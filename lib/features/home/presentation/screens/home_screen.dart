import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/toto_theme.dart';
import '../../../../core/widgets/fade_slide_in.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/toto_widgets.dart';
import '../../../auth/presentation/providers/current_user_provider.dart';
import '../../../leagues/presentation/providers/league_providers.dart';
import '../../../leagues/presentation/widgets/league_tile.dart';

/// Home = punto d'ingresso sulle leghe dell'utente: si entra in una lega
/// per vederne la classifica e compilare la sua schedina (indipendente
/// dalle altre leghe). Non mostra più un feed di partite globale — quello
/// vive dentro ogni lega, dove ha un contesto (di quale lega è quella
/// schedina).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaguesAsync = ref.watch(myLeaguesProvider);
    final userAsync = ref.watch(currentUserProvider);
    final theme = Theme.of(context);
    final c = context.c;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  TotoSpace.lg, TotoSpace.lg, TotoSpace.lg, TotoSpace.sm),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.sports_soccer_rounded, color: c.brand, size: 26),
                      const SizedBox(width: TotoSpace.sm),
                      Text(AppConstants.appName, style: theme.textTheme.titleLarge),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined),
                        tooltip: 'Notifiche',
                        onPressed: () {},
                      ),
                      PressScale(
                        onTap: () => context.go(RoutePaths.profile),
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: c.brandFill,
                          child: Text(
                            userAsync.value?.username.isNotEmpty == true
                                ? userAsync.value!.username[0].toUpperCase()
                                : '?',
                            style: theme.textTheme.labelSmall
                                ?.copyWith(color: c.textOnPrimary),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: leaguesAsync.when(
                loading: () => const AppLoadingView(),
                error: (error, stackTrace) => AppErrorView(
                  message: 'Non è stato possibile caricare le tue leghe.',
                  onRetry: () => ref.invalidate(myLeaguesProvider),
                ),
                data: (leagues) {
                  if (leagues.isEmpty) {
                    return AppEmptyView(
                      icon: Icons.groups_outlined,
                      title: 'Nessuna lega ancora',
                      subtitle:
                          'Crea una lega privata o entra con un invite code per iniziare a pronosticare con i tuoi amici.',
                      action: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FilledButton(
                            onPressed: () =>
                                context.push(RoutePaths.leagueCreate),
                            child: const Text('Crea lega'),
                          ),
                          const SizedBox(width: TotoSpace.md),
                          OutlinedButton(
                            onPressed: () => context.push(RoutePaths.leagueJoin),
                            child: const Text('Entra in lega'),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(TotoSpace.lg,
                        TotoSpace.sm, TotoSpace.lg, TotoSpace.navClearance),
                    children: [
                      Text('LE TUE LEGHE', style: theme.textTheme.labelSmall),
                      const SizedBox(height: TotoSpace.md),
                      for (var i = 0; i < leagues.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: TotoSpace.md),
                          child: FadeSlideIn(
                            delay: Duration(milliseconds: 60 * i.clamp(0, 8)),
                            child: LeagueTile(league: leagues[i]),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
