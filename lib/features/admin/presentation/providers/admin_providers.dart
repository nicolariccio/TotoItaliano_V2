import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/entities/user_role.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/presentation/providers/auth_repository_provider.dart';
import '../../../auth/presentation/providers/current_user_provider.dart';
import '../../data/datasources/admin_football_datasource.dart';
import '../../data/datasources/scoring_recompute_datasource.dart';
import '../../data/repositories/admin_repository_impl.dart';
import '../../domain/repositories/admin_repository.dart';

final Provider<AdminFootballDatasource> adminFootballDatasourceProvider =
    Provider<AdminFootballDatasource>(
  (ref) => AdminFootballDatasource(FirebaseFirestore.instance),
);

final Provider<ScoringRecomputeDatasource> scoringRecomputeDatasourceProvider =
    Provider<ScoringRecomputeDatasource>(
  (ref) => ScoringRecomputeDatasource(FirebaseFirestore.instance),
);

final Provider<AdminRepository> adminRepositoryProvider =
    Provider<AdminRepository>(
  (ref) => AdminRepositoryImpl(
    ref.watch(firebaseAuthProvider),
    ref.watch(userFirestoreDatasourceProvider),
    ref.watch(adminFootballDatasourceProvider),
    ref.watch(scoringRecomputeDatasourceProvider),
  ),
);

/// Vero se l'utente corrente è admin globale, derivato in modo reattivo dal
/// profilo già osservato altrove (`currentUserProvider`): nessuna lettura
/// Firestore aggiuntiva, si aggiorna da solo se il ruolo cambia.
final Provider<bool> isGlobalAdminProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  return user?.role == UserRole.admin;
});
