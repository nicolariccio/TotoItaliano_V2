import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/pill_badge.dart';
import '../../../../data/models/match.dart';

class MatchCard extends StatelessWidget {
  const MatchCard({super.key, required this.match});

  final Match match;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isOpen = match.isPredictionOpen;

    return Card(
      child: InkWell(
        borderRadius: AppRadii.lgRadius,
        onTap: () => context.go(RoutePaths.predictions),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: _TeamLabel(name: match.homeTeam.name, code: match.homeTeam.shortName)),
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
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(DateFormatter.matchKickoff(match.kickoff), style: theme.textTheme.bodySmall),
                  isOpen
                      ? const PillBadge(label: 'APERTO', color: AppColors.success)
                      : const PillBadge(
                          label: 'LOCKED',
                          color: AppColors.darkBorder,
                          icon: Icons.lock_outline_rounded,
                        ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: isOpen
                    ? ElevatedButton(
                        onPressed: () => context.go(RoutePaths.predictions),
                        child: const Text('PRONOSTICA'),
                      )
                    : OutlinedButton(
                        onPressed: null,
                        child: Text(
                          match.status == MatchStatus.finished
                              ? '${match.homeScore} - ${match.awayScore}'
                              : 'PRONOSTICI CHIUSI',
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TeamLabel extends StatelessWidget {
  const _TeamLabel({required this.name, required this.code, this.alignEnd = false});

  final String name;
  final String code;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final badge = CircleAvatar(
      radius: 16,
      backgroundColor: AppColors.azzurro.withValues(alpha: 0.16),
      child: Text(
        code.substring(0, code.length.clamp(0, 3)),
        style: theme.textTheme.labelSmall?.copyWith(color: AppColors.azzurro),
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
      children: alignEnd ? [label, const SizedBox(width: 8), badge] : [badge, const SizedBox(width: 8), label],
    );
  }
}
