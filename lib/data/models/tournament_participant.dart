import 'package:freezed_annotation/freezed_annotation.dart';

part 'tournament_participant.freezed.dart';

/// Stato di un partecipante dentro un [LeagueTournament], in
/// `leagues/{leagueId}/tournaments/{tournamentId}/participants/{userId}`.
///
/// Username/foto denormalizzati come in [LeagueMember] — stesso motivo:
/// un membro non può leggere il profilo altrui abbastanza a fondo da poter
/// fare il join lato client ogni volta.
@freezed
abstract class TournamentParticipant with _$TournamentParticipant {
  const factory TournamentParticipant({
    required String userId,
    required String username,
    String? photoUrl,
    // Campionato: punti cumulati nel torneo (da createdFromMatchdayId in
    // poi). Highlander: punti dell'ultima giornata elaborata, solo
    // display — l'eliminazione non è una classifica cumulativa.
    @Default(0) int points,
    // Highlander/Coppa: false = eliminato.
    @Default(true) bool active,
    String? eliminatedAtMatchdayId,
  }) = _TournamentParticipant;
}
