import '../../../../data/models/league_tournament.dart';
import '../../../../data/models/tournament_bracket_tie.dart';
import '../../../../data/models/tournament_group.dart';
import '../../../../data/models/tournament_participant.dart';

/// Partecipante minimo necessario per creare un torneo: username/foto
/// denormalizzati (come [TournamentParticipant]) e punti totali (per il
/// seeding del tabellone Coppa) — il chiamante li ha già disponibili da
/// `LeagueMember`, evitando una rilettura qui.
class TournamentSeedMember {
  const TournamentSeedMember({
    required this.userId,
    required this.username,
    this.photoUrl,
    required this.totalPoints,
  });

  final String userId;
  final String username;
  final String? photoUrl;
  final int totalPoints;
}

/// Risultato del calcolo (senza scritture) di un'eliminazione Highlander:
/// mostrato all'utente PRIMA di confermare, poi passato invariato a
/// [TournamentRepository.confirmHighlanderMatchday] — mai ricalcolato, o
/// un eventuale sorteggio di spareggio potrebbe dare un esito diverso da
/// quello mostrato in anteprima.
class HighlanderEliminationPreview {
  const HighlanderEliminationPreview({
    required this.matchdayId,
    required this.pointsByUser,
    required this.eliminatedUserIds,
  });

  final String matchdayId;

  /// Punti di giornata di ogni partecipante ancora attivo prima di questa
  /// elaborazione (per mostrare la classifica di giornata in anteprima).
  final Map<String, int> pointsByUser;

  /// Chi viene eliminato, in ordine (il peggiore per primo).
  final List<String> eliminatedUserIds;
}

abstract class TournamentRepository {
  Stream<List<LeagueTournament>> watchTournaments(String leagueId);

  Future<LeagueTournament?> getTournament(String leagueId, String tournamentId);

  Stream<List<TournamentParticipant>> watchParticipants(
      String leagueId, String tournamentId);

  Stream<List<BracketTie>> watchBracket(String leagueId, String tournamentId);

  Stream<List<TournamentGroup>> watchGroups(
      String leagueId, String tournamentId);

  Future<String> createTournament({
    required String leagueId,
    required String name,
    required TournamentType type,
    required List<String> participantUserIds,
    required List<TournamentSeedMember> seedMembers,
    String? createdFromMatchdayId,
    CoppaFormat? coppaFormat,
    int? groupSize,
    int? advancePerGroup,
    int eliminationsPerMatchday,
    List<HighlanderTiebreak> tiebreakOrder,
  });

  /// Calcola (senza scrivere nulla) chi verrebbe eliminato elaborando
  /// [matchdayId] adesso.
  Future<HighlanderEliminationPreview> previewHighlanderMatchday({
    required String leagueId,
    required String tournamentId,
    required String matchdayId,
  });

  /// Applica [preview] così com'è stata mostrata all'utente.
  Future<void> confirmHighlanderMatchday({
    required String leagueId,
    required String tournamentId,
    required HighlanderEliminationPreview preview,
  });

  /// Assegna [matchdayId] alle sfide del turno [round] ancora senza
  /// giornata (necessario prima di poterle risolvere).
  Future<void> assignMatchdayToRound({
    required String leagueId,
    required String tournamentId,
    required int round,
    required String matchdayId,
  });

  /// Risolve tutte le sfide del turno [round] che hanno una giornata
  /// assegnata; se l'intero turno risulta risolto, genera il turno
  /// successivo (o conclude il torneo se era la finale).
  Future<void> resolveBracketRound({
    required String leagueId,
    required String tournamentId,
    required int round,
  });

  /// Somma i punti di [matchdayId] al cumulativo di ciascun girone.
  Future<void> processGroupsMatchday({
    required String leagueId,
    required String tournamentId,
    required String matchdayId,
  });

  /// Chiude la fase a gironi, qualifica i migliori per girone e genera il
  /// turno 1 del tabellone.
  Future<void> closeGroupsPhaseAndSeedBracket({
    required String leagueId,
    required String tournamentId,
  });

  /// Ricalcola i punti cumulati di ciascun partecipante Campionato,
  /// sommando i punti di ciascuna giornata in [matchdayIds] — il chiamante
  /// passa le giornate dalla creazione del torneo in poi (già disponibili
  /// lato UI tramite `matchdaysProvider`).
  Future<void> refreshCampionatoStandings({
    required String leagueId,
    required String tournamentId,
    required List<String> matchdayIds,
  });
}
