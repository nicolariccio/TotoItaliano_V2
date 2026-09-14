import 'package:flutter/material.dart';

/// Palette di TotoItaliano.
///
/// Identità: sport-tech premium, dark-first (come le principali app di
/// fantacalcio/scommesse), con un azzurro "Nazionale" come colore brand e
/// un oro come accento per classifiche/premi.
class AppColors {
  const AppColors._();

  // Brand
  static const Color azzurro = Color(0xFF1B5CFF);
  static const Color azzurroLight = Color(0xFF3DD9FF);
  static const Color oro = Color(0xFFF5B93F);

  // Stato pronostico / esiti
  static const Color success = Color(0xFF1FC46B);
  static const Color error = Color(0xFFFF4D5E);
  static const Color warning = Color(0xFFF5B93F);

  // Podio
  static const Color podiumGold = Color(0xFFFFD34D);
  static const Color podiumSilver = Color(0xFFC7CCD6);
  static const Color podiumBronze = Color(0xFFCD8B4C);

  // Dark surfaces (tema principale)
  static const Color darkBackground = Color(0xFF0A0E1A);
  static const Color darkSurface = Color(0xFF121826);
  static const Color darkSurfaceElevated = Color(0xFF1B2436);
  static const Color darkBorder = Color(0xFF2A3448);

  static const Color darkTextPrimary = Color(0xFFF5F7FA);
  static const Color darkTextSecondary = Color(0xFFA3ACC2);
  static const Color darkTextMuted = Color(0xFF6B7488);

  // Light surfaces (tema alternativo)
  static const Color lightBackground = Color(0xFFF7F8FB);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceElevated = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE3E6ED);

  static const Color lightTextPrimary = Color(0xFF10131C);
  static const Color lightTextSecondary = Color(0xFF565F73);
  static const Color lightTextMuted = Color(0xFF8A93A6);

  /// Gradiente hero usato in header/card in evidenza (es. giornata corrente).
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1B5CFF), Color(0xFF0A2A8F)],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFE08A), Color(0xFFF5B93F)],
  );
}
