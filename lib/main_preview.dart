// ─────────────────────────────────────────────────────────────────────────────
//  Entry point SOLO per l'anteprima visiva delle 5 schermate, con dati finti
//  al posto di Firebase (vedi lib/preview/). Non usato da main.dart, non
//  referenziato da nessun file sotto lib/features o lib/core.
//
//  Avvio: flutter run -t lib/main_preview.dart -d web-server ...
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/constants/app_constants.dart';
import 'core/providers/shared_preferences_provider.dart';
import 'core/providers/theme_mode_provider.dart';
import 'core/theme/toto_theme.dart';
import 'preview/preview_overrides.dart';
import 'preview/preview_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Nessuna dipendenza da Firebase qui: SharedPreferences funziona da sola,
  // quindi la preferenza di tema si comporta esattamente come nell'app
  // reale anche in anteprima.
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        ...previewOverrides,
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const _PreviewApp(),
    ),
  );
}

class _PreviewApp extends ConsumerWidget {
  const _PreviewApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(previewRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: '${AppConstants.appName} (anteprima)',
      debugShowCheckedModeBanner: false,
      theme: TotoTheme.light(),
      darkTheme: TotoTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
