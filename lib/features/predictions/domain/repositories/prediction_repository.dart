import '../../data/datasources/prediction_firestore_datasource.dart';
import '../entities/prediction.dart';

abstract class PredictionRepository {
  /// Salva l'intera schedina di [leagueId] (uno o più pick, uno per
  /// partita) in un'unica scrittura atomica. Rifiuta se l'utente non è
  /// membro di quella lega, o se [picks] contiene una partita già
  /// bloccata: entrambi controlli lato client, per una UX immediata — la
  /// vera protezione è nelle Security Rules (vedi PredictionRepositoryImpl).
  Future<void> saveSchedina(String leagueId, List<PredictionPick> picks);

  Stream<List<Prediction>> watchMyPredictions();

  /// I pronostici dell'utente per [leagueId] nella giornata [matchdayId]:
  /// la schedina di quella lega, indipendente dalle altre leghe a cui
  /// l'utente partecipa.
  Stream<List<Prediction>> watchMyPredictionsForLeagueAndMatchday(
      String leagueId, String matchdayId);
}
