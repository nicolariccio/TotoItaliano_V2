import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/countdown_timer.dart';
import '../../../../core/widgets/fade_slide_in.dart';
import '../../../../core/widgets/gradient_card.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../data/models/match.dart';
import '../../../../data/providers/football_data_providers.dart';
import '../../../auth/presentation/providers/current_user_provider.dart';
import '../widgets/match_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final competitionAsync = ref.watch(activeCompetitionProvider);
    final matchdayAsync = ref.watch(currentMatchdayProvider);
    final matchesAsync = ref.watch(currentMatchdayMatchesProvider);

    final bool isLoading = competitionAsync.isLoading ||
        matchdayAsync.isLoading ||
        matchesAsync.isLoading;
    final Object? error =
        competitionAsync.error ?? matchdayAsync.error ?? matchesAsync.error;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(competitionsProvider);
            ref.invalidate(matchdaysProvider);
            ref.invalidate(currentMatchdayMatchesProvider);
            await ref.read(currentMatchdayMatchesProvider.future);
          },
          child: isLoading
              ? const AppLoadingView()
              : error != null
                  ? AppErrorView(
                      message:
                          'Non è stato possibile caricare i dati delle partite.',
                      onRetry: () {
                        ref.invalidate(competitionsProvider);
                        ref.invalidate(matchdaysProvider);
                        ref.invalidate(currentMatchdayMatchesProvider);
                      },
                    )
                  : _HomeContent(
                      competitionLabel:
                          '${competitionAsync.value!.name} ${competitionAsync.value!.season}',
                      matchdayNumber: matchdayAsync.value!.number,
                      predictionDeadline:
                          matchdayAsync.value!.predictionDeadline,
                      matches: matchesAsync.value!,
                    ),
        ),
      ),
    );
  }
}

class _HomeContent extends ConsumerWidget {
  const _HomeContent({
    required this.competitionLabel,
    required this.matchdayNumber,
    required this.predictionDeadline,
    required this.matches,
  });

  final String competitionLabel;
  final int matchdayNumber;
  final DateTime predictionDeadline;
  final List<Match> matches;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final userAsync = ref.watch(currentUserProvider);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.sports_soccer_rounded,
                    color: AppColors.azzurro, size: 28),
                const SizedBox(width: 8),
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
                GestureDetector(
                  onTap: () => context.go(RoutePaths.profile),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.azzurro,
                    child: Text(
                      userAsync.value?.username.isNotEmpty == true
                          ? userAsync.value!.username[0].toUpperCase()
                          : '?',
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        FadeSlideIn(
          child: GradientCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  competitionLabel.toUpperCase(),
                  style: theme.textTheme.labelLarge
                      ?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 4),
                Text(
                  'GIORNATA $matchdayNumber',
                  style: theme.textTheme.displayMedium
                      ?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 16),
                Text(
                  'Chiusura pronostici tra',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: Colors.white70),
                ),
                CountdownTimer(
                  target: predictionDeadline,
                  style: theme.textTheme.headlineMedium
                      ?.copyWith(color: Colors.white),
                  expiredLabel: 'Pronostici chiusi',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text('PROSSIME PARTITE', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        if (matches.isEmpty)
          const AppEmptyView(
            title: 'Nessuna partita in programma',
            subtitle: 'Torna più tardi per la prossima giornata.',
          )
        else
          ...matches.asMap().entries.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: FadeSlideIn(
                  delay: Duration(milliseconds: 60 * entry.key.clamp(0, 8)),
                  child: MatchCard(match: entry.value),
                ),
              )),
      ],
    );
  }
}
