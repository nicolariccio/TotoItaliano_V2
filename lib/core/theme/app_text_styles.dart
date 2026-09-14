import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tipografia di TotoItaliano: un'unica famiglia (Inter) su tutti i
/// livelli, come nelle app native minimal — la gerarchia viene dal peso e
/// dalla dimensione, non da font diverse. Tracking leggermente negativo
/// sui titoli grandi, come nelle interfacce di sistema Apple.
class AppTextStyles {
  const AppTextStyles._();

  static TextStyle _inter(
    double size,
    FontWeight weight,
    Color color, {
    double? letterSpacing,
    double? height,
  }) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
      );

  static TextStyle displayLarge(Color c) =>
      _inter(34, FontWeight.w700, c, letterSpacing: -0.8, height: 1.1);
  static TextStyle displayMedium(Color c) =>
      _inter(28, FontWeight.w700, c, letterSpacing: -0.6, height: 1.12);
  static TextStyle headlineLarge(Color c) =>
      _inter(24, FontWeight.w600, c, letterSpacing: -0.4, height: 1.15);
  static TextStyle headlineMedium(Color c) =>
      _inter(20, FontWeight.w600, c, letterSpacing: -0.3, height: 1.2);
  static TextStyle titleLarge(Color c) =>
      _inter(18, FontWeight.w600, c, letterSpacing: -0.2);
  static TextStyle titleMedium(Color c) =>
      _inter(16, FontWeight.w600, c, letterSpacing: -0.1);

  static TextStyle bodyLarge(Color c) =>
      _inter(16, FontWeight.w400, c, height: 1.4);
  static TextStyle bodyMedium(Color c) =>
      _inter(14, FontWeight.w400, c, height: 1.4);
  static TextStyle bodySmall(Color c) =>
      _inter(12, FontWeight.w400, c, height: 1.35);

  static TextStyle labelLarge(Color c) => _inter(14, FontWeight.w600, c);
  static TextStyle labelMedium(Color c) => _inter(12, FontWeight.w600, c);
  static TextStyle labelSmall(Color c) => _inter(11, FontWeight.w600, c);

  static TextStyle statNumber(Color c) => _inter(
        22,
        FontWeight.w700,
        c,
        letterSpacing: -0.4,
      ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
}
