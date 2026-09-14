import 'package:flutter/material.dart';

import '../../../../core/widgets/placeholder_screen.dart';

/// Placeholder — leghe private dell'utente, Phase 6.
class LeaguesScreen extends StatelessWidget {
  const LeaguesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Leghe',
      icon: Icons.groups_rounded,
      subtitle: 'Crea/entra in lega privata — Phase 6.',
    );
  }
}
