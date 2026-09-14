import 'package:flutter/material.dart';

import '../../../../core/widgets/placeholder_screen.dart';

class LeagueCreateScreen extends StatelessWidget {
  const LeagueCreateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Crea lega',
      icon: Icons.add_circle_outline_rounded,
      subtitle: 'Creazione lega privata — Phase 6.',
    );
  }
}
