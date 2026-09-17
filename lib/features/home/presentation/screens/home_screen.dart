import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/toto_theme.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/fade_slide_in.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/toto_widgets.dart';
import '../../../../data/models/league.dart';
import '../../../../data/models/match.dart';
import '../../../../data/models/matchday.dart';
import '../../../../data/providers/football_data_providers.dart';
import '../../../auth/presentation/providers/current_user_provider.dart';
import '../../../leagues/presentation/providers/league_providers.dart';
import '../../../leagues/presentation/widgets/league_tile.dart';
import '../../../predictions/presentation/controllers/schedina_controller.dart';
import '../../../predictions/presentation/controllers/schedina_state.dart';

/// Home = punto d'ingresso sulle leghe dell'utente: si entra in una lega
/// per vederne la classifica e compilare la sua schedina (indipendente
/// dalle altre leghe). La hero card in cima mette in evidenza la giornata
/// corrente e la lega con più pronostici ancora da fare — vedi
/// [_HomeHero] — cosi' l'utente sa sempre da dove ripartire anche con
/// più leghe attive.
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
                      FadeSlideIn(child: _HomeHero(leagues: leagues)),
                      const SizedBox(height: TotoSpace.x3l),
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

/// Stato di compilazione della schedina di [league] per la giornata
/// corrente: quante delle partite rilevanti per questa lega (al netto di
/// quelle escluse dal proprietario) hanno già un pronostico completo.
class _LeagueProgress {
  const _LeagueProgress({
    required this.league,
    required this.matches,
    required this.picks,
    required this.completed,
  });

  final League league;
  final List<Match> matches;
  final Map<String, PickState> picks;
  final int completed;

  int get total => matches.length;
  int get incomplete => total - completed;
}

/// Hero card della giornata corrente: mette in evidenza la lega con più
/// pronostici mancanti (quella che ha più bisogno di attenzione ora). Se
/// nessuna lega ha ancora partite in programma per la giornata attiva, la
/// card non appare — niente hero vuota a fare da rumore visivo.
class _HomeHero extends ConsumerWidget {
  const _HomeHero({required this.leagues});

  final List<League> leagues;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchdayAsync = ref.watch(currentMatchdayProvider);
    final matchesAsync = ref.watch(currentMatchdayMatchesProvider);

    if (!matchdayAsync.hasValue || !matchesAsync.hasValue) {
      return const SizedBox.shrink();
    }
    final matchday = matchdayAsync.requireValue;
    final allMatches = matchesAsync.requireValue;
    if (allMatches.isEmpty) return const SizedBox.shrink();

    _LeagueProgress? spotlight;
    for (final league in leagues) {
      final excluded = ref
              .watch(leagueMatchdayConfigProvider(
                  (leagueId: league.id, matchdayId: matchday.id)))
              .valueOrNull
              ?.excludedMatchIds
              .toSet() ??
          const <String>{};
      final relevant = allMatches.where((m) => !excluded.contains(m.id)).toList();
      if (relevant.isEmpty) continue;

      final schedina = ref.watch(schedinaControllerProvider(league.id));
      final completed = relevant
          .where((m) => (schedina.picks[m.id] ?? const PickState()).isComplete)
          .length;

      final candidate = _LeagueProgress(
        league: league,
        matches: relevant,
        picks: schedina.picks,
        completed: completed,
      );
      if (spotlight == null || candidate.incomplete > spotlight.incomplete) {
        spotlight = candidate;
      }
    }
    if (spotlight == null) return const SizedBox.shrink();

    return _HomeHeroCard(matchday: matchday, progress: spotlight);
  }
}

class _HomeHeroCard extends StatelessWidget {
  const _HomeHeroCard({required this.matchday, required this.progress});

  final Matchday matchday;
  final _LeagueProgress progress;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final theme = Theme.of(context);
    final now = DateTime.now();
    final closesIn = matchday.predictionDeadline.difference(now);
    final isClosed = closesIn.isNegative;
    final isClosing = !isClosed && closesIn.inMinutes <= 120;

    final preview = progress.matches.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TotoCard(
          level: TotoCardLevel.elevated,
          radius: TotoRadius.xl,
          padding: const EdgeInsets.all(TotoSpace.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('GIORNATA ${matchday.number}',
                      style: theme.textTheme.labelSmall),
                  TotoBadge(
                    isClosed ? 'Chiusa' : (isClosing ? 'In chiusura' : 'Aperta'),
                    tone: isClosed
                        ? TotoBadgeTone.neutral
                        : (isClosing
                            ? TotoBadgeTone.warning
                            : TotoBadgeTone.brand),
                    icon: isClosed ? Icons.lock_rounded : null,
                  ),
                ],
              ),
              const SizedBox(height: TotoSpace.lg),
              if (!isClosed)
                TotoCountdown(deadline: matchday.predictionDeadline, size: 44)
              else
                Text('Pronostici chiusi', style: theme.textTheme.displaySmall),
              const SizedBox(height: TotoSpace.xl),
              Row(
                children: [
                  TotoProgressRing(
                    value: progress.total == 0
                        ? 0
                        : progress.completed / progress.total,
                  ),
                  const SizedBox(width: TotoSpace.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${progress.completed} di ${progress.total} compilate',
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: TotoSpace.xxs),
                        Text(
                          'nella lega ${progress.league.name}',
                          style: theme.textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (!isClosed && progress.incomplete > 0) ...[
                const SizedBox(height: TotoSpace.xl),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => context.push(
                      RoutePaths.leagueDetailPath(progress.league.id),
                      extra: 'schedina',
                    ),
                    child: Text('Completa le ultime ${progress.incomplete}'),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: TotoSpace.lg),
        for (final match in preview)
          Padding(
            padding: const EdgeInsets.only(bottom: TotoSpace.sm),
            child: _HeroMatchRow(
              match: match,
              pick: progress.picks[match.id],
              onTap: () => context.push(
                RoutePaths.leagueDetailPath(progress.league.id),
                extra: 'schedina',
              ),
            ),
          ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.transparent,
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(
                  horizontal: TotoSpace.sm, vertical: TotoSpace.xs),
              foregroundColor: c.brand,
            ),
            onPressed: () => context.push(
              RoutePaths.leagueDetailPath(progress.league.id),
              extra: 'schedina',
            ),
            child: const Text('Vedi tutte'),
          ),
        ),
        const SizedBox(height: TotoSpace.sm),
        _LeaguePositionRow(league: progress.league),
      ],
    );
  }
}

/// "4° nella Lega Amici del Bar" — riga singola posizione lega in fondo
/// alla hero, per la lega messa in evidenza. Nessuna freccia di delta: il
/// backend non persiste ancora la classifica della giornata precedente
/// (vedi TotoRankDelta, usato invece in Classifica dove il dato è
/// opzionale), quindi non la inventiamo.
class _LeaguePositionRow extends ConsumerWidget {
  const _LeaguePositionRow({required this.league});

  final League league;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final c = context.c;
    final currentUserId = ref.watch(currentUserProvider).valueOrNull?.id;
    final membersAsync = ref.watch(leagueMembersProvider(league.id));
    final members = membersAsync.valueOrNull;
    final position = (members == null || currentUserId == null)
        ? null
        : members.indexWhere((m) => m.userId == currentUserId) + 1;

    if (position == null || position <= 0) return const SizedBox.shrink();

    return PressScale(
      onTap: () => context.push(RoutePaths.leagueDetailPath(league.id)),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: c.brandContainer,
            child: Icon(Icons.shield_rounded, size: 16, color: c.brand),
          ),
          const SizedBox(width: TotoSpace.md),
          Expanded(
            child: Text('$position° nella ${league.name}',
                style: theme.textTheme.bodyLarge,
                overflow: TextOverflow.ellipsis),
          ),
          Icon(Icons.chevron_right_rounded, color: c.textTertiary),
        ],
      ),
    );
  }
}

class _HeroMatchRow extends StatelessWidget {
  const _HeroMatchRow({required this.match, required this.pick, this.onTap});

  final Match match;
  final PickState? pick;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final done = pick?.isComplete ?? false;

    return TotoCard(
      radius: TotoRadius.md,
      padding: const EdgeInsets.symmetric(
          horizontal: TotoSpace.lg, vertical: TotoSpace.sm),
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${match.homeTeam.shortName} - ${match.awayTeam.shortName}',
                  style: theme.textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${DateFormatter.matchKickoffCompact(match.kickoff)} · ${match.homeTeam.stadium}',
                  style: theme.textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: TotoSpace.sm),
          if (done)
              const TotoBadge('Scelto',
                  tone: TotoBadgeTone.brand,
                  icon: Icons.check_rounded,
                  uppercase: false)
            else
              const TotoDashedChip('Scegli'),
        ],
      ),
    );
  }
}
