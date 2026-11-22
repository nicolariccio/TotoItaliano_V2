import 'package:flutter/material.dart';

import '../../../../core/theme/toto_theme.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/toto_widgets.dart';
import '../../../../data/models/match.dart';
import '../../../../data/scoring/scoring_breakdown.dart';
import '../../domain/entities/prediction.dart';
import '../controllers/schedina_controller.dart';
import '../controllers/schedina_state.dart';

class SchedinaRow extends StatelessWidget {
  const SchedinaRow(
      {super.key,
      required this.match,
      required this.pick,
      required this.controller,
      this.live});

  final Match match;
  final PickState pick;
  final SchedinaController controller;

  /// Punteggio provvisorio del pick, se la partita è in corso o finita.
  final LivePickScore? live;

  static const _markets = [
    PredictionMarket.result1x2,
    PredictionMarket.goalNoGoal,
    PredictionMarket.overUnder25,
    PredictionMarket.exactScore,
  ];

  static const _marketLabels = {
    PredictionMarket.result1x2: '1X2',
    PredictionMarket.goalNoGoal: 'Gol/No',
    PredictionMarket.overUnder25: 'U/O 2.5',
    PredictionMarket.exactScore: 'Esatto',
  };

  Color? _accent(TotoColors c) {
    final l = live;
    if (l != null) {
      if (l.winningNow) return c.successBorder;
      if (l.settled) return c.dangerBorder;
    }
    return pick.market != null && match.isPredictionOpen
        ? c.brand.withValues(alpha: 0.45)
        : null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.c;
    final bool enabled = match.isPredictionOpen;
    final bool isLive = match.status == MatchStatus.live;
    final bool hasScore = (isLive || match.status == MatchStatus.finished) &&
        match.homeScore != null &&
        match.awayScore != null;

    return TotoCard(
      accent: _accent(c),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${match.homeTeam.shortName} - ${match.awayTeam.shortName}',
                  style: theme.textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: TotoSpace.sm),
              if (hasScore)
                Text(
                  '${match.homeScore} - ${match.awayScore}',
                  style: TotoType.number(20,
                      display: false, color: isLive ? c.danger : c.textPrimary),
                )
              else
                Text(DateFormatter.matchKickoff(match.kickoff),
                    style: theme.textTheme.bodySmall),
              if (!enabled && !hasScore) ...[
                const SizedBox(width: TotoSpace.sm),
                const TotoBadge.locked(),
              ],
            ],
          ),
          if (hasScore) ...[
            const SizedBox(height: TotoSpace.sm),
            Row(
              children: [
                if (isLive)
                  const TotoBadge.live()
                else
                  const TotoBadge.locked(),
                const SizedBox(width: TotoSpace.sm),
                if (live != null) _LivePointsBadge(live: live!),
              ],
            ),
          ],
          const SizedBox(height: TotoSpace.md),
          Opacity(
            opacity: enabled ? 1 : 0.5,
            child: IgnorePointer(
              ignoring: !enabled,
              child: TotoSegmented<PredictionMarket>(
                values: _markets,
                labels: (m) => _marketLabels[m]!,
                selected: pick.market,
                onChanged: (m) => controller.selectMarket(match.id, m),
              ),
            ),
          ),
          if (pick.market != null) ...[
            const SizedBox(height: TotoSpace.md),
            _ValuePicker(
                match: match,
                pick: pick,
                controller: controller,
                enabled: enabled),
          ],
        ],
      ),
    );
  }
}

/// Punti del pronostico con il risultato attuale: definitivi se l'esito non
/// può più cambiare, altrimenti marcati come provvisori ("ora").
class _LivePointsBadge extends StatelessWidget {
  const _LivePointsBadge({required this.live});

  final LivePickScore live;

  @override
  Widget build(BuildContext context) {
    if (live.settled) {
      return live.winningNow
          ? TotoBadge.points(live.points)
          : const TotoBadge('0',
              tone: TotoBadgeTone.neutral,
              icon: Icons.close_rounded,
              uppercase: false);
    }
    return live.winningNow
        ? TotoBadge('+${live.points} · ora',
            tone: TotoBadgeTone.success,
            icon: Icons.trending_up_rounded,
            uppercase: false)
        : const TotoBadge('0 · ora',
            tone: TotoBadgeTone.neutral, uppercase: false);
  }
}

class _ValuePicker extends StatelessWidget {
  const _ValuePicker(
      {required this.match,
      required this.pick,
      required this.controller,
      required this.enabled});

  final Match match;
  final PickState pick;
  final SchedinaController controller;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    switch (pick.market!) {
      case PredictionMarket.result1x2:
        return Row(
          children: [
            TotoValueChip(
              label: '1',
              selected: pick.result1x2Value == '1',
              enabled: enabled,
              onTap: () => controller.setResult1x2(match.id, '1'),
            ),
            const SizedBox(width: TotoSpace.sm),
            TotoValueChip(
              label: 'X',
              selected: pick.result1x2Value == 'X',
              enabled: enabled,
              onTap: () => controller.setResult1x2(match.id, 'X'),
            ),
            const SizedBox(width: TotoSpace.sm),
            TotoValueChip(
              label: '2',
              selected: pick.result1x2Value == '2',
              enabled: enabled,
              onTap: () => controller.setResult1x2(match.id, '2'),
            ),
          ],
        );

      case PredictionMarket.goalNoGoal:
        return Row(
          children: [
            TotoValueChip(
              label: 'Gol',
              selected: pick.goalNoGoalValue == true,
              enabled: enabled,
              onTap: () => controller.setGoalNoGoal(match.id, true),
            ),
            const SizedBox(width: TotoSpace.sm),
            TotoValueChip(
              label: 'No Gol',
              selected: pick.goalNoGoalValue == false,
              enabled: enabled,
              onTap: () => controller.setGoalNoGoal(match.id, false),
            ),
          ],
        );

      case PredictionMarket.overUnder25:
        return Row(
          children: [
            TotoValueChip(
              label: 'Over 2.5',
              selected: pick.overUnder25Value == true,
              enabled: enabled,
              onTap: () => controller.setOverUnder25(match.id, true),
            ),
            const SizedBox(width: TotoSpace.sm),
            TotoValueChip(
              label: 'Under 2.5',
              selected: pick.overUnder25Value == false,
              enabled: enabled,
              onTap: () => controller.setOverUnder25(match.id, false),
            ),
          ],
        );

      case PredictionMarket.exactScore:
        return Row(
          children: [
            _MiniStepper(
              label: match.homeTeam.shortName,
              value: pick.exactHomeScore,
              enabled: enabled,
              onChanged: (v) => controller.setExactScore(match.id,
                  home: v, away: pick.exactAwayScore),
            ),
            const SizedBox(width: TotoSpace.xl),
            _MiniStepper(
              label: match.awayTeam.shortName,
              value: pick.exactAwayScore,
              enabled: enabled,
              onChanged: (v) => controller.setExactScore(match.id,
                  home: pick.exactHomeScore, away: v),
            ),
          ],
        );
    }
  }
}

class _MiniStepper extends StatelessWidget {
  const _MiniStepper(
      {required this.label,
      required this.value,
      required this.enabled,
      required this.onChanged});

  final String label;
  final int? value;
  final bool enabled;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.bodySmall),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.remove_circle_outline_rounded, size: 20),
              onPressed: enabled
                  ? () => onChanged(((value ?? 0) - 1).clamp(0, 15))
                  : null,
            ),
            SizedBox(
              width: 24,
              child: Text('${value ?? '-'}',
                  textAlign: TextAlign.center,
                  style: TotoType.number(16, display: false)),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
              onPressed: enabled
                  ? () => onChanged(((value ?? 0) + 1).clamp(0, 15))
                  : null,
            ),
          ],
        ),
      ],
    );
  }
}

/// Badge di sintesi per il pick già scelto (usato altrove, es. storico).
class PickSummary extends StatelessWidget {
  const PickSummary({super.key, required this.pick});

  final PickState pick;

  @override
  Widget build(BuildContext context) {
    if (pick.market == null) {
      return const TotoBadge('Non pronosticato',
          tone: TotoBadgeTone.neutral, uppercase: false);
    }
    return TotoBadge(_label(pick), tone: TotoBadgeTone.brand, uppercase: false);
  }

  String _label(PickState pick) {
    switch (pick.market!) {
      case PredictionMarket.result1x2:
        return '1X2: ${pick.result1x2Value ?? '-'}';
      case PredictionMarket.goalNoGoal:
        return pick.goalNoGoalValue == true ? 'Gol' : 'No Gol';
      case PredictionMarket.overUnder25:
        return pick.overUnder25Value == true ? 'Over 2.5' : 'Under 2.5';
      case PredictionMarket.exactScore:
        return '${pick.exactHomeScore ?? '-'}-${pick.exactAwayScore ?? '-'}';
    }
  }
}
