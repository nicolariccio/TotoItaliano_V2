// ─────────────────────────────────────────────────────────────────────────────
//  Router di anteprima: stesse route/schermate dell'app reale (vedi
//  core/routing/app_router.dart), ma senza il redirect di autenticazione —
//  che dipenderebbe da Firebase, assente in questa modalità. Parte
//  direttamente su Home.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/routing/home_shell.dart';
import '../core/routing/route_paths.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/leaderboard/presentation/screens/leaderboard_screen.dart';
import '../features/leagues/presentation/screens/league_create_screen.dart';
import '../features/leagues/presentation/screens/league_detail_screen.dart';
import '../features/leagues/presentation/screens/league_join_screen.dart';
import '../features/leagues/presentation/screens/leagues_screen.dart';
import '../features/leagues/presentation/screens/tournament_create_screen.dart';
import '../features/leagues/presentation/screens/tournament_detail_screen.dart';
import '../features/profile/presentation/screens/prediction_history_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../features/profile/presentation/screens/settings_screen.dart';

final Provider<GoRouter> previewRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: RoutePaths.home,
    routes: [
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
                    initialTab: state.extra as String?,
                  ),
                  routes: [
                    GoRoute(
                      path: RoutePaths.tournamentCreate,
                      builder: (context, state) => TournamentCreateScreen(
                        leagueId: state.pathParameters['leagueId']!,
                      ),
                    ),
                    GoRoute(
                      path: RoutePaths.tournamentDetail,
                      builder: (context, state) => TournamentDetailScreen(
                        leagueId: state.pathParameters['leagueId']!,
                        tournamentId: state.pathParameters['tournamentId']!,
                      ),
                    ),
                  ],
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
