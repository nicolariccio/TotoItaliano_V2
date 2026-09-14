/// Path centralizzati delle route. Nessuno schermo deve navigare con
/// stringhe letterali: usa sempre queste costanti (o i metodi helper per
/// le route parametriche).
class RoutePaths {
  const RoutePaths._();

  static const String splash = '/splash';
  static const String onboarding = '/onboarding';

  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  static const String home = '/home';
  static const String predictions = '/predictions';
  static const String leaderboard = '/leaderboard';
  static const String leagues = '/leagues';
  static const String profile = '/profile';

  static const String leagueDetail = 'league/:leagueId';
  static String leagueDetailPath(String leagueId) => '/leagues/league/$leagueId';

  static const String leagueCreate = '/leagues/create';
  static const String leagueJoin = '/leagues/join';

  static const String settings = '/profile/settings';
  static const String predictionHistory = '/profile/history';
}
