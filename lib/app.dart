import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_constants.dart';
import 'core/notifications/schedina_reminder_providers.dart';
import 'core/providers/theme_mode_provider.dart';
import 'core/routing/app_router.dart';
import 'core/theme/toto_theme.dart';

class TotoItalianoApp extends ConsumerWidget {
  const TotoItalianoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);
    // Nessuna UI: tiene vivo l'ascoltatore che pianifica/cancella i
    // promemoria locali "schedina in scadenza" quando i dati cambiano.
    ref.watch(schedinaReminderSyncProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: TotoTheme.light(),
      darkTheme: TotoTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
