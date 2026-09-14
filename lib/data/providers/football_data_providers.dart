import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/competition.dart';
import '../models/match.dart';
import '../models/matchday.dart';
import '../services/api_football_data_service.dart';
import '../services/football_data_service.dart';

/// Unico punto in cui l'app sceglie l'implementazione concreta di
/// [FootballDataService]. [ApiFootballDataService] chiama api-football
/// attraverso il proxy Cloudflare Worker in cf-worker/ (necessario perché
/// api-sports.io blocca CORS dal browser — vedi commento nella classe): la
/// vera API key resta un secret del worker, mai nel bundle dell'app.
/// [MockFootballDataService] resta disponibile per i test. Se in futuro si
/// passa al piano Blaze di Firebase, [FirestoreFootballDataService] (già
/// scritta, dati sincronizzati da una Cloud Function in functions/) è
/// pronta a sostituire questa riga con un'architettura equivalente lato
/// Firebase invece che Cloudflare.
final Provider<FootballDataService> footballDataServiceProvider = Provider<FootballDataService>(
  (ref) => ApiFootballDataService(),
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
