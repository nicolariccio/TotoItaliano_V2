import 'package:flutter/material.dart';

/// Palette di TotoItaliano.
///
/// Identità: minimal, dark-first, ispirata al linguaggio visivo delle
/// migliori app native (superfici quasi-nere a gradini di grigio invece di
/// blu navy, accenti usati con parsimonia, bordi quasi assenti a favore di
/// differenze di superficie/ombra).
class AppColors {
  const AppColors._();

  // Brand
  static const Color azzurro = Color(0xFF0A84FF);
  static const Color azzurroLight = Color(0xFF64D2FF);
  static const Color oro = Color(0xFFF5B93F);

  // Stato pronostico / esiti
  static const Color success = Color(0xFF32D74B);
  static const Color error = Color(0xFFFF453A);
  static const Color warning = Color(0xFFFFD60A);

  // Podio
  static const Color podiumGold = Color(0xFFFFD34D);
  static const Color podiumSilver = Color(0xFFC7CCD6);
  static const Color podiumBronze = Color(0xFFCD8B4C);

  // Dark surfaces (tema principale) — gradini di grigio neutro, non navy.
  static const Color darkBackground = Color(0xFF000000);
  static const Color darkSurface = Color(0xFF1C1C1E);
  static const Color darkSurfaceElevated = Color(0xFF2C2C2E);
  static const Color darkBorder = Color(0xFF38383A);

  static const Color darkTextPrimary = Color(0xFFF5F5F7);
  static const Color darkTextSecondary = Color(0xFF98989D);
  static const Color darkTextMuted = Color(0xFF636366);

  // Light surfaces (tema alternativo)
  static const Color lightBackground = Color(0xFFF2F2F7);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceElevated = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE5E5EA);

  static const Color lightTextPrimary = Color(0xFF1C1C1E);
  static const Color lightTextSecondary = Color(0xFF6C6C70);
  static const Color lightTextMuted = Color(0xFFAEAEB2);

  /// Gradiente hero, usato con parsimonia (card giornata corrente): due
  /// toni scuri ravvicinati con un accento di brand appena percepibile,
  /// non un blocco blu saturo.
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1C1C1E), Color(0xFF0D1526)],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFE08A), Color(0xFFF5B93F)],
  );
}
