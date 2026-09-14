import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_providers.dart';
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
import '../../features/predictions/presentation/screens/match_detail_screen.dart';
import '../../features/predictions/presentation/screens/predictions_screen.dart';
import '../../features/profile/presentation/screens/prediction_history_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/settings_screen.dart';
import 'home_shell.dart';
import 'route_paths.dart';

/// Trasforma uno [Stream] in un [Listenable] ascoltabile da GoRouter, cosi'
/// il router puo' ri-valutare `redirect` quando cambia lo stato di auth.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

const List<String> _publicAuthRoutes = [
  RoutePaths.login,
  RoutePaths.register,
  RoutePaths.forgotPassword,
];

final Provider<GoRouter> appRouterProvider = Provider<GoRouter>((ref) {
  final refreshStream = GoRouterRefreshStream(
    ref.watch(firebaseAuthProvider).authStateChanges(),
  );
  ref.onDispose(refreshStream.dispose);

  return GoRouter(
    initialLocation: RoutePaths.splash,
    refreshListenable: refreshStream,
    redirect: (context, state) {
      final authState = ref.read(authStateChangesProvider);
      final bool authLoading = authState.isLoading;
      final bool isAuthenticated = authState.valueOrNull != null;
      final bool onboardingComplete = ref.read(onboardingCompleteProvider);

      final String location = state.matchedLocation;

      if (location == RoutePaths.splash) {
        if (authLoading) return null;
        if (!onboardingComplete) return RoutePaths.onboarding;
        return isAuthenticated ? RoutePaths.home : RoutePaths.login;
      }

      if (authLoading) return null;

      if (!onboardingComplete) {
        return location == RoutePaths.onboarding ? null : RoutePaths.onboarding;
      }

      final bool onPublicAuthRoute = _publicAuthRoutes.contains(location);

      if (!isAuthenticated && !onPublicAuthRoute) return RoutePaths.login;
      if (isAuthenticated && (onPublicAuthRoute || location == RoutePaths.onboarding)) {
        return RoutePaths.home;
      }
      return null;
    },
    routes: [
      GoRoute(path: RoutePaths.splash, builder: (context, state) => const SplashScreen()),
      GoRoute(path: RoutePaths.onboarding, builder: (context, state) => const OnboardingScreen()),
      GoRoute(path: RoutePaths.login, builder: (context, state) => const LoginScreen()),
      GoRoute(path: RoutePaths.register, builder: (context, state) => const RegisterScreen()),
      GoRoute(
        path: RoutePaths.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => HomeShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: RoutePaths.home, builder: (context, state) => const HomeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: RoutePaths.predictions,
              builder: (context, state) => const PredictionsScreen(),
              routes: [
                GoRoute(
                  path: RoutePaths.matchDetail,
                  builder: (context, state) => MatchDetailScreen(
                    matchId: state.pathParameters['matchId']!,
                  ),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: RoutePaths.leaderboard, builder: (context, state) => const LeaderboardScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: RoutePaths.leagues,
              builder: (context, state) => const LeaguesScreen(),
              routes: [
                GoRoute(path: 'create', builder: (context, state) => const LeagueCreateScreen()),
                GoRoute(path: 'join', builder: (context, state) => const LeagueJoinScreen()),
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
                GoRoute(path: 'settings', builder: (context, state) => const SettingsScreen()),
                GoRoute(path: 'history', builder: (context, state) => const PredictionHistoryScreen()),
              ],
            ),
          ]),
        ],
      ),
    ],
  );
});
