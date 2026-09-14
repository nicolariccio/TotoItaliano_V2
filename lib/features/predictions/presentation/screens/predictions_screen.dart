import 'package:flutter/material.dart';

import '../../../../core/widgets/placeholder_screen.dart';

/// Placeholder — lista partite pronosticabili, Phase 4.
class PredictionsScreen extends StatelessWidget {
  const PredictionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Pronostici',
      icon: Icons.sports_soccer_rounded,
      subtitle: 'Lista partite e pronostici — Phase 4.',
    );
  }
}
