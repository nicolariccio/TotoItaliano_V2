import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_constants.dart';
import 'core/providers/theme_mode_provider.dart';
import 'core/routing/app_router.dart';
import 'core/theme/toto_theme.dart';

class TotoItalianoApp extends ConsumerWidget {
  const TotoItalianoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

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
