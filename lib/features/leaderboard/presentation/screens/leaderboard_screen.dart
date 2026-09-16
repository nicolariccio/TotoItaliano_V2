import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/toto_theme.dart';
import '../../../../core/widgets/podium_leaderboard.dart';
import '../../../../core/widgets/ranked_entry.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/toto_widgets.dart';
import '../../../auth/presentation/providers/current_user_provider.dart';
import '../../../leagues/presentation/providers/league_providers.dart';
import '../providers/leaderboard_providers.dart';

enum _Scope { generale, lega }

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  _Scope _scope = _Scope.generale;
  String? _selectedLeagueId;

  @override
  Widget build(BuildContext context) {
    final leaguesAsync = ref.watch(myLeaguesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Classifica')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                TotoSpace.lg, TotoSpace.sm, TotoSpace.lg, TotoSpace.sm),
            child: TotoSegmented<_Scope>(
              values: const [_Scope.generale, _Scope.lega],
              labels: (s) => s == _Scope.generale ? 'Generale' : 'Lega',
              selected: _scope,
              onChanged: (s) => setState(() => _scope = s),
            ),
          ),
          if (_scope == _Scope.lega)
            SizedBox(
              height: 40,
              child: leaguesAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (error, stackTrace) => const SizedBox.shrink(),
                data: (leagues) {
                  if (leagues.isEmpty) return const SizedBox.shrink();
                  _selectedLeagueId ??= leagues.first.id;
                  return ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: TotoSpace.lg),
                    itemCount: leagues.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: TotoSpace.sm),
                    itemBuilder: (context, index) {
                      final league = leagues[index];
                      final selected = league.id == _selectedLeagueId;
                      return _LeagueChip(
                        label: league.name,
                        selected: selected,
                        onTap: () => setState(() => _selectedLeagueId = league.id),
                      );
                    },
                  );
                },
              ),
            ),
          const SizedBox(height: TotoSpace.sm),
          Expanded(
            child: _scope == _Scope.generale
                ? const _GeneraleBody()
                : (_selectedLeagueId == null
                    ? const AppLoadingView()
                    : _LegaBody(leagueId: _selectedLeagueId!)),
          ),
        ],
      ),
    );
  }
}

class _LeagueChip extends StatelessWidget {
  const _LeagueChip(
      {required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final theme = Theme.of(context);
    return PressScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: TotoMotion.fast,
        curve: TotoMotion.standard,
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: TotoSpace.lg),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? c.brandFill : c.surface2,
          borderRadius: BorderRadius.circular(TotoRadius.full),
          border: Border.all(color: selected ? c.brandFill : c.borderSubtle),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelLarge?.copyWith(
            color: selected ? c.textOnPrimary : c.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _GeneraleBody extends ConsumerWidget {
  const _GeneraleBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardAsync = ref.watch(leaderboardProvider);
    final currentUserId = ref.watch(currentUserProvider).valueOrNull?.id;

    return leaderboardAsync.when(
      loading: () => const AppLoadingView(),
      error: (error, stackTrace) => AppErrorView(
        message: 'Non è stato possibile caricare la classifica.',
        onRetry: () => ref.invalidate(leaderboardProvider),
      ),
      data: (users) => PodiumLeaderboard(
        currentUserId: currentUserId,
        entries: [
          for (final user in users)
            RankedEntry(
                id: user.id,
                username: user.username,
                photoUrl: user.photoUrl,
                points: user.totalPoints),
        ],
      ),
    );
  }
}

class _LegaBody extends ConsumerWidget {
  const _LegaBody({required this.leagueId});

  final String leagueId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(leagueMembersProvider(leagueId));
    final currentUserId = ref.watch(currentUserProvider).valueOrNull?.id;

    return membersAsync.when(
      loading: () => const AppLoadingView(),
      error: (error, stackTrace) => AppErrorView(
        message: 'Non è stato possibile caricare la classifica di lega.',
        onRetry: () => ref.invalidate(leagueMembersProvider(leagueId)),
      ),
      data: (members) => PodiumLeaderboard(
        emptyTitle: 'Nessun membro ancora',
        currentUserId: currentUserId,
        entries: [
          for (final member in members)
            RankedEntry(
              id: member.userId,
              username: member.username,
              photoUrl: member.photoUrl,
              points: member.totalPoints,
              last5: member.last5,
              exactCount: member.exactCount,
            ),
        ],
      ),
    );
  }
}
