import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/competition.dart';
import '../models/match.dart';
import '../models/matchday.dart';
import '../models/team.dart';
import '../models/team_standing.dart';
import 'football_data_service.dart';

/// Implementazione di [FootballDataService] che chiama api-football
/// tramite il proxy Cloudflare Worker in cf-worker/ (mai direttamente:
/// api-sports.io non espone header CORS e blocca ogni fetch dal browser,
/// verificato in test). Il worker tiene la vera API key come secret
/// server-side; il client manda solo [apiFootballProxyToken], un token
/// nostro senza valore economico che il worker verifica prima di
/// inoltrare la richiesta — non la key reale, quindi anche se estratto
/// dal bundle il danno massimo è "qualcuno usa il nostro worker", non
/// "qualcuno ruba l'abbonamento api-football".
class ApiFootballDataService implements FootballDataService {
  ApiFootballDataService({http.Client? client, String? proxyUrl, String? proxyToken})
      : _client = client ?? http.Client(),
        _proxyUrl = proxyUrl ?? apiFootballProxyUrl,
        _proxyToken = proxyToken ?? apiFootballProxyToken;

  /// URL del worker (es. https://totoitaliano-football-proxy.<subdomain>.workers.dev),
  /// impostato a build/avvio con `--dart-define-from-file=api_football.json`
  /// (vedi api_football.example.json — il file reale resta fuori da git).
  static const String apiFootballProxyUrl = String.fromEnvironment('API_FOOTBALL_PROXY_URL');

  static const String apiFootballProxyToken = String.fromEnvironment('API_FOOTBALL_PROXY_TOKEN');

  static const int _leagueId = 135; // Serie A

  // TEMPORANEO: il piano api-football dell'utente è Free e non include la
  // stagione in corso (2026/27) — l'API risponde esplicitamente "Free
  // plans do not have access to this season, try from 2022 to 2024",
  // verificato in test. Usiamo 2023/24 (consentita dal piano) solo per
  // validare che l'intera catena Flutter → Worker → api-football funzioni
  // con dati reali. Da riportare a 2026 (season) e 'serie-a-2026-27'
  // (competitionId) quando il piano viene aggiornato.
  static const int _season = 2023;
  static const String _competitionId = 'serie-a-2023-24';

  static const Duration _fixturesTtl = Duration(minutes: 5);
  static const Duration _teamsTtl = Duration(hours: 6);
  static const Duration _standingsTtl = Duration(minutes: 5);

  final http.Client _client;
  final String _proxyUrl;
  final String _proxyToken;

  List<Map<String, dynamic>>? _fixturesCache;
  DateTime? _fixturesCacheAt;
  List<Map<String, dynamic>>? _teamsCache;
  DateTime? _teamsCacheAt;
  List<Map<String, dynamic>>? _standingsCache;
  DateTime? _standingsCacheAt;

  Future<List<dynamic>> _get(String path, Map<String, dynamic> params) async {
    final base = Uri.parse(_proxyUrl);
    final uri = base.replace(
      path: '${base.path}$path',
      queryParameters: params.map((k, v) => MapEntry(k, '$v')),
    );

    final response = await _client.get(uri, headers: {'X-Proxy-Token': _proxyToken});
    if (response.statusCode != 200) {
      throw Exception('api-football proxy $path -> HTTP ${response.statusCode}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final errors = body['errors'];
    final hasErrors = errors is List ? errors.isNotEmpty : (errors is Map && errors.isNotEmpty);
    if (hasErrors) {
      throw Exception('api-football $path error: $errors');
    }

    return body['response'] as List<dynamic>;
  }

  Future<List<Map<String, dynamic>>> _fixtures() async {
    final now = DateTime.now();
    if (_fixturesCache != null && _fixturesCacheAt != null && now.difference(_fixturesCacheAt!) < _fixturesTtl) {
      return _fixturesCache!;
    }
    final raw = await _get('/fixtures', {'league': _leagueId, 'season': _season});
    _fixturesCache = raw.cast<Map<String, dynamic>>();
    _fixturesCacheAt = now;
    return _fixturesCache!;
  }

  Future<List<Map<String, dynamic>>> _teams() async {
    final now = DateTime.now();
    if (_teamsCache != null && _teamsCacheAt != null && now.difference(_teamsCacheAt!) < _teamsTtl) {
      return _teamsCache!;
    }
    final raw = await _get('/teams', {'league': _leagueId, 'season': _season});
    _teamsCache = raw.cast<Map<String, dynamic>>();
    _teamsCacheAt = now;
    return _teamsCache!;
  }

  Future<List<Map<String, dynamic>>> _standingsRows() async {
    final now = DateTime.now();
    if (_standingsCache != null && _standingsCacheAt != null && now.difference(_standingsCacheAt!) < _standingsTtl) {
      return _standingsCache!;
    }
    final raw = await _get('/standings', {'league': _leagueId, 'season': _season});
    final rows = raw.isEmpty
        ? const <dynamic>[]
        : ((raw.first as Map<String, dynamic>)['league']?['standings'] as List<dynamic>?)?.first as List<dynamic>? ??
            const <dynamic>[];
    _standingsCache = rows.cast<Map<String, dynamic>>();
    _standingsCacheAt = now;
    return _standingsCache!;
  }

  @override
  Future<List<Competition>> getCompetitions() async {
    final fixtures = await _fixtures();
    final kickoffs = fixtures.map((f) => DateTime.parse(f['fixture']['date'] as String)).toList();
    final now = DateTime.now();
    final start = kickoffs.isEmpty ? now : kickoffs.reduce((a, b) => a.isBefore(b) ? a : b);
    final end = kickoffs.isEmpty ? now : kickoffs.reduce((a, b) => a.isAfter(b) ? a : b);

    return [
      Competition(
        id: _competitionId,
        name: 'Serie A',
        season: '2023/24',
        sport: 'calcio',
        startDate: start,
        endDate: end,
        status: CompetitionStatus.active,
        currency: 'EUR',
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }

  @override
  Future<List<Team>> getTeams({required String competitionId}) async {
    final entries = await _teams();
    return entries.map(_teamFromEntry).toList();
  }

  @override
  Future<List<Matchday>> getMatchdays({required String competitionId}) async {
    final fixtures = await _fixtures();
    final grouped = _groupByRound(fixtures);
    final matchdays = <Matchday>[];
    for (final entry in grouped.entries) {
      matchdays.add(_matchdayFromRound(entry.key, entry.value));
    }
    matchdays.sort((a, b) => a.number.compareTo(b.number));
    return matchdays;
  }

  @override
  Future<List<Match>> getMatches({required String competitionId, String? matchdayId}) async {
    final fixtures = await _fixtures();
    final grouped = _groupByRound(fixtures);
    final matches = <Match>[];
    for (final entry in grouped.entries) {
      final id = 'md${entry.key}';
      if (matchdayId != null && matchdayId != id) continue;
      matches.addAll(entry.value.map((f) => _matchFromFixture(f, id)));
    }
    return matches;
  }

  @override
  Future<Match?> getMatch(String matchId) async {
    final fixtures = await _fixtures();
    final grouped = _groupByRound(fixtures);
    for (final entry in grouped.entries) {
      for (final fixture in entry.value) {
        if ('af${fixture['fixture']['id']}' == matchId) {
          return _matchFromFixture(fixture, 'md${entry.key}');
        }
      }
    }
    return null;
  }

  @override
  Future<List<TeamStanding>> getStandings({required String competitionId}) async {
    final rows = await _standingsRows();
    return rows.map((row) {
      final all = row['all'] as Map<String, dynamic>;
      final goals = all['goals'] as Map<String, dynamic>;
      final team = row['team'] as Map<String, dynamic>;
      return TeamStanding(
        teamId: 'af${team['id']}',
        teamName: team['name'] as String,
        position: row['rank'] as int,
        played: all['played'] as int,
        won: all['win'] as int,
        drawn: all['draw'] as int,
        lost: all['lose'] as int,
        goalsFor: goals['for'] as int,
        goalsAgainst: goals['against'] as int,
        points: row['points'] as int,
      );
    }).toList();
  }

  @override
  Future<List<Match>> getResults({required String competitionId, String? matchdayId}) async {
    final matches = await getMatches(competitionId: competitionId, matchdayId: matchdayId);
    return matches.where((m) => m.status == MatchStatus.finished).toList();
  }

  Map<int, List<Map<String, dynamic>>> _groupByRound(List<Map<String, dynamic>> fixtures) {
    final grouped = <int, List<Map<String, dynamic>>>{};
    for (final fixture in fixtures) {
      final round = _parseRoundNumber(fixture['league']['round'] as String);
      if (round == 0) continue;
      grouped.putIfAbsent(round, () => []).add(fixture);
    }
    return grouped;
  }

  Matchday _matchdayFromRound(int number, List<Map<String, dynamic>> fixtures) {
    final kickoffs = fixtures.map((f) => DateTime.parse(f['fixture']['date'] as String)).toList();
    final start = kickoffs.reduce((a, b) => a.isBefore(b) ? a : b);
    final end = kickoffs.reduce((a, b) => a.isAfter(b) ? a : b);
    final statuses = fixtures.map((f) => _mapFixtureStatus(f['fixture']['status']['short'] as String)).toList();
    final allFinished = statuses.every((s) => s == MatchStatus.finished);
    final anyStarted = statuses.any((s) => s != MatchStatus.scheduled) || DateTime.now().isAfter(start);

    return Matchday(
      id: 'md$number',
      competitionId: _competitionId,
      number: number,
      startDate: start,
      endDate: end,
      status: allFinished ? MatchdayStatus.finished : (anyStarted ? MatchdayStatus.active : MatchdayStatus.upcoming),
      predictionDeadline: start,
    );
  }

  Match _matchFromFixture(Map<String, dynamic> fixture, String matchdayId) {
    final fixtureData = fixture['fixture'] as Map<String, dynamic>;
    final kickoff = DateTime.parse(fixtureData['date'] as String);
    final status = _mapFixtureStatus((fixtureData['status'] as Map<String, dynamic>)['short'] as String);
    final goals = fixture['goals'] as Map<String, dynamic>;
    final homeScore = goals['home'] as int?;
    final awayScore = goals['away'] as int?;

    MatchWinner? winner;
    bool? goalNoGoal;
    Map<String, bool>? overUnder;
    if (status == MatchStatus.finished && homeScore != null && awayScore != null) {
      winner = homeScore > awayScore
          ? MatchWinner.home
          : (homeScore < awayScore ? MatchWinner.away : MatchWinner.draw);
      goalNoGoal = homeScore > 0 && awayScore > 0;
      final total = homeScore + awayScore;
      overUnder = {'1.5': total > 1.5, '2.5': total > 2.5, '3.5': total > 3.5};
    }

    final teams = fixture['teams'] as Map<String, dynamic>;
    final now = DateTime.now();

    return Match(
      id: 'af${fixtureData['id']}',
      competitionId: _competitionId,
      matchdayId: matchdayId,
      homeTeam: _teamFromFixtureSide(teams['home'] as Map<String, dynamic>),
      awayTeam: _teamFromFixtureSide(teams['away'] as Map<String, dynamic>),
      kickoff: kickoff,
      status: status,
      homeScore: homeScore,
      awayScore: awayScore,
      createdAt: now,
      updatedAt: now,
      predictionLocked: status != MatchStatus.scheduled || now.isAfter(kickoff),
      winner: winner,
      goalNoGoal: goalNoGoal,
      overUnder: overUnder,
    );
  }

  Team _teamFromFixtureSide(Map<String, dynamic> side) => Team(
        id: 'af${side['id']}',
        name: side['name'] as String,
        shortName: _shortName(side['name'] as String),
        logoUrl: side['logo'] as String?,
        stadium: '-',
        city: '-',
      );

  Team _teamFromEntry(Map<String, dynamic> entry) {
    final team = entry['team'] as Map<String, dynamic>;
    final venue = entry['venue'] as Map<String, dynamic>?;
    return Team(
      id: 'af${team['id']}',
      name: team['name'] as String,
      shortName: _shortName(team['name'] as String, team['code'] as String?),
      logoUrl: team['logo'] as String?,
      stadium: (venue?['name'] as String?) ?? '-',
      city: (venue?['city'] as String?) ?? '-',
    );
  }

  String _shortName(String name, [String? code]) {
    if (code != null && code.trim().isNotEmpty) return code.trim().toUpperCase();
    return name.substring(0, name.length.clamp(0, 3)).toUpperCase();
  }

  MatchStatus _mapFixtureStatus(String short) {
    if (short == 'FT' || short == 'AET' || short == 'PEN') return MatchStatus.finished;
    if (const ['1H', 'HT', '2H', 'ET', 'BT', 'P', 'SUSP', 'INT', 'LIVE'].contains(short)) return MatchStatus.live;
    if (const ['PST', 'CANC', 'ABD', 'AWD', 'WO'].contains(short)) return MatchStatus.postponed;
    return MatchStatus.scheduled;
  }

  int _parseRoundNumber(String round) {
    final match = RegExp(r'(\d+)\s*$').firstMatch(round);
    return match == null ? 0 : int.parse(match.group(1)!);
  }
}
