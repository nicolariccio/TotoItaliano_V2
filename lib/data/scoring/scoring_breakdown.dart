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
