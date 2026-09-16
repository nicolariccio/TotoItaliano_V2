import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/toto_theme.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/toto_widgets.dart';
import '../../../../data/models/league.dart';
import '../../../../data/providers/football_data_providers.dart';
import '../../../auth/presentation/providers/current_user_provider.dart';
import '../../../predictions/presentation/controllers/schedina_controller.dart';
import '../../../predictions/presentation/controllers/schedina_state.dart';
import '../providers/league_providers.dart';

/// Card lega per la schermata "Leghe": nome, stato di compilazione della
/// giornata corrente, membri/chiusura e la posizione dell'utente in
/// questa lega. Più ricca della compatta [LeagueTile] usata in Home,
/// dove lo spazio è condiviso con la hero card.
class LeagueStatusCard extends ConsumerWidget {
  const LeagueStatusCard({super.key, required this.league});

  final League league;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final c = context.c;
    final currentUserId = ref.watch(currentUserProvider).valueOrNull?.id;

    final matchdayAsync = ref.watch(currentMatchdayProvider);
    final matchesAsync = ref.watch(currentMatchdayMatchesProvider);
    final membersAsync = ref.watch(leagueMembersProvider(league.id));

    int? incomplete;
    int? total;
    String? deadlineLabel;
    if (matchdayAsync.hasValue && matchesAsync.hasValue) {
      final matchday = matchdayAsync.requireValue;
      final excluded = ref
              .watch(leagueMatchdayConfigProvider(
                  (leagueId: league.id, matchdayId: matchday.id)))
              .valueOrNull
              ?.excludedMatchIds
              .toSet() ??
          const <String>{};
      final relevant =
          matchesAsync.requireValue.where((m) => !excluded.contains(m.id)).toList();
      total = relevant.length;
      if (total > 0) {
        final schedina = ref.watch(schedinaControllerProvider(league.id));
        final completed = relevant
            .where((m) => (schedina.picks[m.id] ?? const PickState()).isComplete)
            .length;
        incomplete = total - completed;
        deadlineLabel = DateFormatter.hm(matchday.predictionDeadline);
      }
    }

    int? position;
    int memberCount = league.memberCount;
    if (membersAsync.hasValue) {
      final members = membersAsync.requireValue;
      memberCount = members.length;
      if (currentUserId != null) {
        final idx = members.indexWhere((m) => m.userId == currentUserId);
        if (idx >= 0) position = idx + 1;
      }
    }

    return TotoCard(
      radius: TotoRadius.lg,
      onTap: () => context.push(RoutePaths.leagueDetailPath(league.id)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(league.name,
                          style: theme.textTheme.titleLarge,
                          overflow: TextOverflow.ellipsis),
                    ),
                    if (total != null && total > 0) ...[
                      const SizedBox(width: TotoSpace.sm),
                      (incomplete ?? 0) == 0
                          ? const TotoBadge('Compilata',
                              tone: TotoBadgeTone.brand,
                              icon: Icons.check_rounded)
                          : TotoBadge(
                              '$incomplete partite mancanti',
                              tone: TotoBadgeTone.warning,
                              icon: Icons.schedule_rounded,
                            ),
                    ],
                  ],
                ),
                const SizedBox(height: TotoSpace.xs),
                Text(
                  deadlineLabel != null
                      ? '$memberCount membri · chiude $deadlineLabel'
                      : '$memberCount membri',
                  style: TotoType.number(13,
                      display: false, color: c.textTertiary),
                ),
              ],
            ),
          ),
          const SizedBox(width: TotoSpace.lg),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(position != null ? '$position°' : '—',
                  style: TotoType.number(28, color: c.textPrimary)),
              Text('su $memberCount', style: theme.textTheme.labelSmall),
            ],
          ),
        ],
      ),
    );
  }
}
