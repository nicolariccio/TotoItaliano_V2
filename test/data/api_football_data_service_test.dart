import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:totoitaliano/data/models/match.dart';
import 'package:totoitaliano/data/models/matchday.dart';
import 'package:totoitaliano/data/services/api_football_data_service.dart';

Map<String, dynamic> _fixture({
  required int id,
  required String date,
  required String round,
  required String statusShort,
  int? homeGoals,
  int? awayGoals,
}) {
  return {
    'fixture': {
      'id': id,
      'date': date,
      'status': {'short': statusShort},
    },
    'league': {'round': round},
    'teams': {
      'home': {'id': 100 + id, 'name': 'Casa $id', 'logo': null},
      'away': {'id': 200 + id, 'name': 'Ospite $id', 'logo': null},
    },
    'goals': {'home': homeGoals, 'away': awayGoals},
  };
}

void main() {
  late List<Map<String, dynamic>> fixtures;
  late List<Map<String, dynamic>> teams;
  late List<Map<String, dynamic>> standingsRows;
  late ApiFootballDataService service;

  setUp(() {
    fixtures = [
      _fixture(
        id: 1,
        date: '2026-08-01T15:00:00+00:00',
        round: 'Regular Season - 1',
        statusShort: 'FT',
        homeGoals: 2,
        awayGoals: 1,
      ),
      _fixture(
        id: 2,
        date: '2026-08-08T15:00:00+00:00',
        round: 'Regular Season - 2',
        statusShort: 'NS',
      ),
    ];
    teams = [
      {
        'team': {'id': 101, 'name': 'Inter', 'code': 'INT', 'logo': null},
        'venue': {'name': 'San Siro', 'city': 'Milano'},
      },
    ];
    standingsRows = [
      {
        'rank': 1,
        'team': {'id': 101, 'name': 'Inter'},
        'points': 10,
        'all': {
          'played': 4,
          'win': 3,
          'draw': 1,
          'lose': 0,
          'goals': {'for': 8, 'against': 2},
        },
      },
    ];

    final client = MockClient((request) async {
      if (request.url.path.endsWith('/fixtures')) {
        return http.Response(jsonEncode({'response': fixtures, 'errors': <dynamic>[]}), 200);
      }
      if (request.url.path.endsWith('/teams')) {
        return http.Response(jsonEncode({'response': teams, 'errors': <dynamic>[]}), 200);
      }
      if (request.url.path.endsWith('/standings')) {
        return http.Response(
          jsonEncode({
            'response': [
              {
                'league': {
                  'standings': [standingsRows],
                },
              },
            ],
            'errors': <dynamic>[],
          }),
          200,
        );
      }
      return http.Response('not found', 404);
    });

    service = ApiFootballDataService(client: client, apiKey: 'test-key');
  });

  test('getMatches converte le fixture finite in Match con esito calcolato', () async {
    final matches = await service.getMatches(competitionId: 'serie-a-2026-27', matchdayId: 'md1');
    expect(matches, hasLength(1));
    final match = matches.first;
    expect(match.id, 'af1');
    expect(match.status, MatchStatus.finished);
    expect(match.homeScore, 2);
    expect(match.awayScore, 1);
    expect(match.winner, MatchWinner.home);
    expect(match.goalNoGoal, isTrue);
    expect(match.overUnder!['2.5'], isTrue);
    expect(match.predictionLocked, isTrue);
  });

  test('getMatches lascia aperte le fixture non ancora giocate', () async {
    final matches = await service.getMatches(competitionId: 'serie-a-2026-27', matchdayId: 'md2');
    expect(matches, hasLength(1));
    final match = matches.first;
    expect(match.status, MatchStatus.scheduled);
    expect(match.winner, isNull);
  });

  test('getMatchdays raggruppa per giornata con lo stato corretto', () async {
    final matchdays = await service.getMatchdays(competitionId: 'serie-a-2026-27');
    expect(matchdays, hasLength(2));
    final md1 = matchdays.firstWhere((m) => m.number == 1);
    expect(md1.status, MatchdayStatus.finished);
  });

  test('getMatch trova per id, null se assente', () async {
    final found = await service.getMatch('af1');
    expect(found?.id, 'af1');
    final missing = await service.getMatch('af999');
    expect(missing, isNull);
  });

  test('getTeams mappa nome, sigla e stadio', () async {
    final result = await service.getTeams(competitionId: 'serie-a-2026-27');
    expect(result, hasLength(1));
    expect(result.first.id, 'af101');
    expect(result.first.shortName, 'INT');
    expect(result.first.stadium, 'San Siro');
  });

  test('getStandings mappa la classifica', () async {
    final result = await service.getStandings(competitionId: 'serie-a-2026-27');
    expect(result, hasLength(1));
    expect(result.first.teamId, 'af101');
    expect(result.first.points, 10);
  });

  test('getResults ritorna solo le partite concluse', () async {
    final results = await service.getResults(competitionId: 'serie-a-2026-27');
    expect(results, hasLength(1));
    expect(results.first.status, MatchStatus.finished);
  });
}
