import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Schermata segnaposto, usata SOLO per le route non ancora implementate
/// nella fase corrente di sviluppo (vedi roadmap a fasi). Non è mai lo
/// stato finale di una schermata: ogni occorrenza viene sostituita quando
/// la feature corrispondente viene implementata.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({
    super.key,
    required this.title,
    this.icon = Icons.construction_rounded,
    this.subtitle =
        'Questa sezione sarà disponibile in una prossima fase di sviluppo.',
  });

  final String title;
  final IconData icon;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: AppColors.azzurro),
              const SizedBox(height: 16),
              Text(title,
                  style: theme.textTheme.headlineMedium,
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(subtitle,
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
