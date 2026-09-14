import 'package:flutter/material.dart';

import '../../../../core/widgets/placeholder_screen.dart';

/// Placeholder — classifica generale/giornata con podio, Phase 5.
class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Classifica',
      icon: Icons.emoji_events_rounded,
      subtitle: 'Classifica generale e per giornata — Phase 5.',
    );
  }
}
