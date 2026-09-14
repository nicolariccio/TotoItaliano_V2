import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/state_views.dart';
import '../../../../data/providers/football_data_providers.dart';
import '../../../home/presentation/widgets/match_card.dart';

class PredictionsScreen extends ConsumerWidget {
  const PredictionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchdayAsync = ref.watch(currentMatchdayProvider);
    final matchesAsync = ref.watch(currentMatchdayMatchesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Giornata ${matchdayAsync.value?.number ?? ''}'.trim()),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(matchdaysProvider);
          ref.invalidate(currentMatchdayMatchesProvider);
          await ref.read(currentMatchdayMatchesProvider.future);
        },
        child: matchesAsync.when(
          loading: () => const AppLoadingView(),
          error: (error, stackTrace) => AppErrorView(
            message: 'Non è stato possibile caricare le partite.',
            onRetry: () => ref.invalidate(currentMatchdayMatchesProvider),
          ),
          data: (matches) {
            if (matches.isEmpty) {
              return const AppEmptyView(
                title: 'Nessuna partita in programma',
                subtitle: 'Torna più tardi per la prossima giornata.',
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: matches.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) => MatchCard(match: matches[index]),
            );
          },
        ),
      ),
    );
  }
}
