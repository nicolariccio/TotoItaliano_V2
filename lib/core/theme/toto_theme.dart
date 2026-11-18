// ─────────────────────────────────────────────────────────────────────────────
//  TotoItaliano — Design System
//  Drop-in ThemeData + semantic tokens.
//
//  pubspec.yaml:
//    google_fonts: ^6.2.1
//
//  main.dart:
//    MaterialApp(
//      theme: TotoTheme.light(),
//      darkTheme: TotoTheme.dark(),
//      themeMode: ThemeMode.dark,   // default: "Stadio di notte"
//    );
//
//  Accesso ai token semantici:
//    final c = Theme.of(context).extension<TotoColors>()!;
//    Container(color: c.surface1, ...)
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ═════════════════════════════════════════════════════════════════════════════
//  1. PALETTE PRIMITIVA  (mai usata direttamente nei widget — solo qui dentro)
// ═════════════════════════════════════════════════════════════════════════════

class TotoPalette {
  TotoPalette._();

  // ── Neutri scuri ("Stadio di notte": nero con una punta di verde prato) ───
  static const ink000 = Color(0xFF060A08); // canvas
  static const ink050 = Color(0xFF0A0F0C); // surface flat
  static const ink100 = Color(0xFF0F1612); // card interattiva
  static const ink200 = Color(0xFF151E19); // card elevata / input / segmented
  static const ink300 = Color(0xFF1D2822); // pressed / thumb / bordo sottile
  static const ink400 = Color(0xFF2B3A32); // bordo forte
  static const ink500 = Color(0xFF3A4D42); // bordo focus
  static const ink600 = Color(0xFF4A5A50); // disabled text
  static const ink700 = Color(0xFF86928A); // text tertiary  (6.3:1 su ink000)
  static const ink800 = Color(0xFFB0BAB3); // text secondary (9.9:1)
  static const ink900 = Color(0xFFF4F7F2); // text primary  (18.5:1)

  // ── Neutri chiari (light mode) ─────────────────────────────────────────────
  static const day000 = Color(0xFFFFFFFF);
  static const day050 = Color(0xFFF3F6EF);
  static const day100 = Color(0xFFFFFFFF);
  static const day200 = Color(0xFFEBEFE6);
  static const day300 = Color(0xFFE1E6DB);
  static const day400 = Color(0xFFD9DFD2);
  static const day500 = Color(0xFFC3CBBC);
  static const day600 = Color(0xFFA3ADA5);
  static const day700 = Color(0xFF5F6A62); // 5.3:1 su canvas chiaro
  static const day800 = Color(0xFF414B44);
  static const day900 = Color(0xFF0A0F0A);

  // ── Brand verde prato ──────────────────────────────────────────────────────
  // Su scuro l'accento è un lime "volt" (testo scuro sopra, 14:1). Su chiaro
  // il lime non regge, quindi il brand diventa un verde profondo con testo
  // bianco (5.4:1): due valori, un'unica identità.
  static const pitchVolt = Color(0xFFC8F52F); // accent su scuro: testo/fill
  static const pitchVoltPressed = Color(0xFFA9D61C);
  static const pitchVoltTint = Color(0xFF16200A); // container su scuro
  static const pitchDeep = Color(0xFF0E7A3A); // brand su chiaro: testo/fill
  static const pitchDeepPressed = Color(0xFF0A5F2E);
  static const pitchDeepTint = Color(0xFFE6F4D2); // container su chiaro
  static const onVolt = Color(0xFF0A0F0A);

  // ── Semantici ──────────────────────────────────────────────────────────────
  static const green = Color(0xFF34D9A0); // mint: distinto dal lime del brand
  static const greenTintDark = Color(0xFF0F2A22);
  static const greenBorderDark = Color(0xFF1F5C47);
  static const greenLight = Color(0xFF0A7A68);

  static const red = Color(0xFFFF5A50); // 6.4:1
  static const redTintDark = Color(0xFF2C1315);
  static const redBorderDark = Color(0xFF6B2229);
  static const redLight = Color(0xFFC81E14);

  static const amber = Color(0xFFFFC043); // 12.1:1
  static const amberTintDark = Color(0xFF2A2110);
  static const amberBorderDark = Color(0xFF6B5217);
  static const amberLight = Color(0xFF9A6300);

  // ── Podio / premi ──────────────────────────────────────────────────────────
  static const gold = Color(0xFFF5C451); // 12.2:1
  static const goldTintDark = Color(0xFF2B2209);
  static const silver = Color(0xFFC7CBD1);
  static const silverTintDark = Color(0xFF1F2124);
  static const bronze = Color(0xFFD08A52);
  static const bronzeTintDark = Color(0xFF2A1C10);

  // ── Overlay ────────────────────────────────────────────────────────────────
  static const scrim = Color(0xCC000000); // 80% — modali su fondo quasi nero
  static const hairlineDark = Color(0x14FFFFFF); // 8%  — bordo superiore vetro
  static const specularDark = Color(0x0FFFFFFF); // 6%  — edge highlight card
}

// ═════════════════════════════════════════════════════════════════════════════
//  2. TOKEN SEMANTICI  (ThemeExtension — è QUESTO che usi nei widget)
// ═════════════════════════════════════════════════════════════════════════════

@immutable
class TotoColors extends ThemeExtension<TotoColors> {
  const TotoColors({
    required this.canvas,
    required this.surfaceFlat,
    required this.surface1,
    required this.surface2,
    required this.surfacePressed,
    required this.borderSubtle,
    required this.borderStrong,
    required this.borderFocus,
    required this.specular,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textDisabled,
    required this.textOnPrimary,
    required this.brand,
    required this.brandFill,
    required this.brandPressed,
    required this.brandContainer,
    required this.success,
    required this.successContainer,
    required this.successBorder,
    required this.danger,
    required this.dangerContainer,
    required this.dangerBorder,
    required this.warning,
    required this.warningContainer,
    required this.warningBorder,
    required this.neutralContainer,
    required this.neutralBorder,
    required this.gold,
    required this.goldContainer,
    required this.silver,
    required this.silverContainer,
    required this.bronze,
    required this.bronzeContainer,
    required this.scrim,
    required this.navHairline,
  });

  // superfici
  final Color canvas;
  final Color surfaceFlat;
  final Color surface1; // card interattiva
  final Color surface2; // card elevata, sheet, input
  final Color surfacePressed;

  // bordi
  final Color borderSubtle;
  final Color borderStrong;
  final Color borderFocus;
  final Color specular; // hairline chiaro sul bordo superiore delle card

  // testo
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary; // pavimento leggibile — niente di più fioco
  final Color textDisabled; // MAI portatore di significato
  final Color textOnPrimary;

  // brand
  final Color brand; // testo/icone accent
  final Color brandFill; // riempimento pulsanti/chip selezionati
  final Color brandPressed;
  final Color brandContainer;

  // stati
  final Color success, successContainer, successBorder;
  final Color danger, dangerContainer, dangerBorder;
  final Color warning, warningContainer, warningBorder;
  final Color neutralContainer, neutralBorder;

  // podio
  final Color gold, goldContainer;
  final Color silver, silverContainer;
  final Color bronze, bronzeContainer;

  final Color scrim;
  final Color navHairline;

  // ── Dark ───────────────────────────────────────────────────────────────────
  static const dark = TotoColors(
    canvas: TotoPalette.ink000,
    surfaceFlat: TotoPalette.ink050,
    surface1: TotoPalette.ink100,
    surface2: TotoPalette.ink200,
    surfacePressed: TotoPalette.ink300,
    borderSubtle: TotoPalette.ink300,
    borderStrong: TotoPalette.ink400,
    borderFocus: TotoPalette.pitchVolt,
    specular: TotoPalette.specularDark,
    textPrimary: TotoPalette.ink900,
    textSecondary: TotoPalette.ink800,
    textTertiary: TotoPalette.ink700,
    textDisabled: TotoPalette.ink600,
    textOnPrimary: TotoPalette.onVolt,
    brand: TotoPalette.pitchVolt,
    brandFill: TotoPalette.pitchVolt,
    brandPressed: TotoPalette.pitchVoltPressed,
    brandContainer: TotoPalette.pitchVoltTint,
    success: TotoPalette.green,
    successContainer: TotoPalette.greenTintDark,
    successBorder: TotoPalette.greenBorderDark,
    danger: TotoPalette.red,
    dangerContainer: TotoPalette.redTintDark,
    dangerBorder: TotoPalette.redBorderDark,
    warning: TotoPalette.amber,
    warningContainer: TotoPalette.amberTintDark,
    warningBorder: TotoPalette.amberBorderDark,
    neutralContainer: TotoPalette.ink200,
    neutralBorder: TotoPalette.ink400,
    gold: TotoPalette.gold,
    goldContainer: TotoPalette.goldTintDark,
    silver: TotoPalette.silver,
    silverContainer: TotoPalette.silverTintDark,
    bronze: TotoPalette.bronze,
    bronzeContainer: TotoPalette.bronzeTintDark,
    scrim: TotoPalette.scrim,
    navHairline: TotoPalette.hairlineDark,
  );

  // ── Light ──────────────────────────────────────────────────────────────────
  static const light = TotoColors(
    canvas: TotoPalette.day050,
    surfaceFlat: TotoPalette.day000,
    surface1: TotoPalette.day100,
    surface2: TotoPalette.day000,
    surfacePressed: TotoPalette.day200,
    borderSubtle: TotoPalette.day400,
    borderStrong: TotoPalette.day500,
    borderFocus: TotoPalette.pitchDeep,
    specular: Color(0x00FFFFFF),
    textPrimary: TotoPalette.day900,
    textSecondary: TotoPalette.day800,
    textTertiary: TotoPalette.day700,
    textDisabled: TotoPalette.day600,
    textOnPrimary: Colors.white,
    brand: TotoPalette.pitchDeep,
    brandFill: TotoPalette.pitchDeep,
    brandPressed: TotoPalette.pitchDeepPressed,
    brandContainer: TotoPalette.pitchDeepTint,
    success: TotoPalette.greenLight,
    successContainer: Color(0xFFDDF5EE),
    successBorder: Color(0xFF9EDCCB),
    danger: TotoPalette.redLight,
    dangerContainer: Color(0xFFFDE8E7),
    dangerBorder: Color(0xFFF5B8B4),
    warning: TotoPalette.amberLight,
    warningContainer: Color(0xFFFFF3DC),
    warningBorder: Color(0xFFF0D19A),
    neutralContainer: TotoPalette.day200,
    neutralBorder: TotoPalette.day400,
    gold: Color(0xFF9A7411),
    goldContainer: Color(0xFFFCF2D9),
    silver: Color(0xFF6E737A),
    silverContainer: Color(0xFFF0F1F3),
    bronze: Color(0xFF8C5526),
    bronzeContainer: Color(0xFFF7E9DD),
    scrim: Color(0x66000000),
    navHairline: Color(0x14000000),
  );

  @override
  TotoColors copyWith({
    Color? canvas,
    Color? surfaceFlat,
    Color? surface1,
    Color? surface2,
    Color? surfacePressed,
    Color? borderSubtle,
    Color? borderStrong,
    Color? borderFocus,
    Color? specular,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? textDisabled,
    Color? textOnPrimary,
    Color? brand,
    Color? brandFill,
    Color? brandPressed,
    Color? brandContainer,
    Color? success,
    Color? successContainer,
    Color? successBorder,
    Color? danger,
    Color? dangerContainer,
    Color? dangerBorder,
    Color? warning,
    Color? warningContainer,
    Color? warningBorder,
    Color? neutralContainer,
    Color? neutralBorder,
    Color? gold,
    Color? goldContainer,
    Color? silver,
    Color? silverContainer,
    Color? bronze,
    Color? bronzeContainer,
    Color? scrim,
    Color? navHairline,
  }) {
    return TotoColors(
      canvas: canvas ?? this.canvas,
      surfaceFlat: surfaceFlat ?? this.surfaceFlat,
      surface1: surface1 ?? this.surface1,
      surface2: surface2 ?? this.surface2,
      surfacePressed: surfacePressed ?? this.surfacePressed,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      borderStrong: borderStrong ?? this.borderStrong,
      borderFocus: borderFocus ?? this.borderFocus,
      specular: specular ?? this.specular,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      textDisabled: textDisabled ?? this.textDisabled,
      textOnPrimary: textOnPrimary ?? this.textOnPrimary,
      brand: brand ?? this.brand,
      brandFill: brandFill ?? this.brandFill,
      brandPressed: brandPressed ?? this.brandPressed,
      brandContainer: brandContainer ?? this.brandContainer,
      success: success ?? this.success,
      successContainer: successContainer ?? this.successContainer,
      successBorder: successBorder ?? this.successBorder,
      danger: danger ?? this.danger,
      dangerContainer: dangerContainer ?? this.dangerContainer,
      dangerBorder: dangerBorder ?? this.dangerBorder,
      warning: warning ?? this.warning,
      warningContainer: warningContainer ?? this.warningContainer,
      warningBorder: warningBorder ?? this.warningBorder,
      neutralContainer: neutralContainer ?? this.neutralContainer,
      neutralBorder: neutralBorder ?? this.neutralBorder,
      gold: gold ?? this.gold,
      goldContainer: goldContainer ?? this.goldContainer,
      silver: silver ?? this.silver,
      silverContainer: silverContainer ?? this.silverContainer,
      bronze: bronze ?? this.bronze,
      bronzeContainer: bronzeContainer ?? this.bronzeContainer,
      scrim: scrim ?? this.scrim,
      navHairline: navHairline ?? this.navHairline,
    );
  }

  @override
  TotoColors lerp(ThemeExtension<TotoColors>? other, double t) {
    if (other is! TotoColors) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return TotoColors(
      canvas: c(canvas, other.canvas),
      surfaceFlat: c(surfaceFlat, other.surfaceFlat),
      surface1: c(surface1, other.surface1),
      surface2: c(surface2, other.surface2),
      surfacePressed: c(surfacePressed, other.surfacePressed),
      borderSubtle: c(borderSubtle, other.borderSubtle),
      borderStrong: c(borderStrong, other.borderStrong),
      borderFocus: c(borderFocus, other.borderFocus),
      specular: c(specular, other.specular),
      textPrimary: c(textPrimary, other.textPrimary),
      textSecondary: c(textSecondary, other.textSecondary),
      textTertiary: c(textTertiary, other.textTertiary),
      textDisabled: c(textDisabled, other.textDisabled),
      textOnPrimary: c(textOnPrimary, other.textOnPrimary),
      brand: c(brand, other.brand),
      brandFill: c(brandFill, other.brandFill),
      brandPressed: c(brandPressed, other.brandPressed),
      brandContainer: c(brandContainer, other.brandContainer),
      success: c(success, other.success),
      successContainer: c(successContainer, other.successContainer),
      successBorder: c(successBorder, other.successBorder),
      danger: c(danger, other.danger),
      dangerContainer: c(dangerContainer, other.dangerContainer),
      dangerBorder: c(dangerBorder, other.dangerBorder),
      warning: c(warning, other.warning),
      warningContainer: c(warningContainer, other.warningContainer),
      warningBorder: c(warningBorder, other.warningBorder),
      neutralContainer: c(neutralContainer, other.neutralContainer),
      neutralBorder: c(neutralBorder, other.neutralBorder),
      gold: c(gold, other.gold),
      goldContainer: c(goldContainer, other.goldContainer),
      silver: c(silver, other.silver),
      silverContainer: c(silverContainer, other.silverContainer),
      bronze: c(bronze, other.bronze),
      bronzeContainer: c(bronzeContainer, other.bronzeContainer),
      scrim: c(scrim, other.scrim),
      navHairline: c(navHairline, other.navHairline),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  3. SPAZIATURE · RAGGI · MOTION
// ═════════════════════════════════════════════════════════════════════════════

class TotoSpace {
  TotoSpace._();
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16; // gutter orizzontale standard
  static const double xl = 20;
  static const double xxl = 24; // padding card hero
  static const double x3l = 32; // separazione fra sezioni
  static const double x4l = 40;
  static const double x5l = 48; // separazione fra blocchi maggiori
  static const double x6l = 64;

  /// Spazio libero sotto l'ultimo elemento di una lista, per non finire
  /// dietro la bottom nav in vetro. Sommalo a MediaQuery.padding.bottom.
  static const double navClearance = 76;
}

class TotoRadius {
  TotoRadius._();
  static const double xs = 6; // badge interno, chip minuscole
  static const double sm = 10; // input, segmented, chip valore
  static const double md = 16; // riga lista, CTA a tutta larghezza
  static const double lg = 22; // card primaria, top dei bottom sheet
  static const double xl = 28; // card hero "giornata corrente"
  static const double full = 999; // pill, avatar

  /// Raggio interno corretto per un elemento annidato.
  /// Regola: raggio_interno = raggio_esterno − padding.
  static double nested(double outer, double padding) =>
      (outer - padding).clamp(0.0, outer);
}

class TotoMotion {
  TotoMotion._();
  static const instant = Duration(milliseconds: 100); // press, ripple
  static const fast = Duration(milliseconds: 180); // chip, badge, toggle
  static const base = Duration(milliseconds: 280); // sheet, espansione, stagger
  static const slow = Duration(milliseconds: 420); // transizione di pagina
  static const celebrate = Duration(milliseconds: 1800); // coriandoli

  static const enter = Curves.easeOutQuint;
  static const exit = Curves.easeInCubic;
  static const standard = Curves.easeOutCubic;
  static const emphasized = Curves.easeOutBack; // solo su scale, mai su layout

  static const staggerStep = Duration(milliseconds: 40);

  /// L'uscita dura il 65% dell'entrata.
  static Duration exitOf(Duration enterDuration) =>
      Duration(milliseconds: (enterDuration.inMilliseconds * 0.65).round());

  /// Rispetta "Riduci movimento" di sistema.
  static bool reduced(BuildContext context) =>
      MediaQuery.of(context).disableAnimations;
}

// ═════════════════════════════════════════════════════════════════════════════
//  4. TIPOGRAFIA
//
//  Due famiglie, due ruoli:
//    Inter   → tutta la UI e il testo corrente
//    Archivo → solo il tier "display": numeri grandi, countdown, podio, punti
//
//  Regola del tracking (già applicata sotto):
//    ≥ 28px : size × −0.022     17–24px : size × −0.011
//    14–16  : 0                 ≤ 13px  : size × +0.01
// ═════════════════════════════════════════════════════════════════════════════

class TotoType {
  TotoType._();

  static const _tabular = <FontFeature>[
    FontFeature.tabularFigures(),
    FontFeature.slashedZero(),
  ];

  /// Numeri: sempre a larghezza fissa, altrimenti countdown e punteggi
  /// "ballano" a ogni tick.
  static TextStyle number(
    double size, {
    FontWeight weight = FontWeight.w800,
    Color? color,
    bool display = true,
  }) {
    final base = display
        ? GoogleFonts.archivo(fontWeight: weight)
        : GoogleFonts.inter(fontWeight: weight);
    return base.copyWith(
      fontSize: size,
      color: color,
      height: 1.0,
      letterSpacing: size >= 28 ? size * -0.022 : size * -0.011,
      fontFeatures: _tabular,
    );
  }

  static TextTheme build(Color primary, Color secondary, Color tertiary) {
    TextStyle inter(
      double size,
      FontWeight w,
      double ls,
      double lh, {
      Color? c,
    }) =>
        GoogleFonts.inter(
          fontSize: size,
          fontWeight: w,
          letterSpacing: ls,
          height: lh,
          color: c ?? primary,
        );

    TextStyle archivo(double size, FontWeight w, double ls, double lh) =>
        GoogleFonts.archivo(
          fontSize: size,
          fontWeight: w,
          letterSpacing: ls,
          height: lh,
          color: primary,
          fontFeatures: _tabular,
        );

    return TextTheme(
      // ── Display (Archivo) — countdown, punti, posizione podio ─────────────
      displayLarge: archivo(52, FontWeight.w800, -1.4, 1.00),
      displayMedium: archivo(38, FontWeight.w800, -1.0, 1.05),
      displaySmall: archivo(28, FontWeight.w800, -0.7, 1.10),

      // ── Headline / Title (Inter) ──────────────────────────────────────────
      headlineLarge: inter(28, FontWeight.w700, -0.62, 1.18),
      headlineMedium: inter(24, FontWeight.w700, -0.53, 1.20),
      headlineSmall: inter(20, FontWeight.w600, -0.22, 1.25),

      titleLarge: inter(20, FontWeight.w600, -0.22, 1.25),
      titleMedium: inter(17, FontWeight.w600, -0.19, 1.30),
      titleSmall: inter(15, FontWeight.w600, 0, 1.30),

      // ── Body (Inter) — minimo 15px, mai sotto ─────────────────────────────
      bodyLarge: inter(17, FontWeight.w400, -0.19, 1.45),
      bodyMedium: inter(15, FontWeight.w400, 0, 1.47, c: secondary),
      bodySmall: inter(13, FontWeight.w400, 0.13, 1.40, c: secondary),

      // ── Label ─────────────────────────────────────────────────────────────
      labelLarge: inter(15, FontWeight.w600, 0, 1.20), // testo pulsanti
      labelMedium: inter(13, FontWeight.w600, 0.13, 1.20, c: secondary),
      labelSmall: inter(11, FontWeight.w700, 0.66, 1.10, c: tertiary),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  5. THEMEDATA
// ═════════════════════════════════════════════════════════════════════════════

class TotoTheme {
  TotoTheme._();

  static ThemeData dark() => _build(TotoColors.dark, Brightness.dark);
  static ThemeData light() => _build(TotoColors.light, Brightness.light);

  static ThemeData _build(TotoColors c, Brightness brightness) {
    final text = TotoType.build(c.textPrimary, c.textSecondary, c.textTertiary);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: c.canvas,
      canvasColor: c.canvas,
      splashFactory: InkSparkle.splashFactory,
      extensions: <ThemeExtension<dynamic>>[c],

      colorScheme: ColorScheme(
        brightness: brightness,
        primary: c.brandFill,
        onPrimary: c.textOnPrimary,
        primaryContainer: c.brandContainer,
        onPrimaryContainer: c.brand,
        secondary: c.brand,
        onSecondary: c.textOnPrimary,
        secondaryContainer: c.neutralContainer,
        onSecondaryContainer: c.textPrimary,
        tertiary: c.gold,
        onTertiary: c.canvas,
        tertiaryContainer: c.goldContainer,
        onTertiaryContainer: c.gold,
        error: c.danger,
        onError: c.canvas,
        errorContainer: c.dangerContainer,
        onErrorContainer: c.danger,
        surface: c.surface1,
        onSurface: c.textPrimary,
        surfaceContainerLowest: c.canvas,
        surfaceContainerLow: c.surfaceFlat,
        surfaceContainer: c.surface1,
        surfaceContainerHigh: c.surface2,
        surfaceContainerHighest: c.surfacePressed,
        onSurfaceVariant: c.textSecondary,
        outline: c.borderStrong,
        outlineVariant: c.borderSubtle,
        scrim: c.scrim,
        shadow: Colors.black,
        inverseSurface: c.textPrimary,
        onInverseSurface: c.canvas,
        inversePrimary: c.brandFill,
      ),

      textTheme: text,
      primaryTextTheme: text,

      // ── Page transition: iOS-like su entrambe le piattaforme ──────────────
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),

      // ── App bar: nessuna elevazione, nessun tinting ───────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: c.canvas,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: text.titleMedium,
        iconTheme: IconThemeData(color: c.textPrimary, size: 22),
      ),

      // ── Card: il bordo esiste solo se la card è toccabile ─────────────────
      cardTheme: CardThemeData(
        color: c.surface1,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TotoRadius.lg),
          side: BorderSide(color: c.borderSubtle, width: 1),
        ),
      ),

      dividerTheme: DividerThemeData(
        color: c.borderSubtle,
        thickness: 1,
        space: 1,
      ),

      // ── CTA primaria: raggio 14 a tutta larghezza, pill solo se compatta ──
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((s) {
            if (s.contains(WidgetState.disabled)) return c.neutralContainer;
            if (s.contains(WidgetState.pressed)) return c.brandPressed;
            return c.brandFill;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.disabled)
                  ? c.textDisabled
                  : c.textOnPrimary),
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          minimumSize: const WidgetStatePropertyAll(Size.fromHeight(52)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: TotoSpace.lg),
          ),
          textStyle: WidgetStatePropertyAll(
            text.labelLarge!.copyWith(fontSize: 17),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(TotoRadius.md),
            ),
          ),
          elevation: const WidgetStatePropertyAll(0),
        ),
      ),

      // ── Secondaria: tonale, niente outline (su fondo scuro legge meglio) ──
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.pressed)
                  ? c.surfacePressed
                  : Colors.transparent),
          foregroundColor: WidgetStatePropertyAll(c.brand),
          // Larghezza minima finita: con Size.fromHeight (larghezza infinita)
          // un TextButton dentro una Row (es. "Non hai un account?
          // Registrati") rompeva il layout e la schermata restava vuota.
          minimumSize: const WidgetStatePropertyAll(Size(64, 48)),
          textStyle: WidgetStatePropertyAll(text.labelLarge),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(TotoRadius.md),
            ),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(c.textPrimary),
          side: WidgetStatePropertyAll(BorderSide(color: c.borderStrong)),
          minimumSize: const WidgetStatePropertyAll(Size.fromHeight(48)),
          textStyle: WidgetStatePropertyAll(text.labelLarge),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(TotoRadius.md),
            ),
          ),
        ),
      ),

      // ── Input ─────────────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface2,
        isDense: false,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: TotoSpace.lg,
          vertical: TotoSpace.lg,
        ),
        constraints: const BoxConstraints(minHeight: 52),
        hintStyle: text.bodyLarge!.copyWith(color: c.textTertiary),
        labelStyle: text.labelMedium,
        floatingLabelStyle: text.labelMedium!.copyWith(color: c.brand),
        helperStyle: text.bodySmall,
        errorStyle: text.bodySmall!.copyWith(color: c.danger),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(TotoRadius.md),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(TotoRadius.md),
          borderSide: BorderSide(color: c.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(TotoRadius.md),
          borderSide: BorderSide(color: c.borderFocus, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(TotoRadius.md),
          borderSide: BorderSide(color: c.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(TotoRadius.md),
          borderSide: BorderSide(color: c.danger, width: 2),
        ),
      ),

      // ── Chip: base per i selettori di valore della schedina ───────────────
      chipTheme: ChipThemeData(
        backgroundColor: c.surface2,
        selectedColor: c.brandFill,
        disabledColor: c.neutralContainer,
        labelStyle: text.labelLarge!,
        secondaryLabelStyle: text.labelLarge!.copyWith(color: c.textOnPrimary),
        padding: const EdgeInsets.symmetric(
          horizontal: TotoSpace.lg,
          vertical: TotoSpace.md,
        ),
        side: BorderSide.none,
        showCheckmark: false,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TotoRadius.sm),
        ),
      ),

      // ── Bottom navigation ─────────────────────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        height: 56,
        backgroundColor: c.canvas.withValues(alpha: 0.72),
        surfaceTintColor: Colors.transparent,
        indicatorColor: Colors.transparent,
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(
            size: 24,
            color: s.contains(WidgetState.selected) ? c.brand : c.textTertiary,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => GoogleFonts.inter(
            fontSize: 10,
            fontWeight: s.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w500,
            letterSpacing: 0.1,
            color: s.contains(WidgetState.selected)
                ? c.textPrimary
                : c.textTertiary,
          ),
        ),
      ),

      // ── Bottom sheet ──────────────────────────────────────────────────────
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface2,
        surfaceTintColor: Colors.transparent,
        modalBarrierColor: c.scrim,
        showDragHandle: true,
        dragHandleColor: c.borderStrong,
        dragHandleSize: const Size(36, 4),
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(TotoRadius.lg),
          ),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: c.surface2,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: text.titleLarge,
        contentTextStyle: text.bodyMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TotoRadius.lg),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.surface2,
        contentTextStyle: text.bodyLarge,
        actionTextColor: c.brand,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        insetPadding: const EdgeInsets.all(TotoSpace.lg),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TotoRadius.md),
        ),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.brand,
        linearTrackColor: c.neutralContainer,
        circularTrackColor: c.neutralContainer,
        linearMinHeight: 6,
      ),

      listTileTheme: ListTileThemeData(
        minVerticalPadding: TotoSpace.md,
        iconColor: c.textSecondary,
        titleTextStyle: text.titleSmall,
        subtitleTextStyle: text.bodySmall,
        contentPadding: const EdgeInsets.symmetric(horizontal: TotoSpace.lg),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TotoRadius.md),
        ),
      ),

      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? c.brandFill : c.neutralContainer),
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? c.textOnPrimary : c.textTertiary),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: c.surfacePressed,
          borderRadius: BorderRadius.circular(TotoRadius.sm),
        ),
        textStyle: text.bodySmall!.copyWith(color: c.textPrimary),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  6. SCORCIATOIE
// ═════════════════════════════════════════════════════════════════════════════

extension TotoThemeX on BuildContext {
  TotoColors get c => Theme.of(this).extension<TotoColors>()!;
  TextTheme get t => Theme.of(this).textTheme;
  bool get reducedMotion => MediaQuery.of(this).disableAnimations;
}
