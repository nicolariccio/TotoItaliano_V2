import '../../domain/entities/prediction.dart';

/// Il pick dell'utente per una singola partita della schedina: un solo
/// mercato, con il relativo valore.
class PickState {
  const PickState({
    this.market,
    this.result1x2Value,
    this.goalNoGoalValue,
    this.overUnder25Value,
    this.exactHomeScore,
    this.exactAwayScore,
  });

  final PredictionMarket? market;
  final String? result1x2Value;
  final bool? goalNoGoalValue;
  final bool? overUnder25Value;
  final int? exactHomeScore;
  final int? exactAwayScore;

  /// Vero se, per il mercato scelto, manca ancora il valore: la partita
  /// non entra nella schedina finché non è completo.
  bool get isComplete {
    switch (market) {
      case PredictionMarket.result1x2:
        return result1x2Value != null;
      case PredictionMarket.goalNoGoal:
        return goalNoGoalValue != null;
      case PredictionMarket.overUnder25:
        return overUnder25Value != null;
      case PredictionMarket.exactScore:
        return exactHomeScore != null && exactAwayScore != null;
      case null:
        return false;
    }
  }

  factory PickState.fromPrediction(Prediction p) => PickState(
        market: p.market,
        result1x2Value: p.result1x2Value,
        goalNoGoalValue: p.goalNoGoalValue,
        overUnder25Value: p.overUnder25Value,
        exactHomeScore: p.exactHomeScore,
        exactAwayScore: p.exactAwayScore,
      );

  /// Cambiare mercato azzera i valori degli altri mercati: un solo
  /// pronostico per partita, non un accumulo.
  PickState withMarket(PredictionMarket newMarket) {
    if (newMarket == market) return this;
    return PickState(market: newMarket);
  }

  PickState copyWith({
    String? result1x2Value,
    bool? goalNoGoalValue,
    bool? overUnder25Value,
    int? exactHomeScore,
    int? exactAwayScore,
  }) {
    return PickState(
      market: market,
      result1x2Value: result1x2Value ?? this.result1x2Value,
      goalNoGoalValue: goalNoGoalValue ?? this.goalNoGoalValue,
      overUnder25Value: overUnder25Value ?? this.overUnder25Value,
      exactHomeScore: exactHomeScore ?? this.exactHomeScore,
      exactAwayScore: exactAwayScore ?? this.exactAwayScore,
    );
  }
}

class SchedinaState {
  const SchedinaState({
    this.picks = const {},
    this.isLoading = true,
    this.isSaving = false,
    this.errorMessage,
    this.savedSuccessfully = false,
  });

  final Map<String, PickState> picks;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final bool savedSuccessfully;

  int get completedCount => picks.values.where((p) => p.isComplete).length;

  SchedinaState copyWith({
    Map<String, PickState>? picks,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    bool clearError = false,
    bool? savedSuccessfully,
  }) {
    return SchedinaState(
      picks: picks ?? this.picks,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      savedSuccessfully: savedSuccessfully ?? this.savedSuccessfully,
    );
  }
}
