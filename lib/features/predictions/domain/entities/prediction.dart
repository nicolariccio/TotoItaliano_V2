import 'package:freezed_annotation/freezed_annotation.dart';

part 'prediction.freezed.dart';

/// Il pronostico di un utente per una partita. Un documento per coppia
/// (utente, partita) — id Firestore: `{userId}_{matchId}`.
///
/// Ogni mercato (risultato esatto, 1X2, goal/no goal, over/under) è
/// indipendente e opzionale: l'utente può compilarne anche solo alcuni.
@freezed
abstract class Prediction with _$Prediction {
  const factory Prediction({
    required String id,
    required String userId,
    required String matchId,
    required String competitionId,
    required String matchdayId,
    int? exactHomeScore,
    int? exactAwayScore,
    // '1' (casa) | 'X' (pareggio) | '2' (trasferta)
    String? result1x2,
    // true = GOAL (entrambe segnano), false = NO GOAL
    bool? goalNoGoal,
    // chiavi '1.5' | '2.5' | '3.5', valore true = Over, false = Under
    Map<String, bool>? overUnder,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Prediction;
}
