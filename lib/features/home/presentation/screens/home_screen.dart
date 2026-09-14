import 'package:flutter/material.dart';

import '../../../../core/widgets/placeholder_screen.dart';

/// Placeholder — hero giornata corrente, countdown, prossime partite:
/// Phase 3 (Competition/Matches) + Phase 4 (Prediction engine).
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Home',
      icon: Icons.home_rounded,
      subtitle: 'Hero giornata, countdown e prossime partite — Phase 3.',
    );
  }
}
