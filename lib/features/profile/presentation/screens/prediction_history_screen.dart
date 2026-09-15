import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/toto_theme.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/toto_widgets.dart';
import '../../../../data/models/match.dart';
import '../../../../data/providers/football_data_providers.dart';
import '../../../../data/scoring/scoring_engine.dart';
import '../../../predictions/domain/entities/prediction.dart';
import '../../../predictions/presentation/providers/prediction_providers.dart';

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
              subtitle:
                  'I pronostici che salvi nella schedina appariranno qui.',
            );
          }
          final sorted = [...predictions]
            ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(TotoSpace.lg, TotoSpace.lg,
                TotoSpace.lg, TotoSpace.navClearance),
            itemCount: sorted.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: TotoSpace.md),
            itemBuilder: (context, index) =>
                _PredictionHistoryTile(prediction: sorted[index]),
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
      loading: () => const TotoCard(
          child: Padding(
              padding: EdgeInsets.all(0), child: LinearProgressIndicator())),
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

  String get _pickLabel {
    switch (prediction.market) {
      case PredictionMarket.result1x2:
        return '1X2: ${prediction.result1x2Value ?? '-'}';
      case PredictionMarket.goalNoGoal:
        return prediction.goalNoGoalValue == true ? 'Gol' : 'No Gol';
      case PredictionMarket.overUnder25:
        return prediction.overUnder25Value == true ? 'Over 2.5' : 'Under 2.5';
      case PredictionMarket.exactScore:
        return 'Pronostico ${prediction.exactHomeScore ?? '-'}-${prediction.exactAwayScore ?? '-'}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFinished = match.status == MatchStatus.finished;
    final result = isFinished
        ? ScoringEngine.calculate(prediction: prediction, match: match)
        : null;

    return TotoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${match.homeTeam.name} vs ${match.awayTeam.name}',
                  style: theme.textTheme.titleSmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (result != null)
                TotoBadge.points(result.points)
              else
                const TotoBadge('In attesa',
                    tone: TotoBadgeTone.neutral,
                    icon: Icons.schedule_rounded,
                    uppercase: false),
            ],
          ),
          const SizedBox(height: TotoSpace.xs),
          Text(DateFormatter.matchKickoff(match.kickoff),
              style: theme.textTheme.bodySmall),
          const SizedBox(height: TotoSpace.md),
          TotoBadge(
            _pickLabel,
            uppercase: false,
            tone: result == null
                ? TotoBadgeTone.neutral
                : (result.correct
                    ? TotoBadgeTone.success
                    : TotoBadgeTone.danger),
          ),
          if (isFinished) ...[
            const SizedBox(height: TotoSpace.md),
            Text('Risultato: ${match.homeScore} - ${match.awayScore}',
                style: theme.textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}
