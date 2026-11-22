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
                  TotoSpace.xl, TotoSpace.lg, TotoSpace.lg, TotoSpace.md),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: c.brandContainer,
                      borderRadius: BorderRadius.circular(TotoRadius.sm),
                    ),
                    child: Icon(Icons.sports_soccer_rounded,
                        color: c.brand, size: 22),
                  ),
                  const SizedBox(width: TotoSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userAsync.value?.username.isNotEmpty == true
                              ? 'Ciao, ${userAsync.value!.username}'
                              : AppConstants.appName,
                          style: theme.textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text('Pronto per la giornata?',
                            style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                  Semantics(
                    button: true,
                    label: 'Profilo',
                    child: PressScale(
                      onTap: () => context.go(RoutePaths.profile),
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: Center(
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: c.brandFill,
                            child: Text(
                              userAsync.value?.username.isNotEmpty == true
                                  ? userAsync.value!.username[0].toUpperCase()
                                  : '?',
                              style: theme.textTheme.labelLarge
                                  ?.copyWith(color: c.textOnPrimary),
                            ),
                          ),
                        ),
                      ),
                    ),
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
                      action: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 320),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            FilledButton(
                              onPressed: () =>
                                  context.push(RoutePaths.leagueCreate),
                              child: const Text('Crea lega'),
                            ),
                            const SizedBox(height: TotoSpace.md),
                            OutlinedButton(
                              onPressed: () =>
                                  context.push(RoutePaths.leagueJoin),
                              child: const Text('Entra in lega'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(TotoSpace.lg,
                        TotoSpace.sm, TotoSpace.lg, TotoSpace.navClearance),
                    children: [
                      TotoSectionLabel(
                        'Le tue leghe',
                        trailing: TextButton(
                          onPressed: () => context.push(RoutePaths.leagueJoin),
                          child: const Text('Entra con codice'),
                        ),
                      ),
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
