import '../../../../data/models/match.dart';
import '../../../../data/models/matchday.dart';
import '../../../../data/models/team.dart';

abstract class AdminRepository {
  /// Vero se l'utente corrente è un admin globale (`AppUser.role == admin`).
  /// Guardia lato client per la UI: la sicurezza reale è nelle Security
  /// Rules (`isGlobalAdmin()`), non falsificabile modificando il client.
  Future<bool> isGlobalAdmin();

  Future<String> createCompetition({required String name, required String season});

  Future<void> seedTeams(String competitionId, List<Team> teams);

  Future<String> createMatchday({
    required String competitionId,
    required int number,
    required DateTime startDate,
    required DateTime endDate,
    required DateTime predictionDeadline,
  });

  Future<void> setMatchdayStatus(
      String competitionId, String matchdayId, MatchdayStatus status);

  Future<String> createMatch({
    required String competitionId,
    required String matchdayId,
    required Team homeTeam,
    required Team awayTeam,
    required DateTime kickoff,
  });

  /// Inserisce il risultato ufficiale e ricalcola i punti di tutti i
  /// pronostici collegati, in tutte le leghe. Ritorna il numero di
  /// pronostici segnati.
  Future<int> setMatchResultAndRecompute({
    required Match match,
    required int homeScore,
    required int awayScore,
  });
}
