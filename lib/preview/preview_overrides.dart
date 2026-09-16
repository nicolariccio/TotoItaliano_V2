// ─────────────────────────────────────────────────────────────────────────────
//  Override dei provider per l'anteprima visiva: sostituiscono ogni fonte
//  dati Firebase con i dati finti di fake_data.dart. Nessun file sotto
//  lib/features o lib/core dipende da questo — solo main_preview.dart.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/league_matchday_config.dart';
import '../data/providers/football_data_providers.dart';
import '../features/auth/presentation/providers/auth_repository_provider.dart';
import '../features/auth/presentation/providers/current_user_provider.dart';
import '../features/leaderboard/presentation/providers/leaderboard_providers.dart';
import '../features/leagues/presentation/providers/league_providers.dart';
import '../features/predictions/presentation/providers/prediction_providers.dart';
import 'fake_data.dart';
import 'fake_repositories.dart';

final List<Override> previewOverrides = [
  currentUserProvider.overrideWith((ref) => Stream.value(fakeCurrentUser)),
  myLeaguesProvider.overrideWith((ref) => Stream.value(fakeLeagues)),
  leagueByIdProvider.overrideWith(
      (ref, leagueId) => Future.value(fakeLeagueById(leagueId))),
  leagueMembersProvider.overrideWith(
      (ref, leagueId) => Stream.value(fakeMembersFor(leagueId))),
  leagueMatchdayConfigProvider.overrideWith(
    (ref, key) => Stream.value(
      LeagueMatchdayConfig(leagueId: key.leagueId, matchdayId: key.matchdayId),
    ),
  ),
  leagueRepositoryProvider.overrideWithValue(FakeLeagueRepository()),
  authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
  predictionRepositoryProvider.overrideWithValue(FakePredictionRepository()),
  currentMatchdayProvider.overrideWith((ref) => Future.value(matchday12)),
  currentMatchdayMatchesProvider
      .overrideWith((ref) => Future.value(matchday12Matches)),
  matchdaysProvider.overrideWith((ref) => Future.value(fakeMatchdays)),
  matchByIdProvider
      .overrideWith((ref, matchId) => Future.value(fakeMatchById(matchId))),
  myPredictionsProvider.overrideWith((ref) => Stream.value(allFakePredictions)),
  myPredictionsForLeagueAndMatchdayProvider.overrideWith(
    (ref, key) => Stream.value(fakePredictionsFor(key.leagueId, key.matchdayId)),
  ),
  leaderboardProvider.overrideWith((ref) => Stream.value(fakeGeneraleLeaderboard)),
];
