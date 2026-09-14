import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/auth/presentation/providers/current_user_provider.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/leaderboard/presentation/screens/leaderboard_screen.dart';
import '../../features/leagues/presentation/screens/league_create_screen.dart';
import '../../features/leagues/presentation/screens/league_detail_screen.dart';
import '../../features/leagues/presentation/screens/league_join_screen.dart';
import '../../features/leagues/presentation/screens/leagues_screen.dart';
import '../../features/onboarding/presentation/providers/onboarding_provider.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/onboarding/presentation/screens/splash_screen.dart';
import '../../features/predictions/presentation/screens/predictions_screen.dart';
import '../../features/profile/presentation/screens/prediction_history_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/settings_screen.dart';
import 'home_shell.dart';
import 'route_paths.dart';

/// [Listenable] usato come `refreshListenable` di GoRouter.
///
/// Deliberatamente NON si iscrive direttamente allo stream Firebase: farlo
/// creerebbe una seconda subscription indipendente da quella interna di
/// [authStateChangesProvider], con un ordine di consegna degli eventi non
/// garantito. `redirect` potrebbe rieseguire leggendo ancora lo stato
/// precedente (stale) e il router resterebbe bloccato in loop sulla splash.
/// Notificando da `ref.listen` siamo certi che il provider abbia già
/// aggiornato il proprio stato quando `redirect` lo rilegge.
class _RouterRefreshNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}

const List<String> _publicAuthRoutes = [
  RoutePaths.login,
  RoutePaths.register,
  RoutePaths.forgotPassword,
];

final Provider<GoRouter> appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _RouterRefreshNotifier();
  ref.listen(
      authStateChangesProvider, (previous, next) => refreshNotifier.notify());
  ref.listen(currentUserProvider, (previous, next) => refreshNotifier.notify());
  ref.listen(
      onboardingCompleteProvider, (previous, next) => refreshNotifier.notify());
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    initialLocation: RoutePaths.splash,
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authState = ref.read(authStateChangesProvider);
      final bool onboardingComplete = ref.read(onboardingCompleteProvider);
      final String location = state.matchedLocation;

      // Bootstrap iniziale di Firebase Auth: non sappiamo ancora nulla.
      if (authState.isLoading) return null;

      final bool hasFirebaseSession = authState.valueOrNull != null;

      // Una sessione Firebase Auth SENZA profilo Firestore (registrazione
      // ancora in corso, o account "orfano" in fase di rollback dopo un
      // errore) non conta come autenticato ai fini della navigazione:
      // altrimenti il router manderebbe l'utente in Home a metà flusso,
      // interrompendo login/register mentre l'operazione è ancora in corso.
      bool isAuthenticated = false;
      if (hasFirebaseSession) {
        final profileState = ref.read(currentUserProvider);
        if (profileState.isLoading) return null;
        isAuthenticated = profileState.valueOrNull != null;
      }

      if (location == RoutePaths.splash) {
        if (!onboardingComplete) return RoutePaths.onboarding;
        return isAuthenticated ? RoutePaths.home : RoutePaths.login;
      }

      if (!onboardingComplete) {
        return location == RoutePaths.onboarding ? null : RoutePaths.onboarding;
      }

      final bool onPublicAuthRoute = _publicAuthRoutes.contains(location);

      if (!isAuthenticated && !onPublicAuthRoute) return RoutePaths.login;
      if (isAuthenticated &&
          (onPublicAuthRoute || location == RoutePaths.onboarding)) {
        return RoutePaths.home;
      }
      return null;
    },
    routes: [
      GoRoute(
          path: RoutePaths.splash,
          builder: (context, state) => const SplashScreen()),
      GoRoute(
          path: RoutePaths.onboarding,
          builder: (context, state) => const OnboardingScreen()),
      GoRoute(
          path: RoutePaths.login,
          builder: (context, state) => const LoginScreen()),
      GoRoute(
          path: RoutePaths.register,
          builder: (context, state) => const RegisterScreen()),
      GoRoute(
        path: RoutePaths.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            HomeShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
                path: RoutePaths.home,
                builder: (context, state) => const HomeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: RoutePaths.predictions,
                builder: (context, state) => const PredictionsScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: RoutePaths.leaderboard,
                builder: (context, state) => const LeaderboardScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: RoutePaths.leagues,
              builder: (context, state) => const LeaguesScreen(),
              routes: [
                GoRoute(
                    path: 'create',
                    builder: (context, state) => const LeagueCreateScreen()),
                GoRoute(
                    path: 'join',
                    builder: (context, state) => const LeagueJoinScreen()),
                GoRoute(
                  path: RoutePaths.leagueDetail,
                  builder: (context, state) => LeagueDetailScreen(
                    leagueId: state.pathParameters['leagueId']!,
                  ),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: RoutePaths.profile,
              builder: (context, state) => const ProfileScreen(),
              routes: [
                GoRoute(
                    path: 'settings',
                    builder: (context, state) => const SettingsScreen()),
                GoRoute(
                    path: 'history',
                    builder: (context, state) =>
                        const PredictionHistoryScreen()),
              ],
            ),
          ]),
        ],
      ),
    ],
  );
});
