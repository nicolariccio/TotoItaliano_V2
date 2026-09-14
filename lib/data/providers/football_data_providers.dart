import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/competition.dart';
import '../models/match.dart';
import '../models/matchday.dart';
import '../services/firestore_football_data_service.dart';
import '../services/football_data_service.dart';

/// Unico punto in cui l'app sceglie l'implementazione concreta di
/// [FootballDataService]. [FirestoreFootballDataService] legge i dati
/// reali di Serie A sincronizzati da api-football su Firestore da una
/// Cloud Function (vedi functions/src/sync.ts): il client non chiama mai
/// api-football direttamente. [MockFootballDataService] resta disponibile
/// per i test e come implementazione di riferimento dell'interfaccia.
final Provider<FootballDataService> footballDataServiceProvider = Provider<FootballDataService>(
  (ref) => FirestoreFootballDataService(),
);

final FutureProvider<List<Competition>> competitionsProvider = FutureProvider<List<Competition>>(
  (ref) => ref.watch(footballDataServiceProvider).getCompetitions(),
);

final FutureProvider<Competition> activeCompetitionProvider = FutureProvider<Competition>((ref) async {
  final competitions = await ref.watch(competitionsProvider.future);
  return competitions.firstWhere(
    (c) => c.status == CompetitionStatus.active,
    orElse: () => competitions.first,
  );
});

final FutureProvider<List<Matchday>> matchdaysProvider = FutureProvider<List<Matchday>>((ref) async {
  final competition = await ref.watch(activeCompetitionProvider.future);
  return ref.watch(footballDataServiceProvider).getMatchdays(competitionId: competition.id);
});

final FutureProvider<Matchday> currentMatchdayProvider = FutureProvider<Matchday>((ref) async {
  final matchdays = await ref.watch(matchdaysProvider.future);
  return matchdays.firstWhere(
    (m) => m.status == MatchdayStatus.active,
    orElse: () => matchdays.first,
  );
});

final FutureProvider<List<Match>> currentMatchdayMatchesProvider = FutureProvider<List<Match>>((ref) async {
  final competition = await ref.watch(activeCompetitionProvider.future);
  final matchday = await ref.watch(currentMatchdayProvider.future);
  final matches = await ref
      .watch(footballDataServiceProvider)
      .getMatches(competitionId: competition.id, matchdayId: matchday.id);
  return matches..sort((a, b) => a.kickoff.compareTo(b.kickoff));
});

final FutureProviderFamily<Match?, String> matchByIdProvider = FutureProvider.family<Match?, String>(
  (ref, matchId) => ref.watch(footballDataServiceProvider).getMatch(matchId),
);
