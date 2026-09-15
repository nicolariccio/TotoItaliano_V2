import 'package:freezed_annotation/freezed_annotation.dart';

part 'scoring_config.freezed.dart';

/// Punteggi assegnati per ciascun mercato indovinato. Mai hardcodati nella
/// UI o nel motore di scoring: letti da `scoringConfigs/{competitionId}`
/// (fallback ai valori di default se il documento non esiste ancora),
/// così un admin potrà modificarli in futuro senza toccare il codice.
@freezed
abstract class ScoringConfig with _$ScoringConfig {
  const factory ScoringConfig({
    @Default(10) int exactScorePoints,
    @Default(5) int resultPoints,
    @Default(3) int goalNoGoalPoints,
    // Assegnati per OGNI soglia over/under indovinata (1.5/2.5/3.5): sono
    // mercati indipendenti nella UI, quindi vengono valutati indipendentemente.
    @Default(3) int overUnderPoints,
  }) = _ScoringConfig;

  const ScoringConfig._();

  /// Serializzazione manuale (nessun json_serializable in questo progetto):
  /// usata per salvare la configurazione punteggi personalizzata di una
  /// lega dentro il documento `leagues/{leagueId}.scoringConfig`.
  Map<String, dynamic> toMap() => {
        'exactScorePoints': exactScorePoints,
        'resultPoints': resultPoints,
        'goalNoGoalPoints': goalNoGoalPoints,
        'overUnderPoints': overUnderPoints,
      };

  static ScoringConfig? fromMap(Map<String, dynamic>? map) {
    if (map == null) return null;
    const fallback = ScoringConfig();
    return ScoringConfig(
      exactScorePoints:
          (map['exactScorePoints'] as num?)?.toInt() ?? fallback.exactScorePoints,
      resultPoints:
          (map['resultPoints'] as num?)?.toInt() ?? fallback.resultPoints,
      goalNoGoalPoints: (map['goalNoGoalPoints'] as num?)?.toInt() ??
          fallback.goalNoGoalPoints,
      overUnderPoints:
          (map['overUnderPoints'] as num?)?.toInt() ?? fallback.overUnderPoints,
    );
  }
}
