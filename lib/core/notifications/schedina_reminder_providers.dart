import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers/football_data_providers.dart';
import '../../features/auth/presentation/providers/current_user_provider.dart';
import '../../features/leagues/presentation/providers/league_providers.dart';
import '../../features/predictions/presentation/controllers/schedina_state.dart';
import '../../features/predictions/presentation/providers/prediction_providers.dart';
import '../providers/notification_settings_provider.dart';
import 'local_notification_service.dart';
import 'schedina_reminder_calculator.dart';

/// Calcola (senza pianificare nulla) quali promemoria servono adesso, per
/// tutte le leghe dell'utente sulla giornata corrente. Non gira finché non
/// c'è un profilo autenticato: da app root questo provider è vivo anche
/// prima del login, e senza questa guardia proverebbe comunque a leggere
/// `myLeaguesProvider` (query Firestore che senza utente fallirebbe).
final FutureProvider<SchedinaReminderPlan> schedinaReminderPlanProvider =
    FutureProvider<SchedinaReminderPlan>((ref) async {
  final enabled = ref.watch(schedinaRemindersEnabledProvider);
  if (!enabled) return SchedinaReminderPlan.empty;

  final currentUser = ref.watch(currentUserProvider).valueOrNull;
  if (currentUser == null) return SchedinaReminderPlan.empty;

  final leagues = await ref.watch(myLeaguesProvider.future);
  if (leagues.isEmpty) return SchedinaReminderPlan.empty;

  final matchday = await ref.watch(currentMatchdayProvider.future);
  final matches = await ref.watch(currentMatchdayMatchesProvider.future);
  if (matches.isEmpty) return SchedinaReminderPlan.empty;

  final leagueStates = <
      ({String leagueId, String leagueName, bool schedinaComplete})>[];
  for (final league in leagues) {
    final config = await ref.watch(leagueMatchdayConfigProvider(
      (leagueId: league.id, matchdayId: matchday.id),
    ).future);
    final relevant =
        matches.where((m) => !config.excludedMatchIds.contains(m.id)).toList();
    if (relevant.isEmpty) continue;

    final predictions = await ref.watch(myPredictionsForLeagueAndMatchdayProvider(
      (leagueId: league.id, matchdayId: matchday.id),
    ).future);
    final picksByMatch = {
      for (final p in predictions) p.matchId: PickState.fromPrediction(p),
    };
    final complete = relevant
        .every((m) => (picksByMatch[m.id] ?? const PickState()).isComplete);

    leagueStates.add((
      leagueId: league.id,
      leagueName: league.name,
      schedinaComplete: complete,
    ));
  }

  return SchedinaReminderCalculator.compute(
    leagues: leagueStates,
    matchdayId: matchday.id,
    deadline: matchday.predictionDeadline,
    now: DateTime.now(),
  );
});

/// Effetto collaterale: applica il piano calcolato non appena cambia
/// (nuova giornata, schedina salvata, lega aggiunta/rimossa...). Va tenuto
/// vivo con un `ref.watch(schedinaReminderSyncProvider)` da qualche parte
/// vicino alla radice dell'app (vedi `app.dart`), altrimenti Riverpod lo
/// scarterebbe subito non avendo ascoltatori.
final Provider<void> schedinaReminderSyncProvider = Provider<void>((ref) {
  ref.listen<AsyncValue<SchedinaReminderPlan>>(
    schedinaReminderPlanProvider,
    (previous, next) {
      final plan = next.valueOrNull;
      if (plan == null) return;
      unawaited(LocalNotificationService.instance.syncSchedinaReminders(plan));
    },
    fireImmediately: true,
  );
});
