import 'package:freezed_annotation/freezed_annotation.dart';

part 'tournament_group.freezed.dart';

/// Un girone della fase a gruppi di una Coppa, in
/// `leagues/{leagueId}/tournaments/{tournamentId}/groups/{groupId}`.
/// [cumulativePoints] somma i punti di giornata di ciascun partecipante
/// per tutta la fase a gironi — stessa primitiva usata per Highlander e
/// per i confronti diretti del tabellone (vedi TournamentScoring).
@freezed
abstract class TournamentGroup with _$TournamentGroup {
  const factory TournamentGroup({
    required String id,
    required List<String> participantUserIds,
    @Default(<String, int>{}) Map<String, int> cumulativePoints,
  }) = _TournamentGroup;
}
