import 'package:flutter/material.dart';

import '../../../../core/theme/toto_theme.dart';
import '../../../../core/widgets/toto_widgets.dart';

/// Riepilogo dei punti della schedina in tempo reale: somma dei punti
/// provvisori delle partite in corso e di quelle già concluse.
class LiveScoreSummary extends StatelessWidget {
  const LiveScoreSummary({
    super.key,
    required this.points,
    required this.liveCount,
    required this.settledCount,
    required this.pendingPoints,
  });

  /// Punti totali al momento (partite live + concluse).
  final int points;

  /// Partite in corso con un pronostico.
  final int liveCount;

  /// Partite concluse con un pronostico.
  final int settledCount;

  /// Parte dei punti ancora non definitiva (partite in corso).
  final int pendingPoints;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final t = context.t;
    final isLive = liveCount > 0;

    final subtitle = isLive
        ? (pendingPoints > 0
            ? '$pendingPoints provvisori · $liveCount in corso'
            : '$liveCount ${liveCount == 1 ? 'partita' : 'partite'} in corso')
        : '$settledCount ${settledCount == 1 ? 'partita conclusa' : 'partite concluse'}';

    return Semantics(
      liveRegion: true,
      label: 'Punti della schedina: $points. $subtitle',
      child: TotoCard(
        level: TotoCardLevel.elevated,
        accent: isLive ? c.brand.withValues(alpha: 0.45) : null,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('PUNTI SCHEDINA', style: t.labelSmall),
                      if (isLive) ...[
                        const SizedBox(width: TotoSpace.sm),
                        const TotoBadge.live(),
                      ],
                    ],
                  ),
                  const SizedBox(height: TotoSpace.sm),
                  Text(subtitle, style: t.bodySmall),
                ],
              ),
            ),
            AnimatedSwitcher(
              duration: context.reducedMotion ? Duration.zero : TotoMotion.base,
              switchInCurve: TotoMotion.enter,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.8, end: 1).animate(animation),
                  child: child,
                ),
              ),
              child: Text(
                '$points',
                key: ValueKey(points),
                style: TotoType.number(40,
                    color: points > 0 ? c.success : c.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
