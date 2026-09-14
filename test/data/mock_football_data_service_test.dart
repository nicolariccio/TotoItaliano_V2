import 'package:flutter_test/flutter_test.dart';
import 'package:totoitaliano/data/models/competition.dart';
import 'package:totoitaliano/data/models/match.dart';
import 'package:totoitaliano/data/models/matchday.dart';
import 'package:totoitaliano/data/services/mock_football_data_service.dart';

void main() {
  late MockFootballDataService service;

  setUp(() {
    service = MockFootballDataService();
  });

  test('getCompetitions ritorna la Serie A attiva', () async {
    final competitions = await service.getCompetitions();
    expect(competitions, hasLength(1));
    expect(competitions.first.name, 'Serie A');
    expect(competitions.first.status, CompetitionStatus.active);
  });

  test('getTeams ritorna 20 squadre con id univoci', () async {
    final teams = await service.getTeams(competitionId: 'serie-a-2026-27');
    expect(teams, hasLength(20));
    expect(teams.map((t) => t.id).toSet(), hasLength(20));
  });

  test('getMatchdays ritorna 3 giornate con esattamente una attiva', () async {
    final matchdays = await service.getMatchdays(competitionId: 'serie-a-2026-27');
    expect(matchdays, hasLength(3));
    expect(matchdays.where((m) => m.status == MatchdayStatus.active), hasLength(1));
  });

  test('ogni giornata ha 10 partite (20 squadre)', () async {
    final matchdays = await service.getMatchdays(competitionId: 'serie-a-2026-27');
    for (final matchday in matchdays) {
      final matches = await service.getMatches(
        competitionId: 'serie-a-2026-27',
        matchdayId: matchday.id,
      );
      expect(matches, hasLength(10), reason: 'giornata ${matchday.number}');
    }
  });

  test('le partite della giornata conclusa hanno un risultato e sono locked', () async {
    final matchdays = await service.getMatchdays(competitionId: 'serie-a-2026-27');
    final finishedMatchday = matchdays.firstWhere((m) => m.status == MatchdayStatus.finished);
    final matches = await service.getMatches(
      competitionId: 'serie-a-2026-27',
      matchdayId: finishedMatchday.id,
    );

    for (final match in matches) {
      expect(match.status, MatchStatus.finished);
      expect(match.homeScore, isNotNull);
      expect(match.awayScore, isNotNull);
      expect(match.winner, isNotNull);
      expect(match.predictionLocked, isTrue);
      expect(match.isPredictionOpen, isFalse);
    }
  });

  test('le partite della giornata attiva non sono ancora giocate', () async {
    final matchdays = await service.getMatchdays(competitionId: 'serie-a-2026-27');
    final activeMatchday = matchdays.firstWhere((m) => m.status == MatchdayStatus.active);
    final matches = await service.getMatches(
      competitionId: 'serie-a-2026-27',
      matchdayId: activeMatchday.id,
    );

    for (final match in matches) {
      expect(match.status, MatchStatus.scheduled);
      expect(match.homeScore, isNull);
      expect(match.isPredictionOpen, isTrue);
    }
  });

  test('getResults ritorna solo le partite concluse', () async {
    final results = await service.getResults(competitionId: 'serie-a-2026-27');
    expect(results, hasLength(10));
    expect(results.every((m) => m.status == MatchStatus.finished), isTrue);
  });

  test('getStandings ordina per punti decrescenti e copre tutte le squadre', () async {
    final standings = await service.getStandings(competitionId: 'serie-a-2026-27');
    expect(standings, hasLength(20));
    for (var i = 1; i < standings.length; i++) {
      expect(standings[i - 1].points, greaterThanOrEqualTo(standings[i].points));
    }
    expect(standings.map((s) => s.position), orderedEquals(List.generate(20, (i) => i + 1)));
  });

  test('getMatch ritorna la partita corretta per id, null se inesistente', () async {
    final matchdays = await service.getMatchdays(competitionId: 'serie-a-2026-27');
    final matches = await service.getMatches(
      competitionId: 'serie-a-2026-27',
      matchdayId: matchdays.first.id,
    );
    final found = await service.getMatch(matches.first.id);
    expect(found?.id, matches.first.id);

    final notFound = await service.getMatch('non-esiste');
    expect(notFound, isNull);
  });
}
