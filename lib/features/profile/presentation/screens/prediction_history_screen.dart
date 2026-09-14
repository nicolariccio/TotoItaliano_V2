import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/pill_badge.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../data/models/match.dart';
import '../../../../data/providers/football_data_providers.dart';
import '../../../../data/scoring/scoring_engine.dart';
import '../../../predictions/domain/entities/prediction.dart';
import '../../../predictions/presentation/providers/prediction_providers.dart';

bool? _overUnderCorrect(
  Map<String, bool>? officialOverUnder,
  MapEntry<String, bool> predictedEntry,
  bool isFinished,
) {
  if (!isFinished || officialOverUnder == null) return null;
  final officialValue = officialOverUnder[predictedEntry.key];
  if (officialValue == null) return null;
  return officialValue == predictedEntry.value;
}

class PredictionHistoryScreen extends ConsumerWidget {
  const PredictionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final predictionsAsync = ref.watch(myPredictionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('I miei pronostici')),
      body: predictionsAsync.when(
        loading: () => const AppLoadingView(),
        error: (error, stackTrace) => AppErrorView(
          message: 'Non è stato possibile caricare lo storico.',
          onRetry: () => ref.invalidate(myPredictionsProvider),
        ),
        data: (predictions) {
          if (predictions.isEmpty) {
            return const AppEmptyView(
              title: 'Nessun pronostico ancora',
              subtitle: 'I pronostici che salvi appariranno qui.',
            );
          }
          final sorted = [...predictions]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: sorted.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) => _PredictionHistoryTile(prediction: sorted[index]),
          );
        },
      ),
    );
  }
}

class _PredictionHistoryTile extends ConsumerWidget {
  const _PredictionHistoryTile({required this.prediction});

  final Prediction prediction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchAsync = ref.watch(matchByIdProvider(prediction.matchId));

    return matchAsync.when(
      loading: () => const Card(child: Padding(padding: EdgeInsets.all(16), child: LinearProgressIndicator())),
      error: (error, stackTrace) => const SizedBox.shrink(),
      data: (match) {
        if (match == null) return const SizedBox.shrink();
        return _PredictionCard(prediction: prediction, match: match);
      },
    );
  }
}

class _PredictionCard extends StatelessWidget {
  const _PredictionCard({required this.prediction, required this.match});

  final Prediction prediction;
  final Match match;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFinished = match.status == MatchStatus.finished;
    final breakdown = isFinished ? ScoringEngine.calculate(prediction: prediction, match: match) : null;
    final officialOverUnder = match.overUnder;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${match.homeTeam.name} vs ${match.awayTeam.name}',
                    style: theme.textTheme.labelLarge,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (breakdown != null)
                  PillBadge(
                    label: '+${breakdown.total}',
                    color: breakdown.total > 0 ? AppColors.success : AppColors.darkBorder,
                  )
                else
                  const PillBadge(label: 'IN ATTESA', color: AppColors.darkBorder, icon: Icons.schedule_rounded),
              ],
            ),
            const SizedBox(height: 4),
            Text(DateFormatter.matchKickoff(match.kickoff), style: theme.textTheme.bodySmall),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (prediction.exactHomeScore != null && prediction.exactAwayScore != null)
                  _PickChip(
                    label: 'Pronostico ${prediction.exactHomeScore}-${prediction.exactAwayScore}',
                    correct: breakdown?.exactScoreCorrect,
                  ),
                if (prediction.result1x2 != null)
                  _PickChip(label: '1X2: ${prediction.result1x2}', correct: breakdown?.result1x2Correct),
                if (prediction.goalNoGoal != null)
                  _PickChip(
                    label: prediction.goalNoGoal! ? 'GOAL' : 'NO GOAL',
                    correct: breakdown?.goalNoGoalCorrect,
                  ),
                for (final entry in (prediction.overUnder ?? const <String, bool>{}).entries)
                  _PickChip(
                    label: '${entry.value ? 'Over' : 'Under'} ${entry.key}',
                    correct: _overUnderCorrect(officialOverUnder, entry, isFinished),
                  ),
              ],
            ),
            if (isFinished) ...[
              const SizedBox(height: 12),
              Text(
                'Risultato: ${match.homeScore} - ${match.awayScore}',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PickChip extends StatelessWidget {
  const _PickChip({required this.label, required this.correct});

  final String label;
  final bool? correct;

  @override
  Widget build(BuildContext context) {
    final Color color = correct == null
        ? AppColors.darkBorder
        : correct!
            ? AppColors.success
            : AppColors.error;
    return PillBadge(label: label, color: color.withValues(alpha: correct == null ? 1 : 0.85));
  }
}
