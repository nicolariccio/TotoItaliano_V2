import 'package:flutter/material.dart';

import '../../../../core/widgets/placeholder_screen.dart';

/// Placeholder — schermata pronostico partita (risultato esatto, 1X2,
/// goal/no goal, over/under), Phase 4.
class MatchDetailScreen extends StatelessWidget {
  const MatchDetailScreen({super.key, required this.matchId});

  final String matchId;

  @override
  Widget build(BuildContext context) {
    return PlaceholderScreen(
      title: 'Partita $matchId',
      icon: Icons.stadium_rounded,
      subtitle: 'UX pronostico completa — Phase 4.',
    );
  }
}
