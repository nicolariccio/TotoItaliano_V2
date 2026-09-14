import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';

/// Pulsante a scelta singola usato per i gruppi 1X2, Goal/No Goal e
/// Over/Under. Toccare di nuovo l'opzione selezionata la deseleziona
/// (gestito dal controller, non da questo widget).
class SelectableButton extends StatelessWidget {
  const SelectableButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.enabled = true,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color background = selected ? AppColors.azzurro : theme.colorScheme.surface;
    final Color foreground = selected ? Colors.white : theme.colorScheme.onSurface;

    return Expanded(
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: Material(
          color: background,
          borderRadius: AppRadii.mdRadius,
          child: InkWell(
            borderRadius: AppRadii.mdRadius,
            onTap: enabled ? onTap : null,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: AppRadii.mdRadius,
                border: Border.all(color: selected ? AppColors.azzurro : AppColors.darkBorder),
              ),
              child: Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(color: foreground),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
