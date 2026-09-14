import '../../../../data/models/match.dart';
import '../entities/prediction.dart';

abstract class PredictionRepository {
  /// Crea o aggiorna il pronostico dell'utente corrente per [match].
  ///
  /// Rifiuta il salvataggio se `match.isPredictionOpen` è falso: è un
  /// controllo lato client, pensato per una UX immediata (non serve
  /// attendere il round-trip di rete per sapere che è troppo tardi).
  /// NON è la protezione reale: quella richiede una verifica server-side
  /// del kickoff (Cloud Function — Phase 9), perché un client compromesso
  /// potrebbe alterare l'orologio locale o chiamare Firestore direttamente.
  Future<void> savePrediction({
    required Match match,
    int? exactHomeScore,
    int? exactAwayScore,
    String? result1x2,
    bool? goalNoGoal,
    Map<String, bool>? overUnder,
  });

  Future<Prediction?> getPrediction(String matchId);

  Stream<Prediction?> watchPrediction(String matchId);

  Stream<List<Prediction>> watchMyPredictions();
}
