import '../../data/datasources/prediction_firestore_datasource.dart';
import '../entities/prediction.dart';

abstract class PredictionRepository {
  /// Salva l'intera schedina (uno o più pick, uno per partita) in
  /// un'unica scrittura atomica. Rifiuta se l'utente non fa parte di
  /// almeno una lega, o se [picks] contiene una partita già bloccata:
  /// entrambi controlli lato client, per una UX immediata — la vera
  /// protezione è nelle Security Rules (vedi PredictionRepositoryImpl).
  Future<void> saveSchedina(List<PredictionPick> picks);

  Future<Prediction?> getPrediction(String matchId);

  Stream<Prediction?> watchPrediction(String matchId);

  Stream<List<Prediction>> watchMyPredictions();

  Stream<List<Prediction>> watchMyPredictionsForMatchday(String matchdayId);
}
