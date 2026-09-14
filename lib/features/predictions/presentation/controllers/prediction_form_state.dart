import '../../domain/entities/prediction.dart';

/// Stato del form di pronostico per una singola partita. Non è un
/// [Prediction] persistito: rappresenta cosa l'utente sta compilando
/// nell'interfaccia, prima/durante il salvataggio.
class PredictionFormState {
  const PredictionFormState({
    this.homeScore,
    this.awayScore,
    this.result1x2,
    this.goalNoGoal,
    this.overUnder = const {},
    this.isLoadingExisting = true,
    this.isSaving = false,
    this.errorMessage,
    this.savedSuccessfully = false,
  });

  final int? homeScore;
  final int? awayScore;
  final String? result1x2;
  final bool? goalNoGoal;
  final Map<String, bool> overUnder;
  final bool isLoadingExisting;
  final bool isSaving;
  final String? errorMessage;
  final bool savedSuccessfully;

  bool get hasAnySelection =>
      homeScore != null || awayScore != null || result1x2 != null || goalNoGoal != null || overUnder.isNotEmpty;

  factory PredictionFormState.fromPrediction(Prediction prediction) {
    return PredictionFormState(
      homeScore: prediction.exactHomeScore,
      awayScore: prediction.exactAwayScore,
      result1x2: prediction.result1x2,
      goalNoGoal: prediction.goalNoGoal,
      overUnder: prediction.overUnder ?? const {},
      isLoadingExisting: false,
    );
  }

  PredictionFormState copyWith({
    int? homeScore,
    bool clearHomeScore = false,
    int? awayScore,
    bool clearAwayScore = false,
    String? result1x2,
    bool clearResult1x2 = false,
    bool? goalNoGoal,
    bool clearGoalNoGoal = false,
    Map<String, bool>? overUnder,
    bool? isLoadingExisting,
    bool? isSaving,
    String? errorMessage,
    bool clearError = false,
    bool? savedSuccessfully,
  }) {
    return PredictionFormState(
      homeScore: clearHomeScore ? null : (homeScore ?? this.homeScore),
      awayScore: clearAwayScore ? null : (awayScore ?? this.awayScore),
      result1x2: clearResult1x2 ? null : (result1x2 ?? this.result1x2),
      goalNoGoal: clearGoalNoGoal ? null : (goalNoGoal ?? this.goalNoGoal),
      overUnder: overUnder ?? this.overUnder,
      isLoadingExisting: isLoadingExisting ?? this.isLoadingExisting,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      savedSuccessfully: savedSuccessfully ?? this.savedSuccessfully,
    );
  }
}
