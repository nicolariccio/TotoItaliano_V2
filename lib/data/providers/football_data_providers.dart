import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/competition.dart';
import '../models/match.dart';
import '../models/matchday.dart';
import '../models/team.dart';
import '../services/firestore_football_data_service.dart';
import '../services/football_data_service.dart';

/// Unico punto in cui l'app sceglie l'implementazione concreta di
/// [FootballDataService]. Ora legge da Firestore ([FirestoreFootballDataService]):
/// i dati sono scritti da un admin globale (vedi feature `admin`) invece
/// che sincronizzati da api-football (disattivo, piano Spark). Il resto
/// dello stack (ApiFootballDataService + cf-worker/, MockFootballDataService)
/// resta nel repo, inattivo, pronto a essere riattivato cambiando solo
/// questa riga.
final Provider<FootballDataService> footballDataServiceProvider =
    Provider<FootballDataService>(
  (ref) => FirestoreFootballDataService(),
);

final FutureProvider<List<Competition>> competitionsProvider =
    FutureProvider<List<Competition>>(
  (ref) => ref.watch(footballDataServiceProvider).getCompetitions(),
);

final FutureProvider<Competition> activeCompetitionProvider =
    FutureProvider<Competition>((ref) async {
  final competitions = await ref.watch(competitionsProvider.future);
  return competitions.firstWhere(
    (c) => c.status == CompetitionStatus.active,
    orElse: () => competitions.first,
  );
});

final FutureProvider<List<Matchday>> matchdaysProvider =
    FutureProvider<List<Matchday>>((ref) async {
  final competition = await ref.watch(activeCompetitionProvider.future);
  return ref
      .watch(footballDataServiceProvider)
      .getMatchdays(competitionId: competition.id);
});

final FutureProvider<Matchday> currentMatchdayProvider =
    FutureProvider<Matchday>((ref) async {
  final matchdays = await ref.watch(matchdaysProvider.future);
  return matchdays.firstWhere(
    (m) => m.status == MatchdayStatus.active,
    orElse: () => matchdays.first,
  );
});

final FutureProvider<List<Match>> currentMatchdayMatchesProvider =
    FutureProvider<List<Match>>((ref) async {
  final competition = await ref.watch(activeCompetitionProvider.future);
  final matchday = await ref.watch(currentMatchdayProvider.future);
  final matches = await ref
      .watch(footballDataServiceProvider)
      .getMatches(competitionId: competition.id, matchdayId: matchday.id);
  return matches..sort((a, b) => a.kickoff.compareTo(b.kickoff));
});

final FutureProviderFamily<Match?, String> matchByIdProvider =
    FutureProvider.family<Match?, String>(
  (ref, matchId) => ref.watch(footballDataServiceProvider).getMatch(matchId),
);

final FutureProvider<List<Team>> teamsProvider =
    FutureProvider<List<Team>>((ref) async {
  final competition = await ref.watch(activeCompetitionProvider.future);
  return ref
      .watch(footballDataServiceProvider)
      .getTeams(competitionId: competition.id);
});

/// Partite di una giornata specifica (non necessariamente quella corrente):
/// usato dal pannello admin per gestire anche giornate future/passate.
final FutureProviderFamily<List<Match>, String> matchesForMatchdayProvider =
    FutureProvider.family<List<Match>, String>((ref, matchdayId) async {
  final competition = await ref.watch(activeCompetitionProvider.future);
  final matches = await ref
      .watch(footballDataServiceProvider)
      .getMatches(competitionId: competition.id, matchdayId: matchdayId);
  return matches..sort((a, b) => a.kickoff.compareTo(b.kickoff));
});
