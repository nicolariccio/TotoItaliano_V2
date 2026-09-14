import '../models/competition.dart';
import '../models/match.dart';
import '../models/matchday.dart';
import '../models/team.dart';
import '../models/team_standing.dart';

/// Astrazione verso il provider dei dati calcistici (competizioni, squadre,
/// giornate, partite, classifiche). Il resto dell'app dipende solo da
/// questa interfaccia: [MockFootballDataService] la implementa con dati
/// demo, un'implementazione futura potrà collegarsi a un'API reale senza
/// toccare nessun'altra parte del codice.
abstract class FootballDataService {
  Future<List<Competition>> getCompetitions();

  Future<List<Team>> getTeams({required String competitionId});

  Future<List<Matchday>> getMatchdays({required String competitionId});

  Future<List<Match>> getMatches(
      {required String competitionId, String? matchdayId});

  Future<Match?> getMatch(String matchId);

  Future<List<TeamStanding>> getStandings({required String competitionId});

  Future<List<Match>> getResults(
      {required String competitionId, String? matchdayId});
}
