import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception_mapper.dart';
import '../../../../core/errors/failure.dart';
import '../../../../data/models/match.dart';
import '../providers/prediction_providers.dart';
import 'prediction_form_state.dart';

const int _maxScore = 15;

class PredictionFormController extends StateNotifier<PredictionFormState> {
  PredictionFormController(this._ref, this._match) : super(const PredictionFormState()) {
    _loadExisting();
  }

  final Ref _ref;
  final Match _match;

  Future<void> _loadExisting() async {
    try {
      final existing = await _ref.read(predictionRepositoryProvider).getPrediction(_match.id);
      state = existing != null
          ? PredictionFormState.fromPrediction(existing)
          : state.copyWith(isLoadingExisting: false);
    } catch (_) {
      // Nessun pronostico pregresso caricabile: si parte da un form vuoto,
      // non è un errore bloccante per l'utente.
      state = state.copyWith(isLoadingExisting: false);
    }
  }

  void incrementHomeScore() {
    if (!_match.isPredictionOpen) return;
    final next = ((state.homeScore ?? 0) + 1).clamp(0, _maxScore);
    state = state.copyWith(homeScore: next, clearError: true, savedSuccessfully: false);
  }

  void decrementHomeScore() {
    if (!_match.isPredictionOpen) return;
    final next = ((state.homeScore ?? 0) - 1).clamp(0, _maxScore);
    state = state.copyWith(homeScore: next, clearError: true, savedSuccessfully: false);
  }

  void incrementAwayScore() {
    if (!_match.isPredictionOpen) return;
    final next = ((state.awayScore ?? 0) + 1).clamp(0, _maxScore);
    state = state.copyWith(awayScore: next, clearError: true, savedSuccessfully: false);
  }

  void decrementAwayScore() {
    if (!_match.isPredictionOpen) return;
    final next = ((state.awayScore ?? 0) - 1).clamp(0, _maxScore);
    state = state.copyWith(awayScore: next, clearError: true, savedSuccessfully: false);
  }

  void selectResult1x2(String value) {
    if (!_match.isPredictionOpen) return;
    final isSameSelection = state.result1x2 == value;
    state = state.copyWith(
      result1x2: isSameSelection ? null : value,
      clearResult1x2: isSameSelection,
      clearError: true,
      savedSuccessfully: false,
    );
  }

  void selectGoalNoGoal(bool isGoal) {
    if (!_match.isPredictionOpen) return;
    final isSameSelection = state.goalNoGoal == isGoal;
    state = state.copyWith(
      goalNoGoal: isSameSelection ? null : isGoal,
      clearGoalNoGoal: isSameSelection,
      clearError: true,
      savedSuccessfully: false,
    );
  }

  void selectOverUnder(String threshold, bool isOver) {
    if (!_match.isPredictionOpen) return;
    final next = Map<String, bool>.from(state.overUnder);
    if (next[threshold] == isOver) {
      next.remove(threshold);
    } else {
      next[threshold] = isOver;
    }
    state = state.copyWith(overUnder: next, clearError: true, savedSuccessfully: false);
  }

  Future<void> save() async {
    if (!_match.isPredictionOpen) {
      state = state.copyWith(errorMessage: const PredictionLockedFailure().message);
      return;
    }
    state = state.copyWith(isSaving: true, clearError: true, savedSuccessfully: false);
    try {
      await _ref.read(predictionRepositoryProvider).savePrediction(
            match: _match,
            exactHomeScore: state.homeScore,
            exactAwayScore: state.awayScore,
            result1x2: state.result1x2,
            goalNoGoal: state.goalNoGoal,
            overUnder: state.overUnder.isEmpty ? null : state.overUnder,
          );
      state = state.copyWith(isSaving: false, savedSuccessfully: true);
    } catch (error) {
      state = state.copyWith(isSaving: false, errorMessage: AppExceptionMapper.map(error).message);
    }
  }
}

final StateNotifierProviderFamily<PredictionFormController, PredictionFormState, Match>
    predictionFormControllerProvider =
    StateNotifierProvider.family<PredictionFormController, PredictionFormState, Match>(
  (ref, match) => PredictionFormController(ref, match),
);
