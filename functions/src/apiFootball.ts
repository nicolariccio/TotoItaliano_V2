import { defineSecret, defineString } from "firebase-functions/params";

/**
 * Chiave api-football, impostata SOLO dall'utente nel suo terminale con
 * `firebase functions:secrets:set API_FOOTBALL_KEY` (Google Secret
 * Manager). Non viene mai letta o scritta da questo assistente, né
 * committata: il client Flutter non la vede mai, chiama solo Firestore.
 */
export const apiFootballKey = defineSecret("API_FOOTBALL_KEY");

/**
 * Host dell'API: "v3.football.api-sports.io" per un abbonamento diretto
 * API-SPORTS (default), oppure "api-football-v1.p.rapidapi.com" se la
 * chiave è stata sottoscritta tramite RapidAPI. Non è un segreto, quindi
 * è un parametro normale configurabile senza toccare il codice.
 */
export const apiFootballHost = defineString("API_FOOTBALL_HOST", {
  default: "v3.football.api-sports.io",
});

export interface ApiFootballFixture {
  fixture: { id: number; date: string; status: { short: string } };
  league: { round: string };
  teams: {
    home: { id: number; name: string; logo?: string | null };
    away: { id: number; name: string; logo?: string | null };
  };
  goals: { home: number | null; away: number | null };
}

export interface ApiFootballTeamEntry {
  team: { id: number; name: string; code?: string | null; logo?: string | null };
  venue: { name?: string | null; city?: string | null };
}

export interface ApiFootballStandingRow {
  rank: number;
  team: { id: number; name: string };
  points: number;
  all: {
    played: number;
    win: number;
    draw: number;
    lose: number;
    goals: { for: number; against: number };
  };
}

async function apiFootballGet<T>(path: string, params: Record<string, string | number>): Promise<T> {
  const host = apiFootballHost.value();
  const url = new URL(`https://${host}${path}`);
  for (const [key, value] of Object.entries(params)) {
    url.searchParams.set(key, String(value));
  }

  const headers: Record<string, string> = {};
  if (host.includes("rapidapi.com")) {
    headers["x-rapidapi-key"] = apiFootballKey.value();
    headers["x-rapidapi-host"] = host;
  } else {
    headers["x-apisports-key"] = apiFootballKey.value();
  }

  const response = await fetch(url.toString(), { headers });
  if (!response.ok) {
    throw new Error(`api-football ${path} -> HTTP ${response.status}: ${await response.text()}`);
  }

  const json = (await response.json()) as { response: T; errors?: unknown };
  const errors = json.errors;
  const hasErrors = Array.isArray(errors) ? errors.length > 0 : Boolean(errors && Object.keys(errors as object).length);
  if (hasErrors) {
    throw new Error(`api-football ${path} error: ${JSON.stringify(errors)}`);
  }

  return json.response;
}

export function getFixtures(leagueId: number, season: number): Promise<ApiFootballFixture[]> {
  return apiFootballGet<ApiFootballFixture[]>("/fixtures", { league: leagueId, season });
}

export function getTeams(leagueId: number, season: number): Promise<ApiFootballTeamEntry[]> {
  return apiFootballGet<ApiFootballTeamEntry[]>("/teams", { league: leagueId, season });
}

export async function getStandingsRows(leagueId: number, season: number): Promise<ApiFootballStandingRow[]> {
  const response = await apiFootballGet<Array<{ league: { standings: ApiFootballStandingRow[][] } }>>(
    "/standings",
    { league: leagueId, season },
  );
  return response[0]?.league?.standings?.[0] ?? [];
}
