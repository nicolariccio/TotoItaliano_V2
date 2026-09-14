import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/pill_badge.dart';
import '../../../../data/models/match.dart';
import '../../domain/entities/prediction.dart';
import '../controllers/schedina_controller.dart';
import '../controllers/schedina_state.dart';
import 'selectable_button.dart';

class SchedinaRow extends StatelessWidget {
  const SchedinaRow(
      {super.key,
      required this.match,
      required this.pick,
      required this.controller});

  final Match match;
  final PickState pick;
  final SchedinaController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool enabled = match.isPredictionOpen;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${match.homeTeam.shortName} - ${match.awayTeam.shortName}',
                    style: theme.textTheme.labelLarge,
                  ),
                ),
                Text(DateFormatter.matchKickoff(match.kickoff),
                    style: theme.textTheme.bodySmall),
                if (!enabled) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.lock_outline_rounded,
                      size: 16, color: AppColors.darkTextSecondary),
                ],
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                SelectableButton(
                  label: '1X2',
                  selected: pick.market == PredictionMarket.result1x2,
                  enabled: enabled,
                  onTap: () => controller.selectMarket(
                      match.id, PredictionMarket.result1x2),
                ),
                const SizedBox(width: 6),
                SelectableButton(
                  label: 'GOAL',
                  selected: pick.market == PredictionMarket.goalNoGoal,
                  enabled: enabled,
                  onTap: () => controller.selectMarket(
                      match.id, PredictionMarket.goalNoGoal),
                ),
                const SizedBox(width: 6),
                SelectableButton(
                  label: 'U/O 2.5',
                  selected: pick.market == PredictionMarket.overUnder25,
                  enabled: enabled,
                  onTap: () => controller.selectMarket(
                      match.id, PredictionMarket.overUnder25),
                ),
                const SizedBox(width: 6),
                SelectableButton(
                  label: 'ESATTO',
                  selected: pick.market == PredictionMarket.exactScore,
                  enabled: enabled,
                  onTap: () => controller.selectMarket(
                      match.id, PredictionMarket.exactScore),
                ),
              ],
            ),
            if (pick.market != null) ...[
              const SizedBox(height: 10),
              _ValuePicker(
                  match: match,
                  pick: pick,
                  controller: controller,
                  enabled: enabled),
            ],
          ],
        ),
      ),
    );
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
            SelectableButton(
              label: '1',
              selected: pick.result1x2Value == '1',
              enabled: enabled,
              onTap: () => controller.setResult1x2(match.id, '1'),
            ),
            const SizedBox(width: 6),
            SelectableButton(
              label: 'X',
              selected: pick.result1x2Value == 'X',
              enabled: enabled,
              onTap: () => controller.setResult1x2(match.id, 'X'),
            ),
            const SizedBox(width: 6),
            SelectableButton(
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
            SelectableButton(
              label: 'GOAL',
              selected: pick.goalNoGoalValue == true,
              enabled: enabled,
              onTap: () => controller.setGoalNoGoal(match.id, true),
            ),
            const SizedBox(width: 6),
            SelectableButton(
              label: 'NO GOAL',
              selected: pick.goalNoGoalValue == false,
              enabled: enabled,
              onTap: () => controller.setGoalNoGoal(match.id, false),
            ),
          ],
        );

      case PredictionMarket.overUnder25:
        return Row(
          children: [
            SelectableButton(
              label: 'OVER 2.5',
              selected: pick.overUnder25Value == true,
              enabled: enabled,
              onTap: () => controller.setOverUnder25(match.id, true),
            ),
            const SizedBox(width: 6),
            SelectableButton(
              label: 'UNDER 2.5',
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
            const SizedBox(width: 16),
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
                width: 20,
                child: Text('${value ?? '-'}', textAlign: TextAlign.center)),
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
    if (pick.market == null)
      return const PillBadge(
          label: 'Non pronosticato', color: AppColors.darkBorder);
    return PillBadge(label: _label(pick), color: AppColors.azzurro);
  }

  String _label(PickState pick) {
    switch (pick.market!) {
      case PredictionMarket.result1x2:
        return '1X2: ${pick.result1x2Value ?? '-'}';
      case PredictionMarket.goalNoGoal:
        return pick.goalNoGoalValue == true ? 'GOAL' : 'NO GOAL';
      case PredictionMarket.overUnder25:
        return pick.overUnder25Value == true ? 'Over 2.5' : 'Under 2.5';
      case PredictionMarket.exactScore:
        return '${pick.exactHomeScore ?? '-'}-${pick.exactAwayScore ?? '-'}';
    }
  }
}
