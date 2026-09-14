import 'package:flutter/material.dart';

import '../../../../core/widgets/placeholder_screen.dart';

/// Placeholder — "I miei pronostici", Phase 4/5.
class PredictionHistoryScreen extends StatelessWidget {
  const PredictionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'I miei pronostici',
      icon: Icons.history_rounded,
      subtitle: 'Storico pronostici ed esiti — Phase 4/5.',
    );
  }
}
