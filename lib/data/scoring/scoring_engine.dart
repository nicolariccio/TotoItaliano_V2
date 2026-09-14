import '../../features/predictions/domain/entities/prediction.dart';
import '../models/match.dart';
import '../models/scoring_config.dart';
import 'scoring_breakdown.dart';

/// Calcola i punti di un pronostico confrontandolo con il risultato
/// ufficiale di una partita conclusa.
///
/// Pura logica di dominio: nessuna dipendenza da Firebase/Riverpod, non
/// scrive nulla. Il client la usa SOLO per mostrare all'utente i punti
/// che il proprio pronostico ha ottenuto (storico, statistiche): non è
/// l'autorità che assegna i punti. L'assegnazione reale — quella che
/// aggiorna `users/{uid}.totalPoints` — deve avvenire lato server (Cloud
/// Function, Phase 9), perché le Security Rules impediscono già oggi al
/// client di scrivere quei campi: vedi `firestore.rules`.
///
/// Ogni mercato (risultato esatto, 1X2, goal/no goal, ciascuna soglia
/// over/under) è valutato in modo indipendente, coerentemente con la UI
/// che permette di compilarli separatamente: un pronostico può ottenere
/// punti da più mercati sulla stessa partita.
class ScoringEngine {
  const ScoringEngine._();

  /// Ritorna `null` se la partita non è ancora conclusa (nessun risultato
  /// ufficiale da confrontare).
  static ScoringBreakdown? calculate({
    required Prediction prediction,
    required Match match,
    ScoringConfig config = const ScoringConfig(),
  }) {
    if (match.status != MatchStatus.finished ||
        match.homeScore == null ||
        match.awayScore == null) {
      return null;
    }

    final exactCorrect = (prediction.exactHomeScore == null || prediction.exactAwayScore == null)
        ? null
        : prediction.exactHomeScore == match.homeScore && prediction.exactAwayScore == match.awayScore;

    final result1x2Correct = prediction.result1x2 == null
        ? null
        : prediction.result1x2 == _winnerToResultCode(match.winner);

    final goalNoGoalCorrect =
        prediction.goalNoGoal == null || match.goalNoGoal == null ? null : prediction.goalNoGoal == match.goalNoGoal;

    int overUnderCorrectCount = 0;
    final predictedOverUnder = prediction.overUnder;
    final officialOverUnder = match.overUnder;
    if (predictedOverUnder != null && officialOverUnder != null) {
      for (final entry in predictedOverUnder.entries) {
        if (officialOverUnder[entry.key] == entry.value) {
          overUnderCorrectCount++;
        }
      }
    }

    return ScoringBreakdown(
      exactScorePoints: exactCorrect == true ? config.exactScorePoints : 0,
      exactScoreCorrect: exactCorrect,
      resultPoints: result1x2Correct == true ? config.resultPoints : 0,
      result1x2Correct: result1x2Correct,
      goalNoGoalPoints: goalNoGoalCorrect == true ? config.goalNoGoalPoints : 0,
      goalNoGoalCorrect: goalNoGoalCorrect,
      overUnderPoints: overUnderCorrectCount * config.overUnderPoints,
      overUnderCorrectCount: overUnderCorrectCount,
    );
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
