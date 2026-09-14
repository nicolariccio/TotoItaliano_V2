import 'package:collection/collection.dart';

import '../models/competition.dart';
import '../models/match.dart';
import '../models/matchday.dart';
import '../models/team.dart';
import '../models/team_standing.dart';
import 'football_data_service.dart';

/// Implementazione demo di [FootballDataService]: 20 squadre, una
/// competizione (Serie A) e 3 giornate (una conclusa, una in corso, una
/// futura) generate in memoria. Permette di sviluppare e provare l'app
/// senza alcuna API esterna, come richiesto dalla roadmap di progetto.
///
/// I kickoff delle giornate non ancora giocate sono calcolati relativi a
/// `DateTime.now()` al primo utilizzo, cosi' la demo resta credibile
/// (countdown, blocco pronostici) indipendentemente da quando viene
/// eseguita l'app.
class MockFootballDataService implements FootballDataService {
  MockFootballDataService() {
    _teams = _buildTeams();
    _competition = _buildCompetition();
    _matchdays = _buildMatchdays();
    _matches = _buildMatches();
  }

  static const Duration _simulatedLatency = Duration(milliseconds: 350);

  late final List<Team> _teams;
  late final Competition _competition;
  late final List<Matchday> _matchdays;
  late final List<Match> _matches;

  Future<T> _respond<T>(T value) async {
    await Future<void>.delayed(_simulatedLatency);
    return value;
  }

  @override
  Future<List<Competition>> getCompetitions() => _respond([_competition]);

  @override
  Future<List<Team>> getTeams({required String competitionId}) =>
      _respond(_teams);

  @override
  Future<List<Matchday>> getMatchdays({required String competitionId}) =>
      _respond(_matchdays);

  @override
  Future<List<Match>> getMatches(
      {required String competitionId, String? matchdayId}) {
    final matches = matchdayId == null
        ? _matches
        : _matches.where((m) => m.matchdayId == matchdayId).toList();
    return _respond(matches);
  }

  @override
  Future<Match?> getMatch(String matchId) {
    final match = _matches.where((m) => m.id == matchId).firstOrNull;
    return _respond(match);
  }

  @override
  Future<List<Match>> getResults(
      {required String competitionId, String? matchdayId}) {
    final results = _matches
        .where((m) => m.status == MatchStatus.finished)
        .where((m) => matchdayId == null || m.matchdayId == matchdayId)
        .toList();
    return _respond(results);
  }

  @override
  Future<List<TeamStanding>> getStandings({required String competitionId}) {
    final finished = _matches.where((m) => m.status == MatchStatus.finished);
    final stats = <String, _TeamStats>{
      for (final team in _teams) team.id: _TeamStats(team.id, team.name),
    };

    for (final match in finished) {
      final home = stats[match.homeTeam.id]!;
      final away = stats[match.awayTeam.id]!;
      final homeGoals = match.homeScore ?? 0;
      final awayGoals = match.awayScore ?? 0;

      home.played++;
      away.played++;
      home.goalsFor += homeGoals;
      home.goalsAgainst += awayGoals;
      away.goalsFor += awayGoals;
      away.goalsAgainst += homeGoals;

      if (homeGoals > awayGoals) {
        home.won++;
        away.lost++;
      } else if (homeGoals < awayGoals) {
        away.won++;
        home.lost++;
      } else {
        home.drawn++;
        away.drawn++;
      }
    }

    final standings = stats.values.toList()
      ..sort((a, b) {
        final byPoints = b.points.compareTo(a.points);
        if (byPoints != 0) return byPoints;
        return (b.goalsFor - b.goalsAgainst)
            .compareTo(a.goalsFor - a.goalsAgainst);
      });

    return _respond([
      for (var i = 0; i < standings.length; i++)
        standings[i].toStanding(position: i + 1),
    ]);
  }

  List<Team> _buildTeams() {
    const raw = [
      ('Inter', 'INT', 'Milano', 'Stadio Giuseppe Meazza'),
      ('Milan', 'MIL', 'Milano', 'Stadio Giuseppe Meazza'),
      ('Juventus', 'JUV', 'Torino', 'Allianz Stadium'),
      ('Napoli', 'NAP', 'Napoli', 'Stadio Diego Armando Maradona'),
      ('Roma', 'ROM', 'Roma', 'Stadio Olimpico'),
      ('Lazio', 'LAZ', 'Roma', 'Stadio Olimpico'),
      ('Atalanta', 'ATA', 'Bergamo', 'Gewiss Stadium'),
      ('Fiorentina', 'FIO', 'Firenze', 'Stadio Artemio Franchi'),
      ('Bologna', 'BOL', 'Bologna', "Stadio Renato Dall'Ara"),
      ('Torino', 'TOR', 'Torino', 'Stadio Olimpico Grande Torino'),
      ('Udinese', 'UDI', 'Udine', 'Bluenergy Stadium'),
      ('Sassuolo', 'SAS', 'Sassuolo', 'Mapei Stadium'),
      ('Empoli', 'EMP', 'Empoli', 'Stadio Carlo Castellani'),
      ('Salernitana', 'SAL', 'Salerno', 'Stadio Arechi'),
      ('Genoa', 'GEN', 'Genova', 'Stadio Luigi Ferraris'),
      ('Cagliari', 'CAG', 'Cagliari', 'Unipol Domus'),
      ('Hellas Verona', 'VER', 'Verona', 'Stadio Marcantonio Bentegodi'),
      ('Lecce', 'LEC', 'Lecce', 'Stadio Via del Mare'),
      ('Parma', 'PAR', 'Parma', 'Stadio Ennio Tardini'),
      ('Monza', 'MON', 'Monza', 'U-Power Stadium'),
    ];

    return [
      for (var i = 0; i < raw.length; i++)
        Team(
          id: 't${i + 1}',
          name: raw[i].$1,
          shortName: raw[i].$2,
          city: raw[i].$3,
          stadium: raw[i].$4,
        ),
    ];
  }

  Competition _buildCompetition() {
    final now = DateTime.now();
    return Competition(
      id: 'serie-a-2026-27',
      name: 'Serie A',
      season: '2026/27',
      sport: 'calcio',
      startDate: now.subtract(const Duration(days: 30)),
      endDate: now.add(const Duration(days: 240)),
      status: CompetitionStatus.active,
      entryFee: 50,
      currency: 'EUR',
      createdAt: now.subtract(const Duration(days: 60)),
      updatedAt: now.subtract(const Duration(days: 1)),
    );
  }

  List<Matchday> _buildMatchdays() {
    final now = DateTime.now();
    final matchday2FirstKickoff =
        _atTime(now.add(const Duration(days: 1)), 15, 0);

    return [
      Matchday(
        id: 'md1',
        competitionId: _competitionId,
        number: 1,
        startDate: now.subtract(const Duration(days: 14)),
        endDate: now.subtract(const Duration(days: 12)),
        status: MatchdayStatus.finished,
        predictionDeadline: now.subtract(const Duration(days: 14)),
      ),
      Matchday(
        id: 'md2',
        competitionId: _competitionId,
        number: 2,
        startDate: now.add(const Duration(days: 1)),
        endDate: now.add(const Duration(days: 3)),
        status: MatchdayStatus.active,
        predictionDeadline: matchday2FirstKickoff,
      ),
      Matchday(
        id: 'md3',
        competitionId: _competitionId,
        number: 3,
        startDate: now.add(const Duration(days: 8)),
        endDate: now.add(const Duration(days: 10)),
        status: MatchdayStatus.upcoming,
        predictionDeadline: _atTime(now.add(const Duration(days: 8)), 15, 0),
      ),
    ];
  }

  static const String _competitionId = 'serie-a-2026-27';

  DateTime _atTime(DateTime day, int hour, int minute) {
    return DateTime(day.year, day.month, day.day, hour, minute);
  }

  List<Match> _buildMatches() {
    final now = DateTime.now();
    final matches = <Match>[];

    // Giornata 1 — conclusa, con risultati.
    const md1Scores = [
      (2, 1),
      (1, 1),
      (3, 0),
      (0, 0),
      (2, 2),
      (1, 0),
      (0, 2),
      (1, 3),
      (2, 0),
      (1, 1),
    ];
    matches.addAll(_pairTeams(
      matchdayId: 'md1',
      kickoffs:
          List.generate(10, (i) => now.subtract(Duration(days: 14 - (i ~/ 4)))),
      scores: md1Scores,
    ));

    // Giornata 2 — in corso, orari realistici su 3 giorni.
    final md2Kickoffs = [
      _atTime(now.add(const Duration(days: 1)), 15, 0),
      _atTime(now.add(const Duration(days: 1)), 18, 0),
      _atTime(now.add(const Duration(days: 1)), 20, 45),
      _atTime(now.add(const Duration(days: 2)), 15, 0),
      _atTime(now.add(const Duration(days: 2)), 15, 0),
      _atTime(now.add(const Duration(days: 2)), 18, 0),
      _atTime(now.add(const Duration(days: 2)), 20, 45),
      _atTime(now.add(const Duration(days: 3)), 12, 30),
      _atTime(now.add(const Duration(days: 3)), 15, 0),
      _atTime(now.add(const Duration(days: 3)), 18, 0),
    ];
    matches.addAll(
        _pairTeams(matchdayId: 'md2', kickoffs: md2Kickoffs, scores: null));

    // Giornata 3 — futura, non ancora programmata nel dettaglio.
    final md3Kickoffs = List.generate(
        10, (i) => _atTime(now.add(Duration(days: 8 + i ~/ 4)), 15, 0));
    matches.addAll(
        _pairTeams(matchdayId: 'md3', kickoffs: md3Kickoffs, scores: null));

    return matches;
  }

  List<Match> _pairTeams({
    required String matchdayId,
    required List<DateTime> kickoffs,
    required List<(int, int)>? scores,
  }) {
    final now = DateTime.now();
    final result = <Match>[];

    for (var i = 0; i < 10; i++) {
      final home = _teams[i * 2];
      final away = _teams[i * 2 + 1];
      final kickoff = kickoffs[i];
      final score = scores?[i];
      final isFinished = score != null;

      result.add(_buildMatch(
        id: '$matchdayId-m${i + 1}',
        matchdayId: matchdayId,
        home: home,
        away: away,
        kickoff: kickoff,
        homeScore: score?.$1,
        awayScore: score?.$2,
        status: isFinished ? MatchStatus.finished : MatchStatus.scheduled,
        now: now,
      ));
    }

    return result;
  }

  Match _buildMatch({
    required String id,
    required String matchdayId,
    required Team home,
    required Team away,
    required DateTime kickoff,
    required MatchStatus status,
    required DateTime now,
    int? homeScore,
    int? awayScore,
  }) {
    MatchWinner? winner;
    bool? goalNoGoal;
    Map<String, bool>? overUnder;

    if (homeScore != null && awayScore != null) {
      winner = homeScore > awayScore
          ? MatchWinner.home
          : (homeScore < awayScore ? MatchWinner.away : MatchWinner.draw);
      goalNoGoal = homeScore > 0 && awayScore > 0;
      final totalGoals = homeScore + awayScore;
      overUnder = {
        '1.5': totalGoals > 1.5,
        '2.5': totalGoals > 2.5,
        '3.5': totalGoals > 3.5,
      };
    }

    return Match(
      id: id,
      competitionId: _competitionId,
      matchdayId: matchdayId,
      homeTeam: home,
      awayTeam: away,
      kickoff: kickoff,
      status: status,
      homeScore: homeScore,
      awayScore: awayScore,
      createdAt: now.subtract(const Duration(days: 30)),
      updatedAt: now,
      predictionLocked: status == MatchStatus.finished || now.isAfter(kickoff),
      winner: winner,
      goalNoGoal: goalNoGoal,
      overUnder: overUnder,
    );
  }
}

class _TeamStats {
  _TeamStats(this.teamId, this.teamName);

  final String teamId;
  final String teamName;
  int played = 0;
  int won = 0;
  int drawn = 0;
  int lost = 0;
  int goalsFor = 0;
  int goalsAgainst = 0;

  int get points => won * 3 + drawn;

  TeamStanding toStanding({required int position}) => TeamStanding(
        teamId: teamId,
        teamName: teamName,
        position: position,
        played: played,
        won: won,
        drawn: drawn,
        lost: lost,
        goalsFor: goalsFor,
        goalsAgainst: goalsAgainst,
        points: points,
      );
}
