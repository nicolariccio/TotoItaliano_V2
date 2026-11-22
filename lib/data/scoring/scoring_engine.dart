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

  /// Punteggio provvisorio sul risultato attuale (partita live o finita).
  /// Ritorna `null` se la partita non è iniziata o manca il risultato.
  static LivePickScore? calculateLive({
    required Prediction prediction,
    required Match match,
    ScoringConfig config = const ScoringConfig(),
  }) =>
      calculateLivePick(
        market: prediction.market,
        result1x2Value: prediction.result1x2Value,
        goalNoGoalValue: prediction.goalNoGoalValue,
        overUnder25Value: prediction.overUnder25Value,
        exactHomeScore: prediction.exactHomeScore,
        exactAwayScore: prediction.exactAwayScore,
        match: match,
        config: config,
      );

  /// Come [calculateLive], ma sui valori grezzi del pick: serve alla
  /// schedina in compilazione, dove non esiste ancora un `Prediction`.
  static LivePickScore? calculateLivePick({
    required PredictionMarket market,
    String? result1x2Value,
    bool? goalNoGoalValue,
    bool? overUnder25Value,
    int? exactHomeScore,
    int? exactAwayScore,
    required Match match,
    ScoringConfig config = const ScoringConfig(),
  }) {
    final home = match.homeScore;
    final away = match.awayScore;
    final started = match.status == MatchStatus.live ||
        match.status == MatchStatus.finished;
    if (!started || home == null || away == null) return null;

    final finished = match.status == MatchStatus.finished;
    final total = home + away;
    final bothScored = home > 0 && away > 0;

    final bool winning;
    final bool settled;
    final int value;

    switch (market) {
      case PredictionMarket.exactScore:
        winning = exactHomeScore == home && exactAwayScore == away;
        // Un risultato esatto è già perso se un punteggio ha superato il pick.
        final overshot =
            (exactHomeScore ?? 0) < home || (exactAwayScore ?? 0) < away;
        settled = finished || overshot;
        value = config.exactScorePoints;

      case PredictionMarket.result1x2:
        final current = home > away ? '1' : (home < away ? '2' : 'X');
        winning = result1x2Value == current;
        settled = finished;
        value = config.resultPoints;

      case PredictionMarket.goalNoGoal:
        final pick = goalNoGoalValue;
        winning = pick != null && pick == bothScored;
        settled = finished || bothScored;
        value = config.goalNoGoalPoints;

      case PredictionMarket.overUnder25:
        final pick = overUnder25Value;
        final over = total >= 3;
        winning = pick != null && pick == over;
        settled = finished || over;
        value = config.overUnderPoints;
    }

    return LivePickScore(
      market: market,
      points: winning ? value : 0,
      winningNow: winning,
      settled: settled,
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
