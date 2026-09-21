import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_constants.dart';
import 'shared_preferences_provider.dart';

/// Preferenza di tema dell'utente, persistita localmente. Default
/// [ThemeMode.system]: l'app segue il sistema finché l'utente non sceglie
/// esplicitamente chiaro o scuro dal Profilo.
class ThemeModeController extends StateNotifier<ThemeMode> {
  ThemeModeController(this._ref) : super(_load(_ref));

  final Ref _ref;

  static ThemeMode _load(Ref ref) {
    final raw =
        ref.read(sharedPreferencesProvider).getString(AppConstants.prefsThemeMode);
    return ThemeMode.values.firstWhere(
      (mode) => mode.name == raw,
      orElse: () => ThemeMode.system,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _ref
        .read(sharedPreferencesProvider)
        .setString(AppConstants.prefsThemeMode, mode.name);
    state = mode;
  }
}

final StateNotifierProvider<ThemeModeController, ThemeMode> themeModeProvider =
    StateNotifierProvider<ThemeModeController, ThemeMode>(
        (ref) => ThemeModeController(ref));
