import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/providers/football_data_providers.dart';
import '../../../predictions/presentation/providers/prediction_providers.dart';
import '../../domain/profile_stats.dart';

/// Combina lo storico pronostici dell'utente con l'elenco giornate per
/// calcolare [ProfileStats] (miglior giornata, serie in corso, precisione
/// per mercato, storico recente) — vedi `profile_stats.dart` per il perché
/// questi non sono campi diretti di `AppUser`.
final Provider<AsyncValue<ProfileStats>> profileStatsProvider =
    Provider<AsyncValue<ProfileStats>>((ref) {
  final predictionsAsync = ref.watch(myPredictionsProvider);
  final matchdaysAsync = ref.watch(matchdaysProvider);

  if (predictionsAsync.isLoading || matchdaysAsync.isLoading) {
    return const AsyncValue.loading();
  }
  final error = predictionsAsync.error ?? matchdaysAsync.error;
  if (error != null) {
    return AsyncValue.error(error, StackTrace.current);
  }

  final matchdayById = {
    for (final m in matchdaysAsync.requireValue) m.id: m,
  };
  final scored = [
    for (final p in predictionsAsync.requireValue)
      if (p.correct != null && matchdayById[p.matchdayId] != null)
        ScoredPrediction(prediction: p, matchday: matchdayById[p.matchdayId]!),
  ];

  return AsyncValue.data(ProfileStats.compute(scored));
});
