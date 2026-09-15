import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/league.dart';
import '../../../../data/models/league_matchday_config.dart';
import '../../../../data/models/league_member.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/presentation/providers/auth_repository_provider.dart';
import '../../data/datasources/league_firestore_datasource.dart';
import '../../data/repositories/league_repository_impl.dart';
import '../../domain/repositories/league_repository.dart';

/// Chiave composita lega+giornata, usata sia per la config partite escluse
/// sia (typedef equivalente) per i pronostici salvati di quella lega.
typedef LeagueMatchdayKey = ({String leagueId, String matchdayId});

final Provider<LeagueFirestoreDatasource> leagueFirestoreDatasourceProvider =
    Provider<LeagueFirestoreDatasource>(
  (ref) => LeagueFirestoreDatasource(FirebaseFirestore.instance),
);

final Provider<LeagueRepository> leagueRepositoryProvider =
    Provider<LeagueRepository>(
  (ref) => LeagueRepositoryImpl(
    ref.watch(firebaseAuthProvider),
    ref.watch(leagueFirestoreDatasourceProvider),
    ref.watch(userFirestoreDatasourceProvider),
  ),
);

final StreamProvider<List<League>> myLeaguesProvider =
    StreamProvider<List<League>>((ref) {
  ref.watch(authStateChangesProvider);
  return ref.watch(leagueRepositoryProvider).watchMyLeagues();
});

final FutureProviderFamily<League?, String> leagueByIdProvider =
    FutureProvider.family<League?, String>(
  (ref, leagueId) => ref.watch(leagueRepositoryProvider).getLeague(leagueId),
);

final StreamProviderFamily<List<LeagueMember>, String> leagueMembersProvider =
    StreamProvider.family<List<LeagueMember>, String>(
  (ref, leagueId) => ref.watch(leagueRepositoryProvider).watchMembers(leagueId),
);

final StreamProviderFamily<LeagueMatchdayConfig, LeagueMatchdayKey>
    leagueMatchdayConfigProvider =
    StreamProvider.family<LeagueMatchdayConfig, LeagueMatchdayKey>(
  (ref, key) => ref
      .watch(leagueRepositoryProvider)
      .watchMatchdayConfig(key.leagueId, key.matchdayId),
);
