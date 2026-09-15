import '../../../../data/models/league.dart';
import '../../../../data/models/league_matchday_config.dart';
import '../../../../data/models/league_member.dart';
import '../../../../data/models/scoring_config.dart';

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

  /// Vero se l'utente corrente è membro di almeno una lega.
  Future<bool> hasAnyLeague();

  /// Vero se l'utente corrente è membro di [leagueId] specificamente —
  /// usato per validare lato client il salvataggio di una schedina di
  /// lega prima ancora di arrivare alle Security Rules.
  Future<bool> isMember(String leagueId);

  /// Aggiorna la configurazione punteggi personalizzata della lega. Solo il
  /// proprietario può farlo (imposto dalle Security Rules).
  Future<void> updateScoringConfig(String leagueId, ScoringConfig config);

  /// Quali partite della giornata [matchdayId] sono escluse dalla schedina
  /// di [leagueId] — vuoto/assente = nessuna esclusione, tutte contano.
  Stream<LeagueMatchdayConfig> watchMatchdayConfig(
      String leagueId, String matchdayId);

  /// Imposta l'elenco di partite escluse per una giornata di questa lega.
  /// Solo il proprietario può farlo.
  Future<void> setExcludedMatches(
      String leagueId, String matchdayId, List<String> excludedMatchIds);

  /// Rimuove un membro dalla lega (mai il proprietario stesso). Solo il
  /// proprietario può farlo.
  Future<void> removeMember(String leagueId, String userId);
}
