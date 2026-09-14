import 'package:flutter/material.dart';

import '../../../../core/widgets/placeholder_screen.dart';

class LeagueDetailScreen extends StatelessWidget {
  const LeagueDetailScreen({super.key, required this.leagueId});

  final String leagueId;

  @override
  Widget build(BuildContext context) {
    return PlaceholderScreen(
      title: 'Lega $leagueId',
      icon: Icons.shield_rounded,
      subtitle: 'Classifica di lega e membri — Phase 6.',
    );
  }
}
