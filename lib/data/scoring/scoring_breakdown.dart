import 'package:flutter/foundation.dart';

import '../../features/predictions/domain/entities/prediction.dart';

/// Esito del confronto tra un pronostico (un solo mercato scelto
/// dall'utente) e il risultato ufficiale della partita.
@immutable
class ScoringResult {
  const ScoringResult(
      {required this.market, required this.correct, required this.points});

  final PredictionMarket market;
  final bool correct;
  final int points;
}

/// Punteggio *provvisorio* di un pronostico calcolato sul risultato
/// parziale di una partita in corso (o su quello finale).
///
/// Solo per la visualizzazione in tempo reale: l'assegnazione ufficiale dei
/// punti resta quella di `ScoringEngine.calculate` / backend.
@immutable
class LivePickScore {
  const LivePickScore({
    required this.market,
    required this.points,
    required this.winningNow,
    required this.settled,
  });

  final PredictionMarket market;

  /// Punti che il pronostico vale con il risultato attuale.
  final int points;

  /// Vero se, con il risultato attuale, il pronostico sarebbe corretto.
  final bool winningNow;

  /// Vero se l'esito non può più cambiare (partita finita, oppure mercato
  /// già deciso: es. entrambe le squadre hanno segnato).
  final bool settled;
}
