import * as admin from "firebase-admin";

import {
  ApiFootballFixture,
  ApiFootballTeamEntry,
  getFixtures,
  getStandingsRows,
  getTeams,
} from "./apiFootball";

export const SERIE_A_LEAGUE_ID = 135;
export const SEASON = 2026;
export const COMPETITION_ID = "serie-a-2026-27";

type MatchStatus = "scheduled" | "live" | "finished" | "postponed";
type MatchWinner = "home" | "draw" | "away";

function mapFixtureStatus(short: string): MatchStatus {
  if (short === "FT" || short === "AET" || short === "PEN") return "finished";
  if (["1H", "HT", "2H", "ET", "BT", "P", "SUSP", "INT", "LIVE"].includes(short)) return "live";
  if (["PST", "CANC", "ABD", "AWD", "WO"].includes(short)) return "postponed";
  return "scheduled";
}

// I round di api-football sono stringhe tipo "Regular Season - 7": la
// giornata è il numero finale.
function parseRoundNumber(round: string): number {
  const match = round.match(/(\d+)\s*$/);
  return match ? parseInt(match[1], 10) : 0;
}

function shortNameFrom(name: string, code?: string | null): string {
  if (code && code.trim().length > 0) return code.trim().toUpperCase();
  return name.slice(0, 3).toUpperCase();
}

export interface SyncResult {
  teams: number;
  matches: number;
  matchdays: number;
}

/**
 * Sincronizza squadre, giornate, partite e classifica della Serie A da
 * api-football verso Firestore. Scrive con l'Admin SDK, che ignora le
 * Security Rules: per questo il client non può mai scrivere in queste
 * collezioni (vedi firestore.rules), solo leggerle.
 */
export async function syncSerieA(): Promise<SyncResult> {
  const db = admin.firestore();
  const now = admin.firestore.Timestamp.now();
  const nowMs = Date.now();

  const [teamEntries, fixtures, standingsRows] = await Promise.all([
    getTeams(SERIE_A_LEAGUE_ID, SEASON),
    getFixtures(SERIE_A_LEAGUE_ID, SEASON),
    getStandingsRows(SERIE_A_LEAGUE_ID, SEASON),
  ]);

  const kickoffTimes = fixtures.map((f) => new Date(f.fixture.date).getTime());
  const competitionStart = kickoffTimes.length ? new Date(Math.min(...kickoffTimes)) : new Date(nowMs);
  const competitionEnd = kickoffTimes.length ? new Date(Math.max(...kickoffTimes)) : new Date(nowMs);

  const competitionRef = db.collection("competitions").doc(COMPETITION_ID);

  const teamsBatch = db.batch();
  teamsBatch.set(
    competitionRef,
    {
      id: COMPETITION_ID,
      name: "Serie A",
      season: "2026/27",
      sport: "calcio",
      status: "active",
      entryFee: 0,
      currency: "EUR",
      startDate: admin.firestore.Timestamp.fromDate(competitionStart),
      endDate: admin.firestore.Timestamp.fromDate(competitionEnd),
      updatedAt: now,
      source: "api-football",
    },
    { merge: true },
  );

  for (const entry of teamEntries as ApiFootballTeamEntry[]) {
    const teamId = `af${entry.team.id}`;
    teamsBatch.set(
      competitionRef.collection("teams").doc(teamId),
      {
        id: teamId,
        name: entry.team.name,
        shortName: shortNameFrom(entry.team.name, entry.team.code),
        logoUrl: entry.team.logo ?? null,
        stadium: entry.venue?.name ?? "-",
        city: entry.venue?.city ?? "-",
      },
      { merge: true },
    );
  }
  await teamsBatch.commit();

  const roundGroups = new Map<number, ApiFootballFixture[]>();
  for (const fixture of fixtures) {
    const roundNumber = parseRoundNumber(fixture.league.round);
    if (roundNumber === 0) continue;
    if (!roundGroups.has(roundNumber)) roundGroups.set(roundNumber, []);
    roundGroups.get(roundNumber)!.push(fixture);
  }

  let matchdayBatch = db.batch();
  let matchdayOps = 0;
  let matchBatch = db.batch();
  let matchOps = 0;
  let matchesWritten = 0;

  const flushMatchdayBatch = async () => {
    if (matchdayOps === 0) return;
    await matchdayBatch.commit();
    matchdayBatch = db.batch();
    matchdayOps = 0;
  };
  const flushMatchBatch = async () => {
    if (matchOps === 0) return;
    await matchBatch.commit();
    matchBatch = db.batch();
    matchOps = 0;
  };

  for (const [roundNumber, roundFixtures] of roundGroups) {
    const matchdayId = `md${roundNumber}`;
    const roundKickoffs = roundFixtures.map((f) => new Date(f.fixture.date).getTime());
    const startDate = new Date(Math.min(...roundKickoffs));
    const endDate = new Date(Math.max(...roundKickoffs));
    const statuses = roundFixtures.map((f) => mapFixtureStatus(f.fixture.status.short));
    const allFinished = statuses.every((s) => s === "finished");
    const anyStarted = statuses.some((s) => s !== "scheduled") || nowMs >= startDate.getTime();
    const matchdayStatus = allFinished ? "finished" : anyStarted ? "active" : "upcoming";

    matchdayBatch.set(
      competitionRef.collection("matchdays").doc(matchdayId),
      {
        id: matchdayId,
        competitionId: COMPETITION_ID,
        number: roundNumber,
        startDate: admin.firestore.Timestamp.fromDate(startDate),
        endDate: admin.firestore.Timestamp.fromDate(endDate),
        status: matchdayStatus,
        predictionDeadline: admin.firestore.Timestamp.fromDate(startDate),
      },
      { merge: true },
    );
    matchdayOps++;
    if (matchdayOps >= 400) await flushMatchdayBatch();

    for (const fixture of roundFixtures) {
      const matchId = `af${fixture.fixture.id}`;
      const kickoff = new Date(fixture.fixture.date);
      const status = mapFixtureStatus(fixture.fixture.status.short);
      const homeScore = fixture.goals.home;
      const awayScore = fixture.goals.away;

      let winner: MatchWinner | null = null;
      let goalNoGoal: boolean | null = null;
      let overUnder: Record<string, boolean> | null = null;
      if (status === "finished" && homeScore !== null && awayScore !== null) {
        winner = homeScore > awayScore ? "home" : homeScore < awayScore ? "away" : "draw";
        goalNoGoal = homeScore > 0 && awayScore > 0;
        const total = homeScore + awayScore;
        overUnder = { "1.5": total > 1.5, "2.5": total > 2.5, "3.5": total > 3.5 };
      }

      matchBatch.set(
        db.collection("matches").doc(matchId),
        {
          id: matchId,
          competitionId: COMPETITION_ID,
          matchdayId,
          homeTeam: {
            id: `af${fixture.teams.home.id}`,
            name: fixture.teams.home.name,
            shortName: shortNameFrom(fixture.teams.home.name),
            logoUrl: fixture.teams.home.logo ?? null,
            stadium: "-",
            city: "-",
          },
          awayTeam: {
            id: `af${fixture.teams.away.id}`,
            name: fixture.teams.away.name,
            shortName: shortNameFrom(fixture.teams.away.name),
            logoUrl: fixture.teams.away.logo ?? null,
            stadium: "-",
            city: "-",
          },
          kickoff: admin.firestore.Timestamp.fromDate(kickoff),
          status,
          homeScore,
          awayScore,
          updatedAt: now,
          predictionLocked: status !== "scheduled" || nowMs >= kickoff.getTime(),
          winner,
          goalNoGoal,
          overUnder,
        },
        { merge: true },
      );
      matchOps++;
      matchesWritten++;
      if (matchOps >= 400) await flushMatchBatch();
    }
  }

  await flushMatchdayBatch();
  await flushMatchBatch();

  await db
    .collection("standings")
    .doc(COMPETITION_ID)
    .set({
      competitionId: COMPETITION_ID,
      updatedAt: now,
      rows: standingsRows.map((row) => ({
        teamId: `af${row.team.id}`,
        teamName: row.team.name,
        position: row.rank,
        played: row.all.played,
        won: row.all.win,
        drawn: row.all.draw,
        lost: row.all.lose,
        goalsFor: row.all.goals.for,
        goalsAgainst: row.all.goals.against,
        points: row.points,
      })),
    });

  return { teams: teamEntries.length, matches: matchesWritten, matchdays: roundGroups.size };
}
