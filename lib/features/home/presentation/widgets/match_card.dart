import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/toto_theme.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/toto_widgets.dart';
import '../../../../data/models/match.dart';

class MatchCard extends StatelessWidget {
  const MatchCard({super.key, required this.match});

  final Match match;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isOpen = match.isPredictionOpen;

    return TotoCard(
      onTap: () => context.go(RoutePaths.predictions),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                  child: _TeamLabel(
                      name: match.homeTeam.name,
                      code: match.homeTeam.shortName)),
              Text('vs', style: theme.textTheme.bodySmall),
              Expanded(
                child: _TeamLabel(
                  name: match.awayTeam.name,
                  code: match.awayTeam.shortName,
                  alignEnd: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: TotoSpace.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(DateFormatter.matchKickoff(match.kickoff),
                  style: theme.textTheme.bodySmall),
              isOpen
                  ? const TotoBadge('Aperto',
                      tone: TotoBadgeTone.success, icon: Icons.check_rounded)
                  : const TotoBadge.locked(),
            ],
          ),
          const SizedBox(height: TotoSpace.md),
          SizedBox(
            width: double.infinity,
            child: isOpen
                ? FilledButton(
                    onPressed: () => context.go(RoutePaths.predictions),
                    child: const Text('Pronostica'),
                  )
                : OutlinedButton(
                    onPressed: null,
                    child: Text(
                      match.status == MatchStatus.finished
                          ? '${match.homeScore} - ${match.awayScore}'
                          : 'Pronostici chiusi',
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _TeamLabel extends StatelessWidget {
  const _TeamLabel(
      {required this.name, required this.code, this.alignEnd = false});

  final String name;
  final String code;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.c;
    final badge = CircleAvatar(
      radius: 16,
      backgroundColor: c.brand.withValues(alpha: 0.16),
      child: Text(
        code.substring(0, code.length.clamp(0, 3)),
        style: theme.textTheme.labelSmall?.copyWith(color: c.brand),
      ),
    );

    final label = Expanded(
      child: Text(
        name,
        textAlign: alignEnd ? TextAlign.end : TextAlign.start,
        style: theme.textTheme.labelLarge,
        overflow: TextOverflow.ellipsis,
      ),
    );

    return Row(
      children: alignEnd
          ? [label, const SizedBox(width: TotoSpace.sm), badge]
          : [badge, const SizedBox(width: TotoSpace.sm), label],
    );
  }
}
