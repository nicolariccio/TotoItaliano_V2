import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/podium_leaderboard.dart';
import '../../../../core/widgets/ranked_entry.dart';
import '../../../../core/widgets/state_views.dart';
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
        data: (users) => PodiumLeaderboard(
          entries: [
            for (final user in users)
              RankedEntry(id: user.id, username: user.username, photoUrl: user.photoUrl, points: user.totalPoints),
          ],
        ),
      ),
    );
  }
}
