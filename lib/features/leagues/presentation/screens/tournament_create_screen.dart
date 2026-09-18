import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/toto_theme.dart';
import '../../../../core/utils/error_snackbar.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/toto_widgets.dart';
import '../../../../data/models/league_member.dart';
import '../../../../data/models/league_tournament.dart';
import '../../../../data/providers/football_data_providers.dart';
import '../../../../data/scoring/tournament_scoring.dart';
import '../../domain/repositories/tournament_repository.dart';
import '../providers/league_providers.dart';
import '../providers/tournament_providers.dart';

/// Creazione di un torneo interno alla lega: nome, tipo, partecipanti
/// (default tutti i membri) e configurazione specifica per tipo — vedi
/// il piano approvato in `crispy-splashing-puddle.md`.
class TournamentCreateScreen extends ConsumerStatefulWidget {
  const TournamentCreateScreen({super.key, required this.leagueId});

  final String leagueId;

  @override
  ConsumerState<TournamentCreateScreen> createState() =>
      _TournamentCreateScreenState();
}

class _TournamentCreateScreenState
    extends ConsumerState<TournamentCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  TournamentType _type = TournamentType.campionato;
  CoppaFormat _coppaFormat = CoppaFormat.knockout;
  int _groupSize = 4;
  int _advancePerGroup = 2;
  int _eliminationsPerMatchday = 1;
  List<HighlanderTiebreak> _tiebreakOrder =
      List.of(TournamentScoring.defaultTiebreakOrder);

  // null finché i membri non sono ancora arrivati la prima volta: da lì in
  // poi la selezione (default "tutti") resta sotto controllo dell'utente,
  // anche se lo stream dei membri si aggiorna nel frattempo.
  Set<String>? _selectedUserIds;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit(List<LeagueMember> members) async {
    if (!_formKey.currentState!.validate()) return;
    final selected = _selectedUserIds ?? members.map((m) => m.userId).toSet();
    final minParticipants = _type == TournamentType.campionato ? 1 : 2;
    if (selected.length < minParticipants) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(minParticipants == 1
            ? 'Seleziona almeno un partecipante.'
            : 'Seleziona almeno due partecipanti.'),
      ));
      return;
    }

    setState(() => _isSaving = true);
    try {
      final matchday = await ref.read(currentMatchdayProvider.future);
      final seedMembers = [
        for (final m in members)
          if (selected.contains(m.userId))
            TournamentSeedMember(
              userId: m.userId,
              username: m.username,
              photoUrl: m.photoUrl,
              totalPoints: m.totalPoints,
            ),
      ];

      final tournamentId =
          await ref.read(tournamentRepositoryProvider).createTournament(
                leagueId: widget.leagueId,
                name: _nameController.text.trim(),
                type: _type,
                participantUserIds: seedMembers.map((m) => m.userId).toList(),
                seedMembers: seedMembers,
                createdFromMatchdayId: matchday.id,
                coppaFormat: _type == TournamentType.coppa ? _coppaFormat : null,
                groupSize: _type == TournamentType.coppa &&
                        _coppaFormat == CoppaFormat.groupsThenKnockout
                    ? _groupSize
                    : null,
                advancePerGroup: _type == TournamentType.coppa &&
                        _coppaFormat == CoppaFormat.groupsThenKnockout
                    ? _advancePerGroup
                    : null,
                eliminationsPerMatchday: _eliminationsPerMatchday,
                tiebreakOrder: _tiebreakOrder,
              );
      if (!mounted) return;
      context.pushReplacement(
          RoutePaths.tournamentDetailPath(widget.leagueId, tournamentId));
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      showFailureSnackBar(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(leagueMembersProvider(widget.leagueId));

    return Scaffold(
      appBar: AppBar(title: const Text('Crea torneo')),
      body: SafeArea(
        child: membersAsync.when(
          loading: () => const AppLoadingView(),
          error: (error, stackTrace) => AppErrorView(
            message: 'Non è stato possibile caricare i membri della lega.',
            onRetry: () =>
                ref.invalidate(leagueMembersProvider(widget.leagueId)),
          ),
          data: (members) {
            _selectedUserIds ??= members.map((m) => m.userId).toSet();
            final selected = _selectedUserIds!;

            return Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                    TotoSpace.lg, TotoSpace.md, TotoSpace.lg, TotoSpace.xxl),
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Nome torneo'),
                    validator: (v) => Validators.required(v, field: 'Nome'),
                  ),
                  const SizedBox(height: TotoSpace.lg),
                  Text('Tipo', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: TotoSpace.sm),
                  TotoSegmented<TournamentType>(
                    values: TournamentType.values,
                    labels: (t) => switch (t) {
                      TournamentType.campionato => 'Campionato',
                      TournamentType.coppa => 'Coppa',
                      TournamentType.highlander => 'Highlander',
                    },
                    selected: _type,
                    onChanged: (t) => setState(() => _type = t),
                  ),
                  const SizedBox(height: TotoSpace.lg),
                  if (_type == TournamentType.coppa) _buildCoppaConfig(),
                  if (_type == TournamentType.highlander)
                    _buildHighlanderConfig(),
                  Text('Partecipanti (${selected.length}/${members.length})',
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: TotoSpace.sm),
                  TotoCard(
                    padding: EdgeInsets.zero,
                    // ListTile dipinge ink/ripple sul Material più vicino:
                    // senza questo, il DecoratedBox con sfondo di TotoCard
                    // lo nasconde e Flutter lancia un'eccezione a ogni tap.
                    child: Material(
                      type: MaterialType.transparency,
                      child: Column(
                        children: [
                          for (final member in members)
                            CheckboxListTile(
                              title: Text('@${member.username}'),
                              value: selected.contains(member.userId),
                              onChanged: (checked) => setState(() {
                                if (checked ?? false) {
                                  selected.add(member.userId);
                                } else {
                                  selected.remove(member.userId);
                                }
                              }),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: TotoSpace.xl),
                  FilledButton(
                    onPressed: _isSaving ? null : () => _submit(members),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Crea torneo'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCoppaConfig() {
    return Padding(
      padding: const EdgeInsets.only(bottom: TotoSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Formato', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: TotoSpace.sm),
          TotoSegmented<CoppaFormat>(
            values: CoppaFormat.values,
            labels: (f) => switch (f) {
              CoppaFormat.knockout => 'Eliminazione diretta',
              CoppaFormat.groupsThenKnockout => 'Gironi + eliminazione',
            },
            selected: _coppaFormat,
            onChanged: (f) => setState(() => _coppaFormat = f),
          ),
          if (_coppaFormat == CoppaFormat.groupsThenKnockout) ...[
            const SizedBox(height: TotoSpace.md),
            _Stepper(
              label: 'Partecipanti per girone',
              value: _groupSize,
              min: 3,
              onChanged: (v) => setState(() => _groupSize = v),
            ),
            _Stepper(
              label: 'Qualificati per girone',
              value: _advancePerGroup,
              min: 1,
              onChanged: (v) => setState(() => _advancePerGroup = v),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHighlanderConfig() {
    return Padding(
      padding: const EdgeInsets.only(bottom: TotoSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Stepper(
            label: 'Eliminati per giornata',
            value: _eliminationsPerMatchday,
            min: 1,
            onChanged: (v) => setState(() => _eliminationsPerMatchday = v),
          ),
          const SizedBox(height: TotoSpace.md),
          Text('Ordine criteri di spareggio',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: TotoSpace.xs),
          Text(
            'In caso di parità di punti, si applicano in ordine: chi vince '
            'un criterio si salva. Un pareggio residuo dopo tutti i '
            'criteri è risolto a sorteggio, mostrato esplicitamente.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: context.c.textSecondary),
          ),
          const SizedBox(height: TotoSpace.sm),
          TotoCard(
            padding: EdgeInsets.zero,
            child: Material(
              type: MaterialType.transparency,
              child: Column(
              children: [
                for (var i = 0; i < _tiebreakOrder.length; i++)
                  ListTile(
                    leading: CircleAvatar(
                        radius: 12,
                        child: Text('${i + 1}',
                            style: const TextStyle(fontSize: 12))),
                    title: Text(_tiebreakLabel(_tiebreakOrder[i])),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_upward_rounded),
                          onPressed: i == 0
                              ? null
                              : () => setState(() {
                                    final list = List.of(_tiebreakOrder);
                                    final item = list.removeAt(i);
                                    list.insert(i - 1, item);
                                    _tiebreakOrder = list;
                                  }),
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_downward_rounded),
                          onPressed: i == _tiebreakOrder.length - 1
                              ? null
                              : () => setState(() {
                                    final list = List.of(_tiebreakOrder);
                                    final item = list.removeAt(i);
                                    list.insert(i + 1, item);
                                    _tiebreakOrder = list;
                                  }),
                        ),
                      ],
                    ),
                  ),
              ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _tiebreakLabel(HighlanderTiebreak t) => switch (t) {
        HighlanderTiebreak.earliestSubmission =>
          'Chi ha inviato prima la schedina',
        HighlanderTiebreak.previousMatchdayPoints =>
          'Più punti nella giornata precedente',
        HighlanderTiebreak.seasonExactCount =>
          'Più risultati esatti in stagione',
      };
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.label,
    required this.value,
    required this.onChanged,
    this.min = 0,
  });

  final String label;
  final int value;
  final int min;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: TotoSpace.xxs),
      child: Row(
        children: [
          Expanded(
              child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline_rounded),
            onPressed: value > min ? () => onChanged(value - 1) : null,
          ),
          SizedBox(
            width: 28,
            child: Text('$value',
                textAlign: TextAlign.center,
                style: TotoType.number(16, display: false)),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            onPressed: () => onChanged(value + 1),
          ),
        ],
      ),
    );
  }
}
