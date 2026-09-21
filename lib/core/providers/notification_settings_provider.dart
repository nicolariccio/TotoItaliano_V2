import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_constants.dart';
import '../notifications/local_notification_service.dart';
import 'shared_preferences_provider.dart';

/// Preferenza "promemoria schedina", persistita localmente. Default true:
/// un avviso quando manca un'ora alla chiusura di una schedina non ancora
/// completa è un aiuto, non un disturbo — l'utente può disattivarlo dal
/// Profilo in qualunque momento.
class SchedinaRemindersController extends StateNotifier<bool> {
  SchedinaRemindersController(this._ref) : super(_load(_ref));

  final Ref _ref;

  static bool _load(Ref ref) =>
      ref.read(sharedPreferencesProvider).getBool(
              AppConstants.prefsSchedinaRemindersEnabled) ??
      true;

  Future<void> setEnabled(bool enabled) async {
    await _ref
        .read(sharedPreferencesProvider)
        .setBool(AppConstants.prefsSchedinaRemindersEnabled, enabled);
    state = enabled;
    if (enabled) {
      await LocalNotificationService.instance.requestPermission();
    } else {
      await LocalNotificationService.instance.cancelAll();
    }
  }
}

final StateNotifierProvider<SchedinaRemindersController, bool>
    schedinaRemindersEnabledProvider =
    StateNotifierProvider<SchedinaRemindersController, bool>(
        (ref) => SchedinaRemindersController(ref));
