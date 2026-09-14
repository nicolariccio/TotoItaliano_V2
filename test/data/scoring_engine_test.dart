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

  Match finishedMatch({required int homeScore, required int awayScore}) {
    final winner =
        homeScore > awayScore ? MatchWinner.home : (homeScore < awayScore ? MatchWinner.away : MatchWinner.draw);
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
      overUnder: {'2.5': totalGoals > 2.5},
    );
  }

  Prediction predictionFor(
    PredictionMarket market, {
    int? exactHomeScore,
    int? exactAwayScore,
    String? result1x2Value,
    bool? goalNoGoalValue,
    bool? overUnder25Value,
  }) {
    return Prediction(
      id: 'u1_m1',
      userId: 'u1',
      matchId: 'm1',
      competitionId: 'c1',
      matchdayId: 'md1',
      market: market,
      exactHomeScore: exactHomeScore,
      exactAwayScore: exactAwayScore,
      result1x2Value: result1x2Value,
      goalNoGoalValue: goalNoGoalValue,
      overUnder25Value: overUnder25Value,
      createdAt: now,
      updatedAt: now,
    );
  }

  test('pronostico 2-1, risultato 2-1 → 10 punti (esempio dallo spec)', () {
    final match = finishedMatch(homeScore: 2, awayScore: 1);
    final prediction = predictionFor(PredictionMarket.exactScore, exactHomeScore: 2, exactAwayScore: 1);

    final result = ScoringEngine.calculate(prediction: prediction, match: match)!;

    expect(result.correct, isTrue);
    expect(result.points, 10);
  });

  test('risultato esatto sbagliato → 0 punti', () {
    final match = finishedMatch(homeScore: 2, awayScore: 1);
    final prediction = predictionFor(PredictionMarket.exactScore, exactHomeScore: 1, exactAwayScore: 1);

    final result = ScoringEngine.calculate(prediction: prediction, match: match)!;

    expect(result.correct, isFalse);
    expect(result.points, 0);
  });

  test('1X2 corretto (vittoria casa) → 5 punti', () {
    final match = finishedMatch(homeScore: 2, awayScore: 0);
    final prediction = predictionFor(PredictionMarket.result1x2, result1x2Value: '1');

    final result = ScoringEngine.calculate(prediction: prediction, match: match)!;

    expect(result.correct, isTrue);
    expect(result.points, 5);
  });

  test('pareggio pronosticato correttamente → 5 punti', () {
    final match = finishedMatch(homeScore: 1, awayScore: 1);
    final prediction = predictionFor(PredictionMarket.result1x2, result1x2Value: 'X');

    final result = ScoringEngine.calculate(prediction: prediction, match: match)!;

    expect(result.correct, isTrue);
    expect(result.points, 5);
  });

  test('1X2 sbagliato → 0 punti', () {
    final match = finishedMatch(homeScore: 2, awayScore: 0);
    final prediction = predictionFor(PredictionMarket.result1x2, result1x2Value: '2');

    final result = ScoringEngine.calculate(prediction: prediction, match: match)!;

    expect(result.correct, isFalse);
    expect(result.points, 0);
  });

  test('GOAL corretto (entrambe segnano) → 3 punti', () {
    final match = finishedMatch(homeScore: 2, awayScore: 1);
    final prediction = predictionFor(PredictionMarket.goalNoGoal, goalNoGoalValue: true);

    final result = ScoringEngine.calculate(prediction: prediction, match: match)!;

    expect(result.correct, isTrue);
    expect(result.points, 3);
  });

  test('NO GOAL corretto → 3 punti', () {
    final match = finishedMatch(homeScore: 2, awayScore: 0);
    final prediction = predictionFor(PredictionMarket.goalNoGoal, goalNoGoalValue: false);

    final result = ScoringEngine.calculate(prediction: prediction, match: match)!;

    expect(result.correct, isTrue);
    expect(result.points, 3);
  });

  test('Over 2.5 corretto → 3 punti', () {
    final match = finishedMatch(homeScore: 2, awayScore: 1); // 3 gol totali
    final prediction = predictionFor(PredictionMarket.overUnder25, overUnder25Value: true);

    final result = ScoringEngine.calculate(prediction: prediction, match: match)!;

    expect(result.correct, isTrue);
    expect(result.points, 3);
  });

  test('Under 2.5 sbagliato se ci sono 3 gol → 0 punti', () {
    final match = finishedMatch(homeScore: 2, awayScore: 1);
    final prediction = predictionFor(PredictionMarket.overUnder25, overUnder25Value: false);

    final result = ScoringEngine.calculate(prediction: prediction, match: match)!;

    expect(result.correct, isFalse);
    expect(result.points, 0);
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
    final prediction = predictionFor(PredictionMarket.exactScore, exactHomeScore: 2, exactAwayScore: 1);

    expect(ScoringEngine.calculate(prediction: prediction, match: match), isNull);
  });

  test('la ScoringConfig personalizzata cambia i punti assegnati', () {
    final match = finishedMatch(homeScore: 2, awayScore: 1);
    final prediction = predictionFor(PredictionMarket.exactScore, exactHomeScore: 2, exactAwayScore: 1);

    final result = ScoringEngine.calculate(
      prediction: prediction,
      match: match,
      config: const ScoringConfig(exactScorePoints: 25),
    )!;

    expect(result.points, 25);
  });
}
