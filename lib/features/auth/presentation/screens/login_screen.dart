import 'package:flutter/material.dart';

import '../../../../core/widgets/placeholder_screen.dart';

/// Placeholder — form di login (email/password + Google Sign-In) e la
/// relativa logica arrivano nella Phase 2 (Authentication).
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Accedi',
      icon: Icons.login_rounded,
      subtitle: 'Login email/password e Google Sign-In — Phase 2.',
    );
  }
}
