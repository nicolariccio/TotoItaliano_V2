import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/toto_theme.dart';
import '../../../../core/widgets/fade_slide_in.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/toto_widgets.dart';
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
    final c = context.c;
    final userAsync = ref.watch(currentUserProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        TotoSpace.lg,
        TotoSpace.lg,
        TotoSpace.lg,
        TotoSpace.navClearance,
      ),
      children: [
        Row(
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
        const SizedBox(height: TotoSpace.xl),
        FadeSlideIn(
          child: TotoCard(
            level: TotoCardLevel.elevated,
            radius: TotoRadius.xl,
            padding: const EdgeInsets.all(TotoSpace.xxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  competitionLabel.toUpperCase(),
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: c.textSecondary),
                ),
                const SizedBox(height: TotoSpace.xs),
                Text(
                  'Giornata $matchdayNumber',
                  style: theme.textTheme.displaySmall,
                ),
                const SizedBox(height: TotoSpace.lg),
                Text(
                  'Chiusura pronostici tra',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: TotoSpace.xxs),
                TotoCountdown(deadline: predictionDeadline),
              ],
            ),
          ),
        ),
        const SizedBox(height: TotoSpace.x3l),
        Text('PROSSIME PARTITE', style: theme.textTheme.labelSmall),
        const SizedBox(height: TotoSpace.md),
        if (matches.isEmpty)
          const AppEmptyView(
            title: 'Nessuna partita in programma',
            subtitle: 'Torna più tardi per la prossima giornata.',
          )
        else
          ...matches.asMap().entries.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: TotoSpace.md),
                child: FadeSlideIn(
                  delay: Duration(milliseconds: 60 * entry.key.clamp(0, 8)),
                  child: MatchCard(match: entry.value),
                ),
              )),
      ],
    );
  }
}
