import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/toto_theme.dart';
import '../../../../core/widgets/podium_leaderboard.dart';
import '../../../../core/widgets/ranked_entry.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/toto_widgets.dart';
import '../../../../data/providers/football_data_providers.dart';
import '../../../predictions/presentation/controllers/schedina_controller.dart';
import '../../../predictions/presentation/controllers/schedina_state.dart';
import '../../../predictions/presentation/widgets/schedina_row.dart';
import '../providers/league_providers.dart';

enum _LeagueTab { classifica, schedina }

/// Dettaglio di una lega: classifica e schedina sono entrambe scoperte
/// da qui, non da tab globali — ogni lega ha la sua schedina indipendente
/// (stesso utente può pronosticare diversamente la stessa partita in
/// leghe diverse), quindi il contesto "di quale lega" deve sempre essere
/// esplicito.
class LeagueDetailScreen extends ConsumerStatefulWidget {
  const LeagueDetailScreen({super.key, required this.leagueId});

  final String leagueId;

  @override
  ConsumerState<LeagueDetailScreen> createState() => _LeagueDetailScreenState();
}

class _LeagueDetailScreenState extends ConsumerState<LeagueDetailScreen> {
  _LeagueTab _tab = _LeagueTab.classifica;

  @override
  Widget build(BuildContext context) {
    final leagueAsync = ref.watch(leagueByIdProvider(widget.leagueId));

    return Scaffold(
      appBar: AppBar(title: Text(leagueAsync.value?.name ?? 'Lega')),
      body: leagueAsync.when(
        loading: () => const AppLoadingView(),
        error: (error, stackTrace) => AppErrorView(
          message: 'Non è stato possibile caricare la lega.',
          onRetry: () => ref.invalidate(leagueByIdProvider(widget.leagueId)),
        ),
        data: (league) {
          if (league == null) {
            return const AppErrorView(message: 'Lega non trovata.');
          }

          final c = context.c;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    TotoSpace.lg, TotoSpace.md, TotoSpace.lg, TotoSpace.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (league.description != null &&
                        league.description!.isNotEmpty) ...[
                      Text(league.description!,
                          style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: TotoSpace.md),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: TotoSpace.lg, vertical: TotoSpace.md),
                      decoration: BoxDecoration(
                        color: c.surface2,
                        borderRadius: BorderRadius.circular(TotoRadius.md),
                        border: Border.all(color: c.borderSubtle),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Codice invito',
                                    style:
                                        Theme.of(context).textTheme.bodySmall),
                                Text(
                                  league.inviteCode,
                                  style: TotoType.number(20,
                                      display: false, color: c.brand),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy_rounded),
                            tooltip: 'Copia codice',
                            onPressed: () async {
                              await Clipboard.setData(
                                  ClipboardData(text: league.inviteCode));
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Codice copiato negli appunti.')),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: TotoSpace.md),
                    TotoSegmented<_LeagueTab>(
                      values: _LeagueTab.values,
                      labels: (t) => switch (t) {
                        _LeagueTab.classifica => 'Classifica',
                        _LeagueTab.schedina => 'Schedina',
                      },
                      selected: _tab,
                      onChanged: (t) => setState(() => _tab = t),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: switch (_tab) {
                  _LeagueTab.classifica => _ClassificaTab(leagueId: widget.leagueId),
                  _LeagueTab.schedina => _SchedinaTab(leagueId: widget.leagueId),
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ClassificaTab extends ConsumerWidget {
  const _ClassificaTab({required this.leagueId});

  final String leagueId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(leagueMembersProvider(leagueId));
    return membersAsync.when(
      loading: () => const AppLoadingView(),
      error: (error, stackTrace) => AppErrorView(
        message: 'Non è stato possibile caricare i membri.',
        onRetry: () => ref.invalidate(leagueMembersProvider(leagueId)),
      ),
      data: (members) => PodiumLeaderboard(
        emptyTitle: 'Nessun membro ancora',
        entries: [
          for (final member in members)
            RankedEntry(
              id: member.userId,
              username: member.username,
              photoUrl: member.photoUrl,
              points: member.totalPoints,
            ),
        ],
      ),
    );
  }
}

class _SchedinaTab extends ConsumerWidget {
  const _SchedinaTab({required this.leagueId});

  final String leagueId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchdayAsync = ref.watch(currentMatchdayProvider);
    final matchesAsync = ref.watch(currentMatchdayMatchesProvider);
    final schedina = ref.watch(schedinaControllerProvider(leagueId));
    final controller = ref.read(schedinaControllerProvider(leagueId).notifier);
    final c = context.c;

    ref.listen(schedinaControllerProvider(leagueId), (previous, next) {
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
          padding: const EdgeInsets.fromLTRB(TotoSpace.lg, TotoSpace.xs,
              TotoSpace.lg, TotoSpace.navClearance),
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
