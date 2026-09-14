import 'package:flutter/foundation.dart';

/// Dettaglio del punteggio calcolato per un singolo pronostico, mercato
/// per mercato. `null` su un flag `*Correct` significa "non pronosticato",
/// non "sbagliato": i mercati sono indipendenti (vedi [ScoringEngine]).
@immutable
class ScoringBreakdown {
  const ScoringBreakdown({
    required this.exactScorePoints,
    required this.exactScoreCorrect,
    required this.resultPoints,
    required this.result1x2Correct,
    required this.goalNoGoalPoints,
    required this.goalNoGoalCorrect,
    required this.overUnderPoints,
    required this.overUnderCorrectCount,
  });

  final int exactScorePoints;
  final bool? exactScoreCorrect;

  final int resultPoints;
  final bool? result1x2Correct;

  final int goalNoGoalPoints;
  final bool? goalNoGoalCorrect;

  final int overUnderPoints;
  final int overUnderCorrectCount;

  int get total => exactScorePoints + resultPoints + goalNoGoalPoints + overUnderPoints;

  static const ScoringBreakdown empty = ScoringBreakdown(
    exactScorePoints: 0,
    exactScoreCorrect: null,
    resultPoints: 0,
    result1x2Correct: null,
    goalNoGoalPoints: 0,
    goalNoGoalCorrect: null,
    overUnderPoints: 0,
    overUnderCorrectCount: 0,
  );
}
