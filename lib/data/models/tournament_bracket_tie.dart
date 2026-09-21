import 'package:freezed_annotation/freezed_annotation.dart';

part 'tournament_bracket_tie.freezed.dart';

/// Un incontro del tabellone di una Coppa a eliminazione diretta, in
/// `leagues/{leagueId}/tournaments/{tournamentId}/bracket/{tieId}`.
///
/// [round] parte da 1 (primo turno); [slot] è la posizione nel turno,
/// usata solo per ordinare la lista (nessun disegno a tabellone
/// orizzontale: a 390px di larghezza una lista verticale per turno è più
/// leggibile). Un [participantBId] nullo con [participantAId] valorizzato
/// è un bye: [winnerId] si risolve subito ad A senza bisogno di una
/// giornata giocata.
@freezed
abstract class BracketTie with _$BracketTie {
  const factory BracketTie({
    required String id,
    required int round,
    required int slot,
    String? participantAId,
    String? participantBId,
    String? matchdayId,
    int? pointsA,
    int? pointsB,
    String? winnerId,
  }) = _BracketTie;

  const BracketTie._();

  bool get isBye => participantAId != null && participantBId == null;
  bool get isResolved => winnerId != null;
}
