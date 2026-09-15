import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/toto_theme.dart';
import '../../../../core/widgets/state_views.dart';
import '../providers/league_providers.dart';
import '../widgets/league_tile.dart';

class LeaguesScreen extends ConsumerWidget {
  const LeaguesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaguesAsync = ref.watch(myLeaguesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Leghe')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                TotoSpace.lg, TotoSpace.md, TotoSpace.lg, TotoSpace.sm),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => context.push(RoutePaths.leagueCreate),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Crea lega'),
                  ),
                ),
                const SizedBox(width: TotoSpace.md),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push(RoutePaths.leagueJoin),
                    icon: const Icon(Icons.qr_code_rounded),
                    label: const Text('Entra in lega'),
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
                  return const AppEmptyView(
                    title: 'Nessuna lega ancora',
                    subtitle:
                        'Crea una lega privata o entra con un invite code.',
                    icon: Icons.groups_outlined,
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(TotoSpace.lg, TotoSpace.sm,
                      TotoSpace.lg, TotoSpace.navClearance),
                  itemCount: leagues.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: TotoSpace.md),
                  itemBuilder: (context, index) =>
                      LeagueTile(league: leagues[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
