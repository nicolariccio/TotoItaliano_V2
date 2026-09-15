import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../leagues/presentation/providers/league_providers.dart';
import '../../data/datasources/prediction_firestore_datasource.dart';
import '../../data/repositories/prediction_repository_impl.dart';
import '../../domain/entities/prediction.dart';
import '../../domain/repositories/prediction_repository.dart';

final Provider<PredictionFirestoreDatasource>
    predictionFirestoreDatasourceProvider =
    Provider<PredictionFirestoreDatasource>(
  (ref) => PredictionFirestoreDatasource(FirebaseFirestore.instance),
);

final Provider<PredictionRepository> predictionRepositoryProvider =
    Provider<PredictionRepository>(
  (ref) => PredictionRepositoryImpl(
    ref.watch(firebaseAuthProvider),
    ref.watch(predictionFirestoreDatasourceProvider),
    ref.watch(leagueRepositoryProvider),
  ),
);

/// Tutti i pronostici dell'utente corrente in tutte le sue leghe (storico),
/// reattivo a login/logout.
final StreamProvider<List<Prediction>> myPredictionsProvider =
    StreamProvider<List<Prediction>>((ref) {
  ref.watch(authStateChangesProvider);
  return ref.watch(predictionRepositoryProvider).watchMyPredictions();
});

/// Chiave composita lega+giornata per la schedina di una lega specifica.
typedef LeagueMatchdayKey = ({String leagueId, String matchdayId});

/// I pronostici già salvati dall'utente per [key.leagueId] nella giornata
/// [key.matchdayId], per precompilare la schedina di quella lega.
final StreamProviderFamily<List<Prediction>, LeagueMatchdayKey>
    myPredictionsForLeagueAndMatchdayProvider =
    StreamProvider.family<List<Prediction>, LeagueMatchdayKey>((ref, key) {
  ref.watch(authStateChangesProvider);
  return ref
      .watch(predictionRepositoryProvider)
      .watchMyPredictionsForLeagueAndMatchday(key.leagueId, key.matchdayId);
});
