import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/pill_badge.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../data/models/league.dart';
import '../providers/league_providers.dart';

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
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => context.push(RoutePaths.leagueCreate),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Crea lega'),
                  ),
                ),
                const SizedBox(width: 12),
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
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  itemCount: leagues.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) =>
                      _LeagueTile(league: leagues[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LeagueTile extends StatelessWidget {
  const _LeagueTile({required this.league});

  final League league;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.push(RoutePaths.leagueDetailPath(league.id)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.azzurro.withValues(alpha: 0.16),
                child:
                    const Icon(Icons.shield_rounded, color: AppColors.azzurro),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(league.name, style: theme.textTheme.labelLarge),
                    const SizedBox(height: 4),
                    Text('${league.memberCount} membri',
                        style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              PillBadge(
                  label: league.inviteCode,
                  color: AppColors.darkSurfaceElevated,
                  onColor: AppColors.azzurro),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
