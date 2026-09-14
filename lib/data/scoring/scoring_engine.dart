import '../../features/predictions/domain/entities/prediction.dart';
import '../models/match.dart';
import '../models/scoring_config.dart';
import 'scoring_breakdown.dart';

/// Calcola il punteggio di un pronostico (un solo mercato scelto
/// dall'utente) confrontandolo con il risultato ufficiale di una partita
/// conclusa.
///
/// Pura logica di dominio: nessuna dipendenza da Firebase/Riverpod, non
/// scrive nulla. Il client la usa SOLO per mostrare all'utente i punti
/// che il proprio pronostico ha ottenuto (storico, statistiche): non è
/// l'autorità che assegna i punti. L'assegnazione reale — quella che
/// aggiorna `users/{uid}.totalPoints` — deve avvenire lato server (Cloud
/// Function, Phase 9), perché le Security Rules impediscono già oggi al
/// client di scrivere quei campi: vedi `firestore.rules`.
class ScoringEngine {
  const ScoringEngine._();

  /// Ritorna `null` se la partita non è ancora conclusa (nessun risultato
  /// ufficiale da confrontare).
  static ScoringResult? calculate({
    required Prediction prediction,
    required Match match,
    ScoringConfig config = const ScoringConfig(),
  }) {
    if (match.status != MatchStatus.finished ||
        match.homeScore == null ||
        match.awayScore == null) {
      return null;
    }

    switch (prediction.market) {
      case PredictionMarket.exactScore:
        final correct = prediction.exactHomeScore == match.homeScore &&
            prediction.exactAwayScore == match.awayScore;
        return ScoringResult(
          market: prediction.market,
          correct: correct,
          points: correct ? config.exactScorePoints : 0,
        );

      case PredictionMarket.result1x2:
        final correct =
            prediction.result1x2Value == _winnerToResultCode(match.winner);
        return ScoringResult(
            market: prediction.market,
            correct: correct,
            points: correct ? config.resultPoints : 0);

      case PredictionMarket.goalNoGoal:
        final correct = prediction.goalNoGoalValue != null &&
            prediction.goalNoGoalValue == match.goalNoGoal;
        return ScoringResult(
          market: prediction.market,
          correct: correct,
          points: correct ? config.goalNoGoalPoints : 0,
        );

      case PredictionMarket.overUnder25:
        final officialOver25 = match.overUnder?['2.5'];
        final correct = prediction.overUnder25Value != null &&
            prediction.overUnder25Value == officialOver25;
        return ScoringResult(
          market: prediction.market,
          correct: correct,
          points: correct ? config.overUnderPoints : 0,
        );
    }
  }

  static String? _winnerToResultCode(MatchWinner? winner) {
    switch (winner) {
      case MatchWinner.home:
        return '1';
      case MatchWinner.draw:
        return 'X';
      case MatchWinner.away:
        return '2';
      case null:
        return null;
    }
  }
}
