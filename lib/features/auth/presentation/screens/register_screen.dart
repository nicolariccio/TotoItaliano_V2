import 'package:flutter/material.dart';

import '../../../../core/widgets/placeholder_screen.dart';

/// Placeholder — form di registrazione (nome, cognome, username, email,
/// password, referral opzionale) arriva nella Phase 2.
class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Registrati',
      icon: Icons.person_add_alt_1_rounded,
      subtitle: 'Form di registrazione completo — Phase 2.',
    );
  }
}
