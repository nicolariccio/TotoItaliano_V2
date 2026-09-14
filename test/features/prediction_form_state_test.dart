import 'package:flutter_test/flutter_test.dart';
import 'package:totoitaliano/features/predictions/domain/entities/prediction.dart';
import 'package:totoitaliano/features/predictions/presentation/controllers/prediction_form_state.dart';

void main() {
  group('PredictionFormState.fromPrediction', () {
    test('riporta nel form tutti i mercati salvati', () {
      final prediction = Prediction(
        id: 'u1_m1',
        userId: 'u1',
        matchId: 'm1',
        competitionId: 'c1',
        matchdayId: 'md1',
        exactHomeScore: 2,
        exactAwayScore: 1,
        result1x2: '1',
        goalNoGoal: true,
        overUnder: const {'1.5': true, '2.5': false},
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final state = PredictionFormState.fromPrediction(prediction);

      expect(state.homeScore, 2);
      expect(state.awayScore, 1);
      expect(state.result1x2, '1');
      expect(state.goalNoGoal, isTrue);
      expect(state.overUnder, {'1.5': true, '2.5': false});
      expect(state.isLoadingExisting, isFalse);
    });
  });

  group('PredictionFormState.copyWith', () {
    test('i flag clear* azzerano il campo indipendentemente dal valore corrente', () {
      const state = PredictionFormState(homeScore: 2, result1x2: '1', goalNoGoal: true);

      final cleared = state.copyWith(clearHomeScore: true, clearResult1x2: true, clearGoalNoGoal: true);

      expect(cleared.homeScore, isNull);
      expect(cleared.result1x2, isNull);
      expect(cleared.goalNoGoal, isNull);
    });

    test('senza clear flag i valori esistenti sono preservati', () {
      const state = PredictionFormState(homeScore: 2, awayScore: 1);
      final updated = state.copyWith(homeScore: 3);

      expect(updated.homeScore, 3);
      expect(updated.awayScore, 1);
    });

    test('hasAnySelection riflette correttamente lo stato', () {
      const empty = PredictionFormState();
      const withScore = PredictionFormState(homeScore: 0);
      const withOverUnder = PredictionFormState(overUnder: {'1.5': true});

      expect(empty.hasAnySelection, isFalse);
      expect(withScore.hasAnySelection, isTrue);
      expect(withOverUnder.hasAnySelection, isTrue);
    });
  });
}
