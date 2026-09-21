// ─────────────────────────────────────────────────────────────────────────────
//  Dati finti per l'anteprima visiva (lib/main_preview.dart).
//
//  SOLO per far vedere le 5 schermate senza un progetto Firebase reale:
//  non è codice di produzione, non viene toccato da main.dart/app.dart, e
//  non deve essere referenziato da nessun file sotto lib/features o
//  lib/core. Cancellalo pure una volta finita l'anteprima.
// ─────────────────────────────────────────────────────────────────────────────

import '../data/constants/serie_a_teams.dart';
import '../data/models/league.dart';
import '../data/models/league_member.dart';
import '../data/models/league_tournament.dart';
import '../data/models/match.dart';
import '../data/models/matchday.dart';
import '../data/models/team.dart';
import '../data/models/tournament_bracket_tie.dart';
import '../data/models/tournament_group.dart';
import '../data/models/tournament_participant.dart';
import '../data/scoring/tournament_scoring.dart';
import '../features/auth/domain/entities/app_user.dart';
import '../features/auth/domain/entities/user_role.dart';
import '../features/predictions/domain/entities/prediction.dart';

final DateTime _now = DateTime.now();

DateTime _at(DateTime day, int hour, int minute) =>
    DateTime(day.year, day.month, day.day, hour, minute);

const String meId = 'me';
const String leagueBarId = 'lg-bar';
const String leagueUffId = 'lg-uff';
const String competitionId = 'serie-a-preview';

// ── Utente corrente ─────────────────────────────────────────────────────────

final AppUser fakeCurrentUser = AppUser(
  id: meId,
  email: 'ciccio90@example.com',
  username: 'Ciccio_90',
  firstName: 'Francesco',
  lastName: 'Ciccio',
  referralCode: 'CICCIO90XZ',
  createdAt: _now.subtract(const Duration(days: 120)),
  updatedAt: _now,
  role: UserRole.user,
  totalPoints: 947,
  predictionsCount: 90,
  correctPredictions: 52,
  exactPredictions: 11,
  successRate: 0.58,
  leagueCount: 2,
);

// ── Leghe ────────────────────────────────────────────────────────────────────

final League leagueBar = League(
  id: leagueBarId,
  name: 'Amici del Bar',
  description: 'Il gruppo storico, da prima del Covid.',
  ownerId: meId,
  inviteCode: 'TOTO-8K4P2',
  createdAt: _now.subtract(const Duration(days: 300)),
  memberCount: 18,
);

final League leagueUfficio = League(
  id: leagueUffId,
  name: 'Ufficio Milano',
  description: 'Colleghi + qualche ex collega nostalgico.',
  ownerId: 'other-owner',
  inviteCode: 'TOTO-3F9QZ',
  createdAt: _now.subtract(const Duration(days: 180)),
  memberCount: 34,
);

final List<League> fakeLeagues = [leagueBar, leagueUfficio];
final Map<String, League> _leaguesById = {
  for (final l in fakeLeagues) l.id: l,
};
League? fakeLeagueById(String id) => _leaguesById[id];

List<LeagueMember> _buildMembers({
  required String leagueId,
  required int total,
  required int meRank,
  required List<({String name, int points})> named,
}) {
  final members = <LeagueMember>[];
  var points = 1400;
  for (var rank = 1; rank <= total; rank++) {
    if (rank == meRank) {
      members.add(LeagueMember(
        userId: meId,
        leagueId: leagueId,
        username: fakeCurrentUser.username,
        joinedAt: _now.subtract(const Duration(days: 200)),
        totalPoints: fakeCurrentUser.totalPoints,
        last5: const [true, true, false, true, false],
        exactCount: 5,
      ));
      points = fakeCurrentUser.totalPoints - 20;
      continue;
    }
    final namedIdx = rank - (rank > meRank ? 2 : 1);
    final preset =
        namedIdx >= 0 && namedIdx < named.length ? named[namedIdx] : null;
    final username = preset?.name ?? 'giocatore$rank';
    final memberPoints = preset?.points ?? points;
    points = memberPoints - 15 - (rank % 4) * 6;
    members.add(LeagueMember(
      userId: '$leagueId-u$rank',
      leagueId: leagueId,
      username: username,
      joinedAt: _now.subtract(Duration(days: 250 - rank)),
      totalPoints: memberPoints,
      last5: List.generate(5, (i) => (rank + i) % 3 != 0),
      exactCount: (rank * 7) % 12,
    ));
  }
  members.sort((a, b) => b.totalPoints.compareTo(a.totalPoints));
  return members;
}

final List<LeagueMember> leagueBarMembers = _buildMembers(
  leagueId: leagueBarId,
  total: 18,
  meRank: 4,
  named: const [
    (name: 'MarcoT', points: 1284),
    (name: 'laura.b', points: 1190),
    (name: 'giorgio.rossi', points: 1147),
  ],
);

final List<LeagueMember> leagueUffMembers = _buildMembers(
  leagueId: leagueUffId,
  total: 34,
  meRank: 11,
  named: const [
    (name: 'bomber_anto', points: 1078),
    (name: 'Fede97', points: 1044),
  ],
);

final Map<String, List<LeagueMember>> _membersByLeague = {
  leagueBarId: leagueBarMembers,
  leagueUffId: leagueUffMembers,
};
List<LeagueMember> fakeMembersFor(String leagueId) =>
    _membersByLeague[leagueId] ?? const [];

/// Classifica generale (tutti gli utenti dell'app) — stessi nomi/punti
/// dell'esempio nel design handoff.
final List<AppUser> fakeGeneraleLeaderboard = [
  _genUser('u-marco', 'MarcoT', 1284),
  _genUser('u-laura', 'laura.b', 1190),
  _genUser('u-giorgio', 'giorgio.rossi', 1147),
  _genUser('u-sara', 'Sara_M', 1102),
  _genUser('u-anto', 'bomber_anto', 1078),
  _genUser('u-fede', 'Fede97', 1044),
  _genUser('u-g7', 'giocatore7', 1020),
  _genUser('u-g8', 'giocatore8', 998),
  _genUser('u-g9', 'giocatore9', 978),
  _genUser('u-g10', 'giocatore10', 965),
  _genUser('u-g11', 'giocatore11', 952),
  fakeCurrentUser, // 12°, 947 punti — vedi handoff.
];

AppUser _genUser(String id, String username, int points) => AppUser(
      id: id,
      email: '$username@example.com',
      username: username,
      firstName: username,
      lastName: '',
      referralCode: username.toUpperCase(),
      createdAt: _now.subtract(const Duration(days: 200)),
      updatedAt: _now,
      totalPoints: points,
      predictionsCount: 80 + points % 20,
      exactPredictions: points % 15,
      successRate: 0.4 + (points % 30) / 100,
    );

// ── Giornata corrente (12) e partite ────────────────────────────────────────

final Matchday matchday12 = Matchday(
  id: 'md12',
  competitionId: competitionId,
  number: 12,
  startDate: _now,
  endDate: _now.add(const Duration(days: 2)),
  status: MatchdayStatus.active,
  predictionDeadline: _now.add(const Duration(hours: 2, minutes: 47)),
);

final List<Matchday> pastMatchdays = [
  Matchday(
    id: 'md9',
    competitionId: competitionId,
    number: 9,
    startDate: _now.subtract(const Duration(days: 21)),
    endDate: _now.subtract(const Duration(days: 19)),
    status: MatchdayStatus.finished,
    predictionDeadline: _now.subtract(const Duration(days: 21)),
  ),
  Matchday(
    id: 'md10',
    competitionId: competitionId,
    number: 10,
    startDate: _now.subtract(const Duration(days: 14)),
    endDate: _now.subtract(const Duration(days: 12)),
    status: MatchdayStatus.finished,
    predictionDeadline: _now.subtract(const Duration(days: 14)),
  ),
  Matchday(
    id: 'md11',
    competitionId: competitionId,
    number: 11,
    startDate: _now.subtract(const Duration(days: 7)),
    endDate: _now.subtract(const Duration(days: 5)),
    status: MatchdayStatus.finished,
    predictionDeadline: _now.subtract(const Duration(days: 7)),
  ),
];

final List<Matchday> fakeMatchdays = [...pastMatchdays, matchday12];

Team _team(String shortName) =>
    serieATeams.firstWhere((t) => t.shortName == shortName);

List<Match> _buildMatchday12Matches() {
  final pairs = <(String, String, DateTime, String)>[
    ('INT', 'JUV', _at(_now.add(const Duration(days: 2)), 18, 0), 'sab'),
    ('NAP', 'ROM', _at(_now.add(const Duration(days: 2)), 20, 45), 'sab'),
    ('ATA', 'LAZ', _at(_now.add(const Duration(days: 3)), 15, 0), 'dom'),
    ('MIL', 'FIO', _at(_now.add(const Duration(days: 3)), 18, 0), 'dom'),
    ('BOL', 'TOR', _at(_now.add(const Duration(days: 3)), 20, 45), 'dom'),
    ('UDI', 'CAG', _at(_now.add(const Duration(days: 2)), 15, 0), 'sab'),
    ('GEN', 'VEN', _at(_now.add(const Duration(days: 2)), 15, 0), 'sab'),
    ('LEC', 'PAR', _at(_now.add(const Duration(days: 3)), 12, 30), 'dom'),
    ('FRO', 'MON', _at(_now.add(const Duration(days: 3)), 15, 0), 'dom'),
    ('SAS', 'COM', _at(_now.subtract(const Duration(hours: 1)), 15, 0), 'gio'),
  ];
  return [
    for (var i = 0; i < pairs.length; i++)
      Match(
        id: 'md12-m${i + 1}',
        competitionId: competitionId,
        matchdayId: matchday12.id,
        homeTeam: _team(pairs[i].$1),
        awayTeam: _team(pairs[i].$2),
        kickoff: pairs[i].$3,
        createdAt: _now.subtract(const Duration(days: 5)),
        updatedAt: _now,
        predictionLocked: _now.isAfter(pairs[i].$3),
      ),
  ];
}

final List<Match> matchday12Matches = _buildMatchday12Matches();

List<Match> _buildPastMatches(Matchday md, int offsetDays) {
  const pairs = [
    ('INT', 'NAP'),
    ('JUV', 'ROM'),
    ('MIL', 'ATA'),
    ('LAZ', 'FIO'),
    ('BOL', 'UDI'),
    ('TOR', 'GEN'),
    ('CAG', 'VEN'),
    ('LEC', 'FRO'),
  ];
  return [
    for (var i = 0; i < pairs.length; i++)
      Match(
        id: '${md.id}-m${i + 1}',
        competitionId: competitionId,
        matchdayId: md.id,
        homeTeam: _team(pairs[i].$1),
        awayTeam: _team(pairs[i].$2),
        kickoff: _now.subtract(Duration(days: offsetDays)),
        status: MatchStatus.finished,
        homeScore: (i * 7) % 4,
        awayScore: (i * 5) % 3,
        createdAt: _now.subtract(Duration(days: offsetDays + 10)),
        updatedAt: _now.subtract(Duration(days: offsetDays)),
        predictionLocked: true,
      ),
  ];
}

final List<Match> md9Matches = _buildPastMatches(pastMatchdays[0], 21);
final List<Match> md10Matches = _buildPastMatches(pastMatchdays[1], 14);
final List<Match> md11Matches = _buildPastMatches(pastMatchdays[2], 7);

final List<Match> allFakeMatches = [
  ...matchday12Matches,
  ...md9Matches,
  ...md10Matches,
  ...md11Matches,
];
final Map<String, Match> _matchesById = {
  for (final m in allFakeMatches) m.id: m,
};
Match? fakeMatchById(String id) => _matchesById[id];

// ── Pronostici salvati ──────────────────────────────────────────────────────

Prediction _pick({
  required String id,
  required String leagueId,
  required Match match,
  required PredictionMarket market,
  String? r1x2,
  bool? goalNoGoal,
  bool? overUnder,
  int? exactHome,
  int? exactAway,
  bool? correct,
  int? pointsAwarded,
  DateTime? updatedAt,
}) =>
    Prediction(
      id: id,
      userId: meId,
      leagueId: leagueId,
      matchId: match.id,
      competitionId: competitionId,
      matchdayId: match.matchdayId,
      market: market,
      result1x2Value: r1x2,
      goalNoGoalValue: goalNoGoal,
      overUnder25Value: overUnder,
      exactHomeScore: exactHome,
      exactAwayScore: exactAway,
      correct: correct,
      pointsAwarded: pointsAwarded,
      createdAt: match.updatedAt.subtract(const Duration(hours: 3)),
      updatedAt:
          updatedAt ?? match.updatedAt.subtract(const Duration(hours: 1)),
    );

/// Schedina "Amici del Bar" giornata 12: 10 di 10 — compilata.
List<Prediction> _md12PredictionsBar() {
  final values = ['1', 'X', '2', '1', '1', 'X', '2', '1', '1', '2'];
  return [
    for (var i = 0; i < matchday12Matches.length; i++)
      _pick(
        id: 'p-bar-md12-$i',
        leagueId: leagueBarId,
        match: matchday12Matches[i],
        market: PredictionMarket.result1x2,
        r1x2: values[i],
      ),
  ];
}

/// Schedina "Ufficio Milano" giornata 12: 7 di 10 — 3 mancanti (diventa la
/// lega "spotlight" in Home, come nell'esempio del design handoff).
List<Prediction> _md12PredictionsUfficio() {
  final done = matchday12Matches.take(7).toList();
  final values = ['1', 'X', '2', '1', '2', 'X', '1'];
  return [
    for (var i = 0; i < done.length; i++)
      _pick(
        id: 'p-uff-md12-$i',
        leagueId: leagueUffId,
        match: done[i],
        market: PredictionMarket.result1x2,
        r1x2: values[i],
      ),
  ];
}

/// Pronostici passati (segnati) usati per statistiche Profilo: miglior
/// giornata, serie in corso, precisione per mercato, storico.
List<Prediction> _pastPredictions() {
  final entries = <Prediction>[];
  var counter = 0;

  void addRound(List<Match> matches, List<
      ({PredictionMarket market, bool correct, int points})> spec) {
    for (var i = 0; i < spec.length && i < matches.length; i++) {
      final s = spec[i];
      final match = matches[i];
      entries.add(_pick(
        id: 'p-hist-${counter++}',
        leagueId: leagueBarId,
        match: match,
        market: s.market,
        r1x2: s.market == PredictionMarket.result1x2 ? '1' : null,
        goalNoGoal: s.market == PredictionMarket.goalNoGoal ? true : null,
        overUnder: s.market == PredictionMarket.overUnder25 ? true : null,
        exactHome: s.market == PredictionMarket.exactScore ? 1 : null,
        exactAway: s.market == PredictionMarket.exactScore ? 0 : null,
        correct: s.correct,
        pointsAwarded: s.correct ? s.points : 0,
        // Indice crescente = più recente: cosi' l'ordine cronologico fra
        // pronostici della stessa giornata (stesso match.updatedAt) resta
        // deterministico per il calcolo della "serie in corso".
        updatedAt: match.updatedAt
            .subtract(const Duration(hours: 1))
            .add(Duration(minutes: i)),
      ));
    }
  }

  // Giornata 9 — 18 punti, buona giornata.
  addRound(md9Matches, const [
    (market: PredictionMarket.result1x2, correct: true, points: 5),
    (market: PredictionMarket.result1x2, correct: true, points: 5),
    (market: PredictionMarket.goalNoGoal, correct: true, points: 3),
    (market: PredictionMarket.overUnder25, correct: true, points: 3),
    (market: PredictionMarket.exactScore, correct: false, points: 10),
    (market: PredictionMarket.result1x2, correct: false, points: 5),
    (market: PredictionMarket.goalNoGoal, correct: false, points: 3),
    (market: PredictionMarket.overUnder25, correct: true, points: 3),
  ]);

  // Giornata 10 — 7 punti.
  addRound(md10Matches, const [
    (market: PredictionMarket.result1x2, correct: true, points: 5),
    (market: PredictionMarket.result1x2, correct: false, points: 5),
    (market: PredictionMarket.goalNoGoal, correct: false, points: 3),
    (market: PredictionMarket.overUnder25, correct: false, points: 3),
    (market: PredictionMarket.exactScore, correct: false, points: 10),
    (market: PredictionMarket.result1x2, correct: false, points: 5),
    (market: PredictionMarket.goalNoGoal, correct: true, points: 3),
    (market: PredictionMarket.overUnder25, correct: false, points: 3),
  ]);

  // Giornata 11 — mista: le ultime due (più recenti) azzeccate, così la
  // "serie in corso" nel Profilo mostra 2.
  addRound(md11Matches, const [
    (market: PredictionMarket.result1x2, correct: false, points: 5),
    (market: PredictionMarket.goalNoGoal, correct: false, points: 3),
    (market: PredictionMarket.overUnder25, correct: true, points: 3),
    (market: PredictionMarket.exactScore, correct: true, points: 10),
  ]);

  return entries;
}

final List<Prediction> allFakePredictions = [
  ..._md12PredictionsBar(),
  ..._md12PredictionsUfficio(),
  ..._pastPredictions(),
];

List<Prediction> fakePredictionsFor(String leagueId, String matchdayId) =>
    allFakePredictions
        .where((p) => p.leagueId == leagueId && p.matchdayId == matchdayId)
        .toList();

// ── Tornei di lega ───────────────────────────────────────────────────────────
//  Un torneo per tipo, come nel piano approvato: Campionato attivo,
//  Highlander con un paio di eliminati, Coppa a eliminazione diretta a metà
//  (girone semifinale in corso) — tutti nella lega "Amici del Bar".

const String tournamentCampionatoId = 't-campionato';
const String tournamentHighlanderId = 't-highlander';
const String tournamentCoppaId = 't-coppa';

final List<String> _campionatoIds =
    leagueBarMembers.take(10).map((m) => m.userId).toList();
final List<String> _highlanderIds =
    leagueBarMembers.take(8).map((m) => m.userId).toList();
final List<String> _coppaSeeds =
    leagueBarMembers.take(8).map((m) => m.userId).toList();

final List<LeagueTournament> fakeTournaments = [
  LeagueTournament(
    id: tournamentCampionatoId,
    leagueId: leagueBarId,
    name: 'Campionato di ritorno',
    type: TournamentType.campionato,
    participantUserIds: _campionatoIds,
    status: TournamentStatus.active,
    createdAt: _now.subtract(const Duration(days: 20)),
    createdFromMatchdayId: 'md9',
  ),
  LeagueTournament(
    id: tournamentHighlanderId,
    leagueId: leagueBarId,
    name: 'Highlander',
    type: TournamentType.highlander,
    participantUserIds: _highlanderIds,
    status: TournamentStatus.active,
    createdAt: _now.subtract(const Duration(days: 14)),
    createdFromMatchdayId: 'md10',
    eliminationsPerMatchday: 1,
    tiebreakOrder: TournamentScoring.defaultTiebreakOrder,
    lastProcessedMatchdayId: 'md11',
  ),
  LeagueTournament(
    id: tournamentCoppaId,
    leagueId: leagueBarId,
    name: 'Coppa del Bar',
    type: TournamentType.coppa,
    participantUserIds: _coppaSeeds,
    status: TournamentStatus.active,
    createdAt: _now.subtract(const Duration(days: 10)),
    createdFromMatchdayId: 'md10',
    coppaFormat: CoppaFormat.knockout,
    phase: CoppaPhase.knockout,
  ),
];

final Map<String, LeagueTournament> _tournamentsById = {
  for (final t in fakeTournaments) t.id: t,
};
LeagueTournament? fakeTournamentById(String id) => _tournamentsById[id];
List<LeagueTournament> fakeTournamentsFor(String leagueId) =>
    fakeTournaments.where((t) => t.leagueId == leagueId).toList();

List<TournamentParticipant> _tournamentParticipants(
  List<String> ids,
  List<int> points, {
  Set<String> eliminated = const {},
  Map<String, String> eliminatedAt = const {},
}) {
  final byId = {for (final m in leagueBarMembers) m.userId: m};
  return [
    for (var i = 0; i < ids.length; i++)
      TournamentParticipant(
        userId: ids[i],
        username: byId[ids[i]]?.username ?? ids[i],
        photoUrl: byId[ids[i]]?.photoUrl,
        points: points[i],
        active: !eliminated.contains(ids[i]),
        eliminatedAtMatchdayId: eliminatedAt[ids[i]],
      ),
  ];
}

final List<TournamentParticipant> _campionatoParticipants =
    _tournamentParticipants(
        _campionatoIds, const [42, 38, 35, 31, 29, 26, 24, 20, 18, 15]);

final List<TournamentParticipant> _highlanderParticipants =
    _tournamentParticipants(
  _highlanderIds,
  const [15, 13, 12, 11, 9, 8, 6, 4],
  eliminated: {_highlanderIds[6], _highlanderIds[7]},
  eliminatedAt: {_highlanderIds[6]: 'md11', _highlanderIds[7]: 'md10'},
);

final List<TournamentParticipant> _coppaParticipants =
    _tournamentParticipants(_coppaSeeds, List.filled(_coppaSeeds.length, 0));

final Map<String, List<TournamentParticipant>> _participantsByTournament = {
  tournamentCampionatoId: _campionatoParticipants,
  tournamentHighlanderId: _highlanderParticipants,
  tournamentCoppaId: _coppaParticipants,
};
List<TournamentParticipant> fakeParticipantsFor(String tournamentId) =>
    _participantsByTournament[tournamentId] ?? const [];

/// Round 1 (quarti) tutti risolti, semifinale (round 2) con un incontro già
/// risolto e l'altro con giornata assegnata ma non ancora elaborato — la
/// finale non esiste ancora, coerente con la macchina a stati reale (si
/// genera solo quando l'intero turno precedente è risolto).
final List<BracketTie> _coppaRound1 = () {
  final generated = TournamentScoring.generateFirstRound(_coppaSeeds);
  return [
    for (var i = 0; i < generated.length; i++)
      generated[i].copyWith(
        matchdayId: 'md10',
        pointsA: 18 - i * 2,
        pointsB: 10 + i,
        winnerId: (18 - i * 2) >= (10 + i)
            ? generated[i].participantAId
            : generated[i].participantBId,
      ),
  ];
}();

final List<BracketTie> _coppaRound2 = [
  BracketTie(
    id: 'r2-s0',
    round: 2,
    slot: 0,
    participantAId: _coppaRound1[0].winnerId,
    participantBId: _coppaRound1[1].winnerId,
    matchdayId: 'md11',
    pointsA: 14,
    pointsB: 9,
    winnerId: _coppaRound1[0].winnerId,
  ),
  BracketTie(
    id: 'r2-s1',
    round: 2,
    slot: 1,
    participantAId: _coppaRound1[2].winnerId,
    participantBId: _coppaRound1[3].winnerId,
    matchdayId: 'md12',
  ),
];

final List<BracketTie> fakeCoppaBracket = [..._coppaRound1, ..._coppaRound2];

final Map<String, List<BracketTie>> _bracketByTournament = {
  tournamentCoppaId: fakeCoppaBracket,
};
List<BracketTie> fakeBracketFor(String tournamentId) =>
    _bracketByTournament[tournamentId] ?? const [];

List<TournamentGroup> fakeGroupsFor(String tournamentId) => const [];
