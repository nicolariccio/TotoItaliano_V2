import '../../../../data/models/league.dart';
import '../../../../data/models/league_member.dart';

abstract class LeagueRepository {
  /// Crea una nuova lega con l'utente corrente come proprietario e primo
  /// membro. Ritorna l'id della lega creata.
  Future<String> createLeague({required String name, String? description});

  /// Cerca una lega tramite invite code e, se trovata e non se ne fa già
  /// parte, aggiunge l'utente corrente come membro. Lancia
  /// [LeagueNotFoundFailure] se il codice non corrisponde a nessuna lega.
  Future<League> joinLeagueByInviteCode(String inviteCode);

  Future<League?> getLeague(String leagueId);

  Stream<List<LeagueMember>> watchMembers(String leagueId);

  Stream<List<League>> watchMyLeagues();
}
