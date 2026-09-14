import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Overridden in `main.dart` con l'istanza reale, dopo
/// `SharedPreferences.getInstance()`. Nessun altro provider deve chiamare
/// `getInstance()` direttamente: tutti dipendono da questo.
final Provider<SharedPreferences> sharedPreferencesProvider =
    Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(
      'sharedPreferencesProvider non è stato inizializzato in main.dart'),
);
