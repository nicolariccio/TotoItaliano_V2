import 'package:flutter/material.dart';

import '../../../../core/widgets/placeholder_screen.dart';

class LeagueJoinScreen extends StatelessWidget {
  const LeagueJoinScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Entra in lega',
      icon: Icons.qr_code_rounded,
      subtitle: 'Inserimento invite code — Phase 6.',
    );
  }
}
