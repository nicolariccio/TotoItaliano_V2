import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_constants.dart';
import 'core/routing/app_router.dart';
import 'core/theme/toto_theme.dart';

class TotoItalianoApp extends ConsumerWidget {
  const TotoItalianoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: TotoTheme.light(),
      darkTheme: TotoTheme.dark(),
      themeMode: ThemeMode.dark,
      routerConfig: router,
    );
  }
}
