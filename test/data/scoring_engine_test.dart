import 'package:flutter_test/flutter_test.dart';
import 'package:totoitaliano/data/models/match.dart';
import 'package:totoitaliano/data/models/scoring_config.dart';
import 'package:totoitaliano/data/models/team.dart';
import 'package:totoitaliano/data/scoring/scoring_engine.dart';
import 'package:totoitaliano/features/predictions/domain/entities/prediction.dart';

void main() {
  const home = Team(id: 't1', name: 'Inter', shortName: 'INT', stadium: 'Meazza', city: 'Milano');
  const away = Team(id: 't2', name: 'Milan', shortName: 'MIL', stadium: 'Meazza', city: 'Milano');
  final now = DateTime(2026, 1, 1);

  Match finishedMatch({
    required int homeScore,
    required int awayScore,
    Map<String, bool>? overUnder,
  }) {
    final winner = homeScore > awayScore
        ? MatchWinner.home
        : (homeScore < awayScore ? MatchWinner.away : MatchWinner.draw);
    final totalGoals = homeScore + awayScore;
    return Match(
      id: 'm1',
      competitionId: 'c1',
      matchdayId: 'md1',
      homeTeam: home,
      awayTeam: away,
      kickoff: now,
      status: MatchStatus.finished,
      homeScore: homeScore,
      awayScore: awayScore,
      createdAt: now,
      updatedAt: now,
      predictionLocked: true,
      winner: winner,
      goalNoGoal: homeScore > 0 && awayScore > 0,
      overUnder: overUnder ??
          {
            '1.5': totalGoals > 1.5,
            '2.5': totalGoals > 2.5,
            '3.5': totalGoals > 3.5,
          },
    );
  }

  Prediction predictionFor({
    int? exactHomeScore,
    int? exactAwayScore,
    String? result1x2,
    bool? goalNoGoal,
    Map<String, bool>? overUnder,
  }) {
    return Prediction(
      id: 'u1_m1',
      userId: 'u1',
      matchId: 'm1',
      competitionId: 'c1',
      matchdayId: 'md1',
      exactHomeScore: exactHomeScore,
      exactAwayScore: exactAwayScore,
      result1x2: result1x2,
      goalNoGoal: goalNoGoal,
      overUnder: overUnder,
      createdAt: now,
      updatedAt: now,
    );
  }

  group('risultato esatto', () {
    test('pronostico 2-1, risultato 2-1 → 10 punti (esempio dallo spec)', () {
      final match = finishedMatch(homeScore: 2, awayScore: 1);
      final prediction = predictionFor(exactHomeScore: 2, exactAwayScore: 1);

      final result = ScoringEngine.calculate(prediction: prediction, match: match)!;

      expect(result.exactScoreCorrect, isTrue);
      expect(result.exactScorePoints, 10);
      expect(result.total, 10);
    });

    test('punteggio esatto sbagliato → 0 punti su quel mercato', () {
      final match = finishedMatch(homeScore: 2, awayScore: 1);
      final prediction = predictionFor(exactHomeScore: 1, exactAwayScore: 1);

      final result = ScoringEngine.calculate(prediction: prediction, match: match)!;

      expect(result.exactScoreCorrect, isFalse);
      expect(result.exactScorePoints, 0);
    });

    test('mercato non pronosticato → flag null, 0 punti, non conta come errore', () {
      final match = finishedMatch(homeScore: 2, awayScore: 1);
      final prediction = predictionFor();

      final result = ScoringEngine.calculate(prediction: prediction, match: match)!;

      expect(result.exactScoreCorrect, isNull);
      expect(result.exactScorePoints, 0);
    });
  });

  group('1X2', () {
    test('1X2 corretto (vittoria casa) → 5 punti', () {
      final match = finishedMatch(homeScore: 2, awayScore: 0);
      final prediction = predictionFor(result1x2: '1');

      final result = ScoringEngine.calculate(prediction: prediction, match: match)!;

      expect(result.result1x2Correct, isTrue);
      expect(result.resultPoints, 5);
    });

    test('pareggio pronosticato correttamente → 5 punti', () {
      final match = finishedMatch(homeScore: 1, awayScore: 1);
      final prediction = predictionFor(result1x2: 'X');

      final result = ScoringEngine.calculate(prediction: prediction, match: match)!;

      expect(result.result1x2Correct, isTrue);
      expect(result.resultPoints, 5);
    });

    test('1X2 sbagliato → 0 punti', () {
      final match = finishedMatch(homeScore: 2, awayScore: 0);
      final prediction = predictionFor(result1x2: '2');

      final result = ScoringEngine.calculate(prediction: prediction, match: match)!;

      expect(result.result1x2Correct, isFalse);
      expect(result.resultPoints, 0);
    });
  });

  group('goal/no goal', () {
    test('GOAL corretto (entrambe segnano) → 3 punti', () {
      final match = finishedMatch(homeScore: 2, awayScore: 1);
      final prediction = predictionFor(goalNoGoal: true);

      final result = ScoringEngine.calculate(prediction: prediction, match: match)!;

      expect(result.goalNoGoalCorrect, isTrue);
      expect(result.goalNoGoalPoints, 3);
    });

    test('NO GOAL corretto → 3 punti', () {
      final match = finishedMatch(homeScore: 2, awayScore: 0);
      final prediction = predictionFor(goalNoGoal: false);

      final result = ScoringEngine.calculate(prediction: prediction, match: match)!;

      expect(result.goalNoGoalCorrect, isTrue);
      expect(result.goalNoGoalPoints, 3);
    });
  });

  group('over/under', () {
    test('una soglia corretta su tre → 3 punti', () {
      final match = finishedMatch(homeScore: 2, awayScore: 1); // 3 gol totali
      final prediction = predictionFor(overUnder: const {'1.5': true});

      final result = ScoringEngine.calculate(prediction: prediction, match: match)!;

      expect(result.overUnderCorrectCount, 1);
      expect(result.overUnderPoints, 3);
    });

    test('tutte e tre le soglie corrette → 9 punti (mercati indipendenti)', () {
      final match = finishedMatch(homeScore: 2, awayScore: 1); // 3 gol totali: over 1.5, over 2.5, under 3.5
      final prediction = predictionFor(overUnder: const {'1.5': true, '2.5': true, '3.5': false});

      final result = ScoringEngine.calculate(prediction: prediction, match: match)!;

      expect(result.overUnderCorrectCount, 3);
      expect(result.overUnderPoints, 9);
    });

    test('soglia sbagliata non conta', () {
      final match = finishedMatch(homeScore: 0, awayScore: 0);
      final prediction = predictionFor(overUnder: const {'1.5': true});

      final result = ScoringEngine.calculate(prediction: prediction, match: match)!;

      expect(result.overUnderCorrectCount, 0);
      expect(result.overUnderPoints, 0);
    });
  });

  test('più mercati corretti sulla stessa partita si sommano', () {
    final match = finishedMatch(homeScore: 2, awayScore: 1);
    final prediction = predictionFor(
      exactHomeScore: 2,
      exactAwayScore: 1,
      result1x2: '1',
      goalNoGoal: true,
      overUnder: const {'1.5': true, '2.5': true},
    );

    final result = ScoringEngine.calculate(prediction: prediction, match: match)!;

    expect(result.total, 10 + 5 + 3 + 3 + 3); // esatto + 1x2 + goal + 2 soglie o/u
  });

  test('partita non ancora conclusa → nessun punteggio calcolabile', () {
    final match = Match(
      id: 'm2',
      competitionId: 'c1',
      matchdayId: 'md1',
      homeTeam: home,
      awayTeam: away,
      kickoff: now,
      status: MatchStatus.scheduled,
      createdAt: now,
      updatedAt: now,
    );
    final prediction = predictionFor(exactHomeScore: 2, exactAwayScore: 1);

    expect(ScoringEngine.calculate(prediction: prediction, match: match), isNull);
  });

  test('la ScoringConfig personalizzata cambia i punti assegnati', () {
    final match = finishedMatch(homeScore: 2, awayScore: 1);
    final prediction = predictionFor(exactHomeScore: 2, exactAwayScore: 1);

    final result = ScoringEngine.calculate(
      prediction: prediction,
      match: match,
      config: const ScoringConfig(exactScorePoints: 25),
    )!;

    expect(result.exactScorePoints, 25);
  });
}
