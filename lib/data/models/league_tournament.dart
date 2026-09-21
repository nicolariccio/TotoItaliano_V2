import 'package:freezed_annotation/freezed_annotation.dart';

part 'league_tournament.freezed.dart';

/// Formato di competizione interna a una lega. Chiamato "torneo" (non
/// "competizione") per non confliggere con [Competition] = la competizione
/// calcistica ufficiale ("Serie A 2026/27"), concetto già pervasivo in
/// Match/Matchday/Prediction.
enum TournamentType { campionato, coppa, highlander }

enum TournamentStatus { upcoming, active, finished }

/// Solo per [TournamentType.coppa].
enum CoppaFormat { knockout, groupsThenKnockout }

/// Fase corrente di una Coppa a gironi + eliminazione diretta.
enum CoppaPhase { groups, knockout }

/// Criteri di spareggio Highlander, in ordine di priorità scelto
/// dall'admin di lega. Un pareggio residuo dopo tutti i criteri si risolve
/// a sorteggio (mostrato esplicitamente, mai silenzioso).
enum HighlanderTiebreak {
  /// Chi ha salvato la schedina per primo quella giornata si salva.
  earliestSubmission,

  /// Punti più alti nella giornata precedente vincono lo spareggio.
  previousMatchdayPoints,

  /// Totale pronostici a risultato esatto più alto in stagione vince.
  seasonExactCount,
}

@freezed
abstract class LeagueTournament with _$LeagueTournament {
  const factory LeagueTournament({
    required String id,
    required String leagueId,
    required String name,
    required TournamentType type,
    // Snapshot fisso alla creazione: mai "tutti i membri" implicito, così
    // il torneo resta stabile anche se la lega cambia composizione dopo.
    required List<String> participantUserIds,
    @Default(TournamentStatus.upcoming) TournamentStatus status,
    required DateTime createdAt,
    // Giornata da cui il torneo parte "azzerato" (Campionato) o da cui
    // inizia il tabellone/l'eliminazione (Coppa/Highlander).
    String? createdFromMatchdayId,

    // Solo TournamentType.coppa:
    CoppaFormat? coppaFormat,
    @Default(CoppaPhase.knockout) CoppaPhase phase,
    int? groupSize,
    int? advancePerGroup,

    // Solo TournamentType.highlander:
    @Default(1) int eliminationsPerMatchday,
    @Default(<HighlanderTiebreak>[]) List<HighlanderTiebreak> tiebreakOrder,
    String? lastProcessedMatchdayId,
  }) = _LeagueTournament;
}
