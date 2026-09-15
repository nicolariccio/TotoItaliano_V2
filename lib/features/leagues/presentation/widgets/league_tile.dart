import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/toto_theme.dart';
import '../../../../core/widgets/toto_widgets.dart';
import '../../../../data/models/league.dart';

/// Card di una lega nella lista "le mie leghe", usata sia in Home sia
/// nella schermata Leghe: tocco → dettaglio lega (classifica + schedina).
class LeagueTile extends StatelessWidget {
  const LeagueTile({super.key, required this.league});

  final League league;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.c;
    return TotoCard(
      onTap: () => context.push(RoutePaths.leagueDetailPath(league.id)),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: c.brandContainer,
            child: Icon(Icons.shield_rounded, color: c.brand),
          ),
          const SizedBox(width: TotoSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(league.name, style: theme.textTheme.titleSmall),
                const SizedBox(height: TotoSpace.xxs),
                Text('${league.memberCount} membri',
                    style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          TotoBadge(league.inviteCode, tone: TotoBadgeTone.brand, uppercase: false),
          const SizedBox(width: TotoSpace.xs),
          Icon(Icons.chevron_right_rounded, color: c.textTertiary),
        ],
      ),
    );
  }
}
