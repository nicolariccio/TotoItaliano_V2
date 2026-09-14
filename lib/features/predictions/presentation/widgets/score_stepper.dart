import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';

class ScoreStepper extends StatelessWidget {
  const ScoreStepper({
    super.key,
    required this.label,
    required this.value,
    required this.onIncrement,
    required this.onDecrement,
    this.enabled = true,
  });

  final String label;
  final int? value;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(child: Text(label, style: theme.textTheme.labelLarge)),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: AppRadii.pillRadius,
            border: Border.all(color: AppColors.darkBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_rounded),
                onPressed: enabled ? onDecrement : null,
              ),
              SizedBox(
                width: 32,
                child: Text(
                  '${value ?? '-'}',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_rounded),
                onPressed: enabled ? onIncrement : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
