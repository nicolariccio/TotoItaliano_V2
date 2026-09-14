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

/// Pronostico salvato dall'utente corrente per una partita, reattivo a
/// login/logout (segue lo stesso pattern di [currentUserProvider]).
final StreamProviderFamily<Prediction?, String> predictionForMatchProvider =
    StreamProvider.family<Prediction?, String>((ref, matchId) {
  ref.watch(authStateChangesProvider);
  return ref.watch(predictionRepositoryProvider).watchPrediction(matchId);
});

/// Tutti i pronostici dell'utente corrente (storico), reattivo a login/logout.
final StreamProvider<List<Prediction>> myPredictionsProvider =
    StreamProvider<List<Prediction>>((ref) {
  ref.watch(authStateChangesProvider);
  return ref.watch(predictionRepositoryProvider).watchMyPredictions();
});

/// I pronostici già salvati dall'utente per la giornata corrente, per
/// precompilare la schedina.
final StreamProviderFamily<List<Prediction>, String>
    myPredictionsForMatchdayProvider =
    StreamProvider.family<List<Prediction>, String>((ref, matchdayId) {
  ref.watch(authStateChangesProvider);
  return ref
      .watch(predictionRepositoryProvider)
      .watchMyPredictionsForMatchday(matchdayId);
});
