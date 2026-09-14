import 'package:flutter/material.dart';

import '../../../../core/widgets/placeholder_screen.dart';

/// Placeholder — invio email di reset via Firebase Auth, Phase 2.
class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Password dimenticata',
      icon: Icons.lock_reset_rounded,
      subtitle: 'Reset password via Firebase Auth — Phase 2.',
    );
  }
}
