import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tipografia di TotoItaliano: Poppins per i titoli (personalità, "premium
/// sport"), Inter per i testi lunghi (leggibilità).
class AppTextStyles {
  const AppTextStyles._();

  static TextStyle _poppins(double size, FontWeight weight, Color color) =>
      GoogleFonts.poppins(fontSize: size, fontWeight: weight, color: color);

  static TextStyle _inter(double size, FontWeight weight, Color color) =>
      GoogleFonts.inter(fontSize: size, fontWeight: weight, color: color);

  static TextStyle displayLarge(Color c) => _poppins(34, FontWeight.w700, c);
  static TextStyle displayMedium(Color c) => _poppins(28, FontWeight.w700, c);
  static TextStyle headlineLarge(Color c) => _poppins(24, FontWeight.w600, c);
  static TextStyle headlineMedium(Color c) => _poppins(20, FontWeight.w600, c);
  static TextStyle titleLarge(Color c) => _poppins(18, FontWeight.w600, c);
  static TextStyle titleMedium(Color c) => _poppins(16, FontWeight.w600, c);

  static TextStyle bodyLarge(Color c) => _inter(16, FontWeight.w400, c);
  static TextStyle bodyMedium(Color c) => _inter(14, FontWeight.w400, c);
  static TextStyle bodySmall(Color c) => _inter(12, FontWeight.w400, c);

  static TextStyle labelLarge(Color c) => _inter(14, FontWeight.w600, c);
  static TextStyle labelMedium(Color c) => _inter(12, FontWeight.w600, c);
  static TextStyle labelSmall(Color c) => _inter(11, FontWeight.w600, c);

  static TextStyle statNumber(Color c) => _poppins(22, FontWeight.w700, c);
}
