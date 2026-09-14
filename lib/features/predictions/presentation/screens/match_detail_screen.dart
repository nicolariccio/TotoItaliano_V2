import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/pill_badge.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../data/models/match.dart';
import '../../../../data/providers/football_data_providers.dart';
import '../controllers/prediction_form_controller.dart';
import '../widgets/score_stepper.dart';
import '../widgets/selectable_button.dart';

class MatchDetailScreen extends ConsumerWidget {
  const MatchDetailScreen({super.key, required this.matchId});

  final String matchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchAsync = ref.watch(matchByIdProvider(matchId));

    return Scaffold(
      appBar: AppBar(title: const Text('Pronostico')),
      body: matchAsync.when(
        loading: () => const AppLoadingView(),
        error: (error, stackTrace) => AppErrorView(
          message: 'Non è stato possibile caricare la partita.',
          onRetry: () => ref.invalidate(matchByIdProvider(matchId)),
        ),
        data: (match) {
          if (match == null) {
            return const AppErrorView(message: 'Partita non trovata.');
          }
          return _MatchPredictionView(match: match);
        },
      ),
    );
  }
}

class _MatchPredictionView extends ConsumerWidget {
  const _MatchPredictionView({required this.match});

  final Match match;

  static const List<String> _thresholds = ['1.5', '2.5', '3.5'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(predictionFormControllerProvider(match));
    final controller = ref.read(predictionFormControllerProvider(match).notifier);
    final bool isOpen = match.isPredictionOpen;

    ref.listen(predictionFormControllerProvider(match), (previous, next) {
      if (next.savedSuccessfully && previous?.savedSuccessfully != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pronostico salvato.')),
        );
      }
      if (next.errorMessage != null && next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.errorMessage!)));
      }
    });

    if (state.isLoadingExisting) {
      return const AppLoadingView();
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _MatchHeader(match: match),
        if (!isOpen) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.darkSurfaceElevated,
              borderRadius: AppRadii.mdRadius,
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.lock_outline_rounded, color: AppColors.darkTextSecondary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    match.status == MatchStatus.finished
                        ? 'Partita conclusa: i pronostici sono chiusi.'
                        : 'I pronostici per questa partita sono chiusi dal kickoff.',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        Text('RISULTATO ESATTO', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        ScoreStepper(
          label: match.homeTeam.name,
          value: state.homeScore,
          enabled: isOpen,
          onIncrement: controller.incrementHomeScore,
          onDecrement: controller.decrementHomeScore,
        ),
        const SizedBox(height: 8),
        ScoreStepper(
          label: match.awayTeam.name,
          value: state.awayScore,
          enabled: isOpen,
          onIncrement: controller.incrementAwayScore,
          onDecrement: controller.decrementAwayScore,
        ),
        const SizedBox(height: 24),
        Text('1X2', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        Row(
          children: [
            SelectableButton(
              label: '1',
              selected: state.result1x2 == '1',
              enabled: isOpen,
              onTap: () => controller.selectResult1x2('1'),
            ),
            const SizedBox(width: 8),
            SelectableButton(
              label: 'X',
              selected: state.result1x2 == 'X',
              enabled: isOpen,
              onTap: () => controller.selectResult1x2('X'),
            ),
            const SizedBox(width: 8),
            SelectableButton(
              label: '2',
              selected: state.result1x2 == '2',
              enabled: isOpen,
              onTap: () => controller.selectResult1x2('2'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text('GOAL', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        Row(
          children: [
            SelectableButton(
              label: 'GOAL',
              selected: state.goalNoGoal == true,
              enabled: isOpen,
              onTap: () => controller.selectGoalNoGoal(true),
            ),
            const SizedBox(width: 8),
            SelectableButton(
              label: 'NO GOAL',
              selected: state.goalNoGoal == false,
              enabled: isOpen,
              onTap: () => controller.selectGoalNoGoal(false),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text('OVER / UNDER', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        for (final threshold in _thresholds) ...[
          Row(
            children: [
              SelectableButton(
                label: 'Over $threshold',
                selected: state.overUnder[threshold] == true,
                enabled: isOpen,
                onTap: () => controller.selectOverUnder(threshold, true),
              ),
              const SizedBox(width: 8),
              SelectableButton(
                label: 'Under $threshold',
                selected: state.overUnder[threshold] == false,
                enabled: isOpen,
                onTap: () => controller.selectOverUnder(threshold, false),
              ),
            ],
          ),
          if (threshold != _thresholds.last) const SizedBox(height: 8),
        ],
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: (isOpen && !state.isSaving) ? controller.save : null,
          child: state.isSaving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('SALVA PRONOSTICO'),
        ),
      ],
    );
  }
}

class _MatchHeader extends StatelessWidget {
  const _MatchHeader({required this.match});

  final Match match;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                match.homeTeam.name,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('VS', style: theme.textTheme.bodyMedium),
            ),
            Expanded(
              child: Text(
                match.awayTeam.name,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(DateFormatter.matchKickoff(match.kickoff), style: theme.textTheme.bodySmall),
            const SizedBox(width: 8),
            if (match.status == MatchStatus.finished)
              PillBadge(
                label: '${match.homeScore} - ${match.awayScore}',
                color: AppColors.darkBorder,
              ),
          ],
        ),
      ],
    );
  }
}
