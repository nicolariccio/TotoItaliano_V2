import 'package:flutter/material.dart';

import '../theme/app_radii.dart';
import '../theme/app_text_styles.dart';

/// Badge arrotondato per stati (LOCKED, RISULTATO ESATTO, +10, ecc.).
class PillBadge extends StatelessWidget {
  const PillBadge({
    super.key,
    required this.label,
    required this.color,
    this.onColor = Colors.white,
    this.icon,
  });

  final String label;
  final Color color;
  final Color onColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: AppRadii.pillRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: onColor),
            const SizedBox(width: 4),
          ],
          Text(label, style: AppTextStyles.labelSmall(onColor)),
        ],
      ),
    );
  }
}
