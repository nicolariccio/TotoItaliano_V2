import 'package:flutter/material.dart';

import '../../../../core/widgets/placeholder_screen.dart';

/// Placeholder — profilo utente con statistiche, Phase 2/5.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Profilo',
      icon: Icons.person_rounded,
      subtitle: 'Statistiche personali e storico — Phase 2/5.',
    );
  }
}
