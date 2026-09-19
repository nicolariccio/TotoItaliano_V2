/// Costanti globali dell'applicazione.
class AppConstants {
  const AppConstants._();

  static const String appName = 'TotoItaliano';
  static const String appTagline = 'Il calcio italiano, la tua sfida.';

  static const String prefsOnboardingComplete = 'onboarding_complete';
  static const String prefsThemeMode = 'theme_mode';

  /// Punti di default del motore di scoring, usati solo come fallback
  /// se `scoringConfigs/{competitionId}` non è ancora stato creato.
  /// La configurazione reale vive sempre lato backend.
  static const int defaultExactScorePoints = 10;
  static const int defaultResultPoints = 5;
  static const int defaultGoalNoGoalPoints = 3;
  static const int defaultOverUnderPoints = 3;

  static const int referralDiscountEuro = 5;
  static const int defaultEntryFeeEuro = 50;
}
