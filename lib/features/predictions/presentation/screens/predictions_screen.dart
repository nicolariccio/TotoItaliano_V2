import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/toto_theme.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../data/providers/football_data_providers.dart';
import '../../../leagues/presentation/providers/league_providers.dart';
import '../controllers/schedina_controller.dart';
import '../controllers/schedina_state.dart';
import '../widgets/schedina_row.dart';

class PredictionsScreen extends ConsumerWidget {
  const PredictionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaguesAsync = ref.watch(myLeaguesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Schedina')),
      body: leaguesAsync.when(
        loading: () => const AppLoadingView(),
        error: (error, stackTrace) => AppErrorView(
          message: 'Non è stato possibile verificare le tue leghe.',
          onRetry: () => ref.invalidate(myLeaguesProvider),
        ),
        data: (leagues) =>
            leagues.isEmpty ? const _LeagueGate() : const _SchedinaBody(),
      ),
    );
  }
}

class _LeagueGate extends StatelessWidget {
  const _LeagueGate();

  @override
  Widget build(BuildContext context) {
    return AppEmptyView(
      icon: Icons.groups_outlined,
      title: 'Serve una lega per pronosticare',
      subtitle:
          'Crea una lega privata o entra con un invite code prima di compilare la schedina.',
      action: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FilledButton(
            onPressed: () => context.push(RoutePaths.leagueCreate),
            child: const Text('Crea lega'),
          ),
          const SizedBox(width: TotoSpace.md),
          OutlinedButton(
            onPressed: () => context.push(RoutePaths.leagueJoin),
            child: const Text('Entra in lega'),
          ),
        ],
      ),
    );
  }
}

class _SchedinaBody extends ConsumerWidget {
  const _SchedinaBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchdayAsync = ref.watch(currentMatchdayProvider);
    final matchesAsync = ref.watch(currentMatchdayMatchesProvider);
    final schedina = ref.watch(schedinaControllerProvider);
    final controller = ref.read(schedinaControllerProvider.notifier);
    final c = context.c;

    ref.listen(schedinaControllerProvider, (previous, next) {
      if (next.savedSuccessfully && previous?.savedSuccessfully != true) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Schedina salvata.')));
      }
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(next.errorMessage!)));
      }
    });

    final bool isLoading =
        matchdayAsync.isLoading || matchesAsync.isLoading || schedina.isLoading;
    final Object? error = matchdayAsync.error ?? matchesAsync.error;

    if (isLoading) return const AppLoadingView();
    if (error != null) {
      return AppErrorView(
        message: 'Non è stato possibile caricare le partite.',
        onRetry: () {
          ref.invalidate(matchdaysProvider);
          ref.invalidate(currentMatchdayMatchesProvider);
        },
      );
    }

    final matches = matchesAsync.value!;
    if (matches.isEmpty) {
      return const AppEmptyView(
        title: 'Nessuna partita in programma',
        subtitle: 'Torna più tardi per la prossima giornata.',
      );
    }

    final openMatchesCount = matches.where((m) => m.isPredictionOpen).length;
    final bool canSave = openMatchesCount > 0 && !schedina.isSaving;
    final double progress =
        matches.isEmpty ? 0 : schedina.completedCount / matches.length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              TotoSpace.lg, TotoSpace.md, TotoSpace.lg, TotoSpace.xs),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Giornata ${matchdayAsync.value?.number ?? ''}',
                  style: Theme.of(context).textTheme.titleMedium),
              Text(
                '${schedina.completedCount}/${matches.length} completati',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(
                TotoSpace.lg, TotoSpace.sm, TotoSpace.lg, TotoSpace.sm),
            itemCount: matches.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: TotoSpace.sm),
            itemBuilder: (context, index) {
              final match = matches[index];
              final pick = schedina.picks[match.id] ?? const PickState();
              return SchedinaRow(
                  match: match, pick: pick, controller: controller);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
              TotoSpace.lg, TotoSpace.xs, TotoSpace.lg, TotoSpace.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(TotoRadius.full),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: c.neutralContainer,
                  color: c.brand,
                ),
              ),
              const SizedBox(height: TotoSpace.md),
              FilledButton(
                onPressed: canSave ? () => controller.save(matches) : null,
                child: schedina.isSaving
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: c.textOnPrimary),
                      )
                    : const Text('Salva schedina'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
