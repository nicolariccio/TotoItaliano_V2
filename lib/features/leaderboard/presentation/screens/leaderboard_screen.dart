import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../providers/leaderboard_providers.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardAsync = ref.watch(leaderboardProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Classifica')),
      body: leaderboardAsync.when(
        loading: () => const AppLoadingView(),
        error: (error, stackTrace) => AppErrorView(
          message: 'Non è stato possibile caricare la classifica.',
          onRetry: () => ref.invalidate(leaderboardProvider),
        ),
        data: (users) {
          if (users.isEmpty) {
            return const AppEmptyView(
              title: 'Classifica non ancora disponibile',
              subtitle: 'Torna qui dopo le prime giornate giocate.',
            );
          }

          final podium = users.take(3).toList();
          final rest = users.length > 3 ? users.sublist(3) : const <AppUser>[];

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (podium.isNotEmpty) _Podium(users: podium),
              const SizedBox(height: 24),
              for (var i = 0; i < rest.length; i++)
                _LeaderboardRow(position: i + 4, user: rest[i]),
            ],
          );
        },
      ),
    );
  }
}

class _Podium extends StatelessWidget {
  const _Podium({required this.users});

  final List<AppUser> users;

  @override
  Widget build(BuildContext context) {
    AppUser? at(int index) => index < users.length ? users[index] : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: _PodiumSlot(user: at(1), position: 2, height: 84, color: AppColors.podiumSilver)),
        const SizedBox(width: 8),
        Expanded(child: _PodiumSlot(user: at(0), position: 1, height: 110, color: AppColors.podiumGold)),
        const SizedBox(width: 8),
        Expanded(child: _PodiumSlot(user: at(2), position: 3, height: 64, color: AppColors.podiumBronze)),
      ],
    );
  }
}

class _PodiumSlot extends StatelessWidget {
  const _PodiumSlot({required this.user, required this.position, required this.height, required this.color});

  final AppUser? user;
  final int position;
  final double height;
  final Color color;

  static const List<String> _medals = ['🥇', '🥈', '🥉'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (user == null) return const SizedBox.shrink();

    return Column(
      children: [
        Text(_medals[position - 1], style: const TextStyle(fontSize: 28)),
        const SizedBox(height: 4),
        CircleAvatar(
          radius: 22,
          backgroundColor: color,
          backgroundImage: user!.photoUrl != null ? NetworkImage(user!.photoUrl!) : null,
          child: user!.photoUrl == null
              ? Text(
                  user!.username.isNotEmpty ? user!.username[0].toUpperCase() : '?',
                  style: theme.textTheme.titleMedium?.copyWith(color: Colors.black87),
                )
              : null,
        ),
        const SizedBox(height: 6),
        Text(
          '@${user!.username}',
          style: theme.textTheme.labelMedium,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        Text('${user!.totalPoints} pt', style: theme.textTheme.labelSmall),
        const SizedBox(height: 8),
        Container(
          height: height,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.18),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            border: Border(top: BorderSide(color: color, width: 3)),
          ),
        ),
      ],
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({required this.position, required this.user});

  final int position;
  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              child: Text('$position', style: theme.textTheme.labelLarge, textAlign: TextAlign.center),
            ),
            const SizedBox(width: 12),
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.azzurro,
              backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
              child: user.photoUrl == null
                  ? Text(
                      user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
                      style: theme.textTheme.labelMedium?.copyWith(color: Colors.white),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text('@${user.username}', style: theme.textTheme.labelLarge, overflow: TextOverflow.ellipsis),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.darkSurfaceElevated,
                borderRadius: AppRadii.pillRadius,
              ),
              child: Text('${user.totalPoints} pt', style: theme.textTheme.labelMedium),
            ),
          ],
        ),
      ),
    );
  }
}
