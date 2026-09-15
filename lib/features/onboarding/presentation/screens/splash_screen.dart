import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/toto_theme.dart';

/// Splash mostrata durante l'avvio, mentre `AppRouter` valuta lo stato di
/// autenticazione e di onboarding per decidere la prima route reale.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const c = TotoColors.dark;
    return Scaffold(
      backgroundColor: c.canvas,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sports_soccer_rounded, color: c.brand, size: 56),
            const SizedBox(height: TotoSpace.md),
            Text(
              AppConstants.appName,
              style: Theme.of(context).textTheme.headlineLarge,
            ),
          ],
        ),
      ),
    );
  }
}
