import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';

/// Card con gradiente brand, usata per elementi in evidenza (hero giornata
/// corrente, card premio in vetrina, ecc.).
class GradientCard extends StatelessWidget {
  const GradientCard({
    super.key,
    required this.child,
    this.gradient = AppColors.heroGradient,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final Gradient gradient;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: AppRadii.lgRadius,
      ),
      child: child,
    );
  }
}
