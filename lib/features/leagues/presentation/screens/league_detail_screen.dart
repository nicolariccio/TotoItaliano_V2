import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/widgets/podium_leaderboard.dart';
import '../../../../core/widgets/ranked_entry.dart';
import '../../../../core/widgets/state_views.dart';
import '../providers/league_providers.dart';

class LeagueDetailScreen extends ConsumerWidget {
  const LeagueDetailScreen({super.key, required this.leagueId});

  final String leagueId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leagueAsync = ref.watch(leagueByIdProvider(leagueId));

    return Scaffold(
      appBar: AppBar(title: Text(leagueAsync.value?.name ?? 'Lega')),
      body: leagueAsync.when(
        loading: () => const AppLoadingView(),
        error: (error, stackTrace) => AppErrorView(
          message: 'Non è stato possibile caricare la lega.',
          onRetry: () => ref.invalidate(leagueByIdProvider(leagueId)),
        ),
        data: (league) {
          if (league == null) {
            return const AppErrorView(message: 'Lega non trovata.');
          }

          final membersAsync = ref.watch(leagueMembersProvider(leagueId));

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (league.description != null && league.description!.isNotEmpty) ...[
                      Text(league.description!, style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 12),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.darkSurfaceElevated,
                        borderRadius: AppRadii.mdRadius,
                        border: Border.all(color: AppColors.darkBorder),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Codice invito', style: Theme.of(context).textTheme.bodySmall),
                                Text(
                                  league.inviteCode,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(color: AppColors.azzurro, letterSpacing: 1),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy_rounded),
                            tooltip: 'Copia codice',
                            onPressed: () async {
                              await Clipboard.setData(ClipboardData(text: league.inviteCode));
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Codice copiato negli appunti.')),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('CLASSIFICA DI LEGA', style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
              ),
              Expanded(
                child: membersAsync.when(
                  loading: () => const AppLoadingView(),
                  error: (error, stackTrace) => AppErrorView(
                    message: 'Non è stato possibile caricare i membri.',
                    onRetry: () => ref.invalidate(leagueMembersProvider(leagueId)),
                  ),
                  data: (members) => PodiumLeaderboard(
                    emptyTitle: 'Nessun membro ancora',
                    entries: [
                      for (final member in members)
                        RankedEntry(
                          id: member.userId,
                          username: member.username,
                          photoUrl: member.photoUrl,
                          points: member.totalPoints,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
