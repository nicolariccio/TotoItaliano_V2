import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/toto_theme.dart';
import '../../../../core/utils/error_snackbar.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/toto_widgets.dart';
import '../../../../data/models/match.dart';
import '../../../../data/models/matchday.dart';
import '../../../../data/models/team.dart';
import '../../../../data/providers/football_data_providers.dart';
import '../providers/admin_providers.dart';

class AdminMatchdayScreen extends ConsumerWidget {
  const AdminMatchdayScreen({super.key, required this.matchdayId});

  final String matchdayId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchdaysAsync = ref.watch(matchdaysProvider);
    final matchesAsync = ref.watch(matchesForMatchdayProvider(matchdayId));
    final teamsAsync = ref.watch(teamsProvider);

    final matchday = matchdaysAsync.valueOrNull
        ?.firstWhereOrNull((m) => m.id == matchdayId);

    return Scaffold(
      appBar: AppBar(
        title: Text(matchday != null
            ? 'Giornata ${matchday.number}'
            : 'Giornata'),
        actions: [
          if (matchday != null && matchday.status != MatchdayStatus.active)
            TextButton(
              onPressed: () async {
                try {
                  await ref.read(adminRepositoryProvider).setMatchdayStatus(
                      matchday.competitionId, matchday.id, MatchdayStatus.active);
                  ref.invalidate(matchdaysProvider);
                } catch (error) {
                  if (context.mounted) showFailureSnackBar(context, error);
                }
              },
              child: const Text('Segna attiva'),
            ),
        ],
      ),
      floatingActionButton: teamsAsync.valueOrNull == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _createMatch(
                  context, ref, matchday, teamsAsync.valueOrNull!),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Nuova partita'),
            ),
      body: matchesAsync.when(
        loading: () => const AppLoadingView(),
        error: (error, stackTrace) => AppErrorView(
          message: 'Non è stato possibile caricare le partite.',
          onRetry: () => ref.invalidate(matchesForMatchdayProvider(matchdayId)),
        ),
        data: (matches) {
          if (matches.isEmpty) {
            return const AppEmptyView(
              title: 'Nessuna partita',
              subtitle: 'Aggiungi la prima partita di questa giornata.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(TotoSpace.lg, TotoSpace.lg,
                TotoSpace.lg, TotoSpace.navClearance),
            itemCount: matches.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: TotoSpace.sm),
            itemBuilder: (context, index) =>
                _MatchRow(match: matches[index]),
          );
        },
      ),
    );
  }

  Future<void> _createMatch(BuildContext context, WidgetRef ref,
      Matchday? matchday, List<Team> teams) async {
    if (matchday == null) return;
    final result = await showDialog<_NewMatchInput>(
      context: context,
      builder: (context) => _NewMatchDialog(teams: teams),
    );
    if (result == null || !context.mounted) return;

    try {
      await ref.read(adminRepositoryProvider).createMatch(
            competitionId: matchday.competitionId,
            matchdayId: matchday.id,
            homeTeam: result.home,
            awayTeam: result.away,
            kickoff: result.kickoff,
          );
      ref.invalidate(matchesForMatchdayProvider(matchdayId));
    } catch (error) {
      if (context.mounted) showFailureSnackBar(context, error);
    }
  }
}

class _MatchRow extends ConsumerWidget {
  const _MatchRow({required this.match});

  final Match match;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isFinished = match.status == MatchStatus.finished;

    return TotoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('${match.homeTeam.name} - ${match.awayTeam.name}',
                    style: theme.textTheme.titleSmall),
              ),
              if (isFinished)
                Text('${match.homeScore} - ${match.awayScore}',
                    style: TotoType.number(18, display: false))
              else
                const TotoBadge('Da giocare',
                    tone: TotoBadgeTone.neutral, uppercase: false),
            ],
          ),
          const SizedBox(height: TotoSpace.xs),
          Text(
            '${match.kickoff.day}/${match.kickoff.month}/${match.kickoff.year} '
            '${match.kickoff.hour.toString().padLeft(2, '0')}:${match.kickoff.minute.toString().padLeft(2, '0')}',
            style: theme.textTheme.bodySmall,
          ),
          if (!isFinished) ...[
            const SizedBox(height: TotoSpace.sm),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                onPressed: () async {
                  final scores = await showDialog<(int, int)>(
                    context: context,
                    builder: (context) => _ResultDialog(match: match),
                  );
                  if (scores == null || !context.mounted) return;
                  try {
                    final scored = await ref
                        .read(adminRepositoryProvider)
                        .setMatchResultAndRecompute(
                          match: match,
                          homeScore: scores.$1,
                          awayScore: scores.$2,
                        );
                    ref.invalidate(matchesForMatchdayProvider(match.matchdayId));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(
                              'Risultato salvato. $scored pronostici aggiornati.')));
                    }
                  } catch (error) {
                    if (context.mounted) showFailureSnackBar(context, error);
                  }
                },
                child: const Text('Inserisci risultato'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ResultDialog extends StatefulWidget {
  const _ResultDialog({required this.match});

  final Match match;

  @override
  State<_ResultDialog> createState() => _ResultDialogState();
}

class _ResultDialogState extends State<_ResultDialog> {
  final _homeController = TextEditingController();
  final _awayController = TextEditingController();

  @override
  void dispose() {
    _homeController.dispose();
    _awayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.match.homeTeam.name} - ${widget.match.awayTeam.name}'),
      content: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: TextField(
              controller: _homeController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: InputDecoration(labelText: widget.match.homeTeam.shortName),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: TotoSpace.sm),
            child: Text('-'),
          ),
          Expanded(
            child: TextField(
              controller: _awayController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: InputDecoration(labelText: widget.match.awayTeam.shortName),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(), child: const Text('Annulla')),
        FilledButton(
          onPressed: () {
            final home = int.tryParse(_homeController.text);
            final away = int.tryParse(_awayController.text);
            if (home == null || away == null || home < 0 || away < 0) return;
            Navigator.of(context).pop((home, away));
          },
          child: const Text('Salva'),
        ),
      ],
    );
  }
}

class _NewMatchInput {
  const _NewMatchInput(
      {required this.home, required this.away, required this.kickoff});

  final Team home;
  final Team away;
  final DateTime kickoff;
}

class _NewMatchDialog extends StatefulWidget {
  const _NewMatchDialog({required this.teams});

  final List<Team> teams;

  @override
  State<_NewMatchDialog> createState() => _NewMatchDialogState();
}

class _NewMatchDialogState extends State<_NewMatchDialog> {
  Team? _home;
  Team? _away;
  DateTime _kickoff = DateTime.now().add(const Duration(days: 1));

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nuova partita'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<Team>(
            initialValue: _home,
            decoration: const InputDecoration(labelText: 'Squadra in casa'),
            items: [
              for (final t in widget.teams)
                DropdownMenuItem(value: t, child: Text(t.name)),
            ],
            onChanged: (v) => setState(() => _home = v),
          ),
          const SizedBox(height: TotoSpace.sm),
          DropdownButtonFormField<Team>(
            initialValue: _away,
            decoration: const InputDecoration(labelText: 'Squadra in trasferta'),
            items: [
              for (final t in widget.teams)
                DropdownMenuItem(value: t, child: Text(t.name)),
            ],
            onChanged: (v) => setState(() => _away = v),
          ),
          const SizedBox(height: TotoSpace.sm),
          TextButton(
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _kickoff,
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (date == null || !context.mounted) return;
              final time = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(_kickoff),
              );
              if (time == null) return;
              setState(() => _kickoff = DateTime(
                  date.year, date.month, date.day, time.hour, time.minute));
            },
            child: Text(
                'Calcio d\'inizio: ${_kickoff.day}/${_kickoff.month} ${_kickoff.hour.toString().padLeft(2, '0')}:${_kickoff.minute.toString().padLeft(2, '0')}'),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(), child: const Text('Annulla')),
        FilledButton(
          onPressed: _home == null || _away == null || _home == _away
              ? null
              : () => Navigator.of(context).pop(
                  _NewMatchInput(home: _home!, away: _away!, kickoff: _kickoff)),
          child: const Text('Crea'),
        ),
      ],
    );
  }
}
