import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/toto_theme.dart';
import '../../../../core/utils/error_snackbar.dart';
import '../../../../core/widgets/podium_leaderboard.dart';
import '../../../../core/widgets/ranked_entry.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/toto_widgets.dart';
import '../../../../data/models/league.dart';
import '../../../../data/models/league_member.dart';
import '../../../../data/models/scoring_config.dart';
import '../../../../data/providers/football_data_providers.dart';
import '../../../auth/presentation/providers/current_user_provider.dart';
import '../../../predictions/presentation/controllers/schedina_controller.dart';
import '../../../predictions/presentation/controllers/schedina_state.dart';
import '../../../predictions/presentation/widgets/schedina_row.dart';
import '../providers/league_providers.dart';

enum _LeagueTab { classifica, schedina, gestione }

/// Dettaglio di una lega: classifica e schedina sono entrambe scoperte
/// da qui, non da tab globali — ogni lega ha la sua schedina indipendente
/// (stesso utente può pronosticare diversamente la stessa partita in
/// leghe diverse), quindi il contesto "di quale lega" deve sempre essere
/// esplicito.
class LeagueDetailScreen extends ConsumerStatefulWidget {
  const LeagueDetailScreen({super.key, required this.leagueId, this.initialTab});

  final String leagueId;

  /// 'schedina' per aprire direttamente la tab Schedina (es. dalla CTA
  /// della hero card Home); qualsiasi altro valore o null apre Classifica.
  final String? initialTab;

  @override
  ConsumerState<LeagueDetailScreen> createState() => _LeagueDetailScreenState();
}

class _LeagueDetailScreenState extends ConsumerState<LeagueDetailScreen> {
  late _LeagueTab _tab = widget.initialTab == 'schedina'
      ? _LeagueTab.schedina
      : _LeagueTab.classifica;

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
          final currentUserId = ref.watch(currentUserProvider).valueOrNull?.id;
          final isOwner = currentUserId != null && currentUserId == league.ownerId;
          final tabs = [
            _LeagueTab.classifica,
            _LeagueTab.schedina,
            if (isOwner) _LeagueTab.gestione,
          ];
          final effectiveTab = tabs.contains(_tab) ? _tab : _LeagueTab.classifica;

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
                      values: tabs,
                      labels: (t) => switch (t) {
                        _LeagueTab.classifica => 'Classifica',
                        _LeagueTab.schedina => 'Schedina',
                        _LeagueTab.gestione => 'Gestione',
                      },
                      selected: effectiveTab,
                      onChanged: (t) => setState(() => _tab = t),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: switch (effectiveTab) {
                  _LeagueTab.classifica => _ClassificaTab(leagueId: widget.leagueId),
                  _LeagueTab.schedina => _SchedinaTab(leagueId: widget.leagueId),
                  _LeagueTab.gestione => _GestioneTab(league: league),
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
    final currentUserId = ref.watch(currentUserProvider).valueOrNull?.id;
    return membersAsync.when(
      loading: () => const AppLoadingView(),
      error: (error, stackTrace) => AppErrorView(
        message: 'Non è stato possibile caricare i membri.',
        onRetry: () => ref.invalidate(leagueMembersProvider(leagueId)),
      ),
      data: (members) => PodiumLeaderboard(
        emptyTitle: 'Nessun membro ancora',
        currentUserId: currentUserId,
        entries: [
          for (final member in members)
            RankedEntry(
              id: member.userId,
              username: member.username,
              photoUrl: member.photoUrl,
              points: member.totalPoints,
              last5: member.last5,
              exactCount: member.exactCount,
            ),
        ],
      ),
    );
  }
}

class _SchedinaTab extends ConsumerStatefulWidget {
  const _SchedinaTab({required this.leagueId});

  final String leagueId;

  @override
  ConsumerState<_SchedinaTab> createState() => _SchedinaTabState();
}

class _SchedinaTabState extends ConsumerState<_SchedinaTab> {
  // Una sola riga espansa alla volta, come da handoff: aprirne un'altra
  // richiude la precedente invece di accumulare card aperte in lista.
  String? _expandedMatchId;

  @override
  Widget build(BuildContext context) {
    final leagueId = widget.leagueId;
    final matchdayAsync = ref.watch(currentMatchdayProvider);
    final matchesAsync = ref.watch(currentMatchdayMatchesProvider);
    // Chiave stabile anche prima che la giornata sia caricata: la config
    // di una giornata inesistente ('') torna semplicemente nessuna
    // esclusione, innocuo finché non usiamo il risultato (solo dopo i
    // controlli di isLoading/error più sotto, quando la giornata è certa).
    final excludedMatchIds = ref
            .watch(leagueMatchdayConfigProvider((
              leagueId: leagueId,
              matchdayId: matchdayAsync.valueOrNull?.id ?? '',
            )))
            .valueOrNull
            ?.excludedMatchIds
            .toSet() ??
        const <String>{};
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

    final matches = matchesAsync.value!
        .where((m) => !excludedMatchIds.contains(m.id))
        .toList();
    if (matches.isEmpty) {
      return const AppEmptyView(
        title: 'Nessuna partita in programma',
        subtitle: 'Torna più tardi per la prossima giornata, o chiedi al '
            'proprietario della lega di includere delle partite.',
      );
    }

    final openMatchesCount = matches.where((m) => m.isPredictionOpen).length;
    final bool canSave = openMatchesCount > 0 && !schedina.isSaving;
    final double progress =
        matches.isEmpty ? 0 : schedina.completedCount / matches.length;

    final matchday = matchdayAsync.value!;
    final deadlinePassed = DateTime.now().isAfter(matchday.predictionDeadline);

    return Column(
      children: [
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: TotoSpace.lg),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: c.borderSubtle)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Giornata ${matchday.number}',
                  style: Theme.of(context).textTheme.titleMedium),
              if (!deadlinePassed)
                TotoCountdown(deadline: matchday.predictionDeadline, size: 15)
              else
                TotoBadge.locked(),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(
                TotoSpace.lg, TotoSpace.md, TotoSpace.lg, TotoSpace.sm),
            itemCount: matches.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: TotoSpace.sm),
            itemBuilder: (context, index) {
              final match = matches[index];
              final pick = schedina.picks[match.id] ?? const PickState();
              return SchedinaRow(
                match: match,
                pick: pick,
                controller: controller,
                expanded: _expandedMatchId == match.id,
                onToggle: () => setState(() {
                  _expandedMatchId =
                      _expandedMatchId == match.id ? null : match.id;
                }),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(TotoSpace.lg, TotoSpace.md,
              TotoSpace.lg, TotoSpace.navClearance),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    deadlinePassed
                        ? '${schedina.completedCount} di ${matches.length}'
                        : '${schedina.completedCount} di ${matches.length} · '
                            'chiude fra ${_untilClose(matchday.predictionDeadline)}',
                    style: TotoType.number(13, display: false,
                        color: c.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: TotoSpace.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(TotoRadius.full),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 4,
                  backgroundColor: c.neutralContainer,
                  color: c.brand,
                ),
              ),
              const SizedBox(height: TotoSpace.md),
              SizedBox(
                height: 44,
                child: FilledButton(
                  onPressed: canSave ? () => controller.save(matches) : null,
                  child: schedina.isSaving
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: c.textOnPrimary),
                        )
                      : const Text('Conferma'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Es. "2h 47m" — usato nella barra persistente sopra la bottom nav,
  /// più compatto del countdown a cifre della testata.
  String _untilClose(DateTime deadline) {
    final left = deadline.difference(DateTime.now());
    if (left.isNegative) return '0m';
    final hours = left.inHours;
    final minutes = left.inMinutes.remainder(60);
    return hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';
  }
}

/// Pannello di gestione della lega, visibile solo al proprietario: punteggi
/// personalizzati, quali partite della giornata corrente contano per questa
/// lega, e rimozione membri. Ispirato agli strumenti di gestione lega di
/// totoamici.net.
class _GestioneTab extends ConsumerWidget {
  const _GestioneTab({required this.league});

  final League league;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
          TotoSpace.lg, TotoSpace.md, TotoSpace.lg, TotoSpace.navClearance),
      children: [
        Text('Punteggi', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: TotoSpace.sm),
        _ScoringConfigCard(league: league),
        const SizedBox(height: TotoSpace.lg),
        Text('Partite di questa giornata',
            style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: TotoSpace.sm),
        _MatchdaySelectionCard(leagueId: league.id),
        const SizedBox(height: TotoSpace.lg),
        Text('Membri', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: TotoSpace.sm),
        _MemberManagementList(leagueId: league.id),
      ],
    );
  }
}

class _ScoringConfigCard extends ConsumerStatefulWidget {
  const _ScoringConfigCard({required this.league});

  final League league;

  @override
  ConsumerState<_ScoringConfigCard> createState() => _ScoringConfigCardState();
}

class _ScoringConfigCardState extends ConsumerState<_ScoringConfigCard> {
  late ScoringConfig _config;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _config = widget.league.scoringConfig ?? const ScoringConfig();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await ref
          .read(leagueRepositoryProvider)
          .updateScoringConfig(widget.league.id, _config);
      ref.invalidate(leagueByIdProvider(widget.league.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Punteggi aggiornati.')));
      }
    } catch (error) {
      if (mounted) showFailureSnackBar(context, error);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TotoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ScoringStepper(
            label: 'Risultato esatto',
            value: _config.exactScorePoints,
            onChanged: (v) =>
                setState(() => _config = _config.copyWith(exactScorePoints: v)),
          ),
          _ScoringStepper(
            label: '1X2',
            value: _config.resultPoints,
            onChanged: (v) =>
                setState(() => _config = _config.copyWith(resultPoints: v)),
          ),
          _ScoringStepper(
            label: 'Gol/No Gol',
            value: _config.goalNoGoalPoints,
            onChanged: (v) =>
                setState(() => _config = _config.copyWith(goalNoGoalPoints: v)),
          ),
          _ScoringStepper(
            label: 'Under/Over 2.5',
            value: _config.overUnderPoints,
            onChanged: (v) =>
                setState(() => _config = _config.copyWith(overUnderPoints: v)),
          ),
          const SizedBox(height: TotoSpace.sm),
          FilledButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Salva punteggi'),
          ),
        ],
      ),
    );
  }
}

class _ScoringStepper extends StatelessWidget {
  const _ScoringStepper(
      {required this.label, required this.value, required this.onChanged});

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: TotoSpace.xxs),
      child: Row(
        children: [
          Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline_rounded),
            onPressed: value > 0 ? () => onChanged(value - 1) : null,
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

class _MatchdaySelectionCard extends ConsumerWidget {
  const _MatchdaySelectionCard({required this.leagueId});

  final String leagueId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchdayAsync = ref.watch(currentMatchdayProvider);
    final matchesAsync = ref.watch(currentMatchdayMatchesProvider);

    if (matchdayAsync.isLoading || matchesAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final matchday = matchdayAsync.valueOrNull;
    final matches = matchesAsync.valueOrNull;
    if (matchday == null || matches == null || matches.isEmpty) {
      return const TotoCard(child: Text('Nessuna partita in programma.'));
    }

    final key = (leagueId: leagueId, matchdayId: matchday.id);
    final configAsync = ref.watch(leagueMatchdayConfigProvider(key));
    final excluded =
        configAsync.valueOrNull?.excludedMatchIds.toSet() ?? const <String>{};

    Future<void> toggle(String matchId, bool include) async {
      final newExcluded = {...excluded};
      if (include) {
        newExcluded.remove(matchId);
      } else {
        newExcluded.add(matchId);
      }
      try {
        await ref
            .read(leagueRepositoryProvider)
            .setExcludedMatches(leagueId, matchday.id, newExcluded.toList());
      } catch (error) {
        if (context.mounted) showFailureSnackBar(context, error);
      }
    }

    return TotoCard(
      child: Column(
        children: [
          for (final match in matches)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('${match.homeTeam.shortName} - ${match.awayTeam.shortName}',
                  style: Theme.of(context).textTheme.bodyMedium),
              value: !excluded.contains(match.id),
              onChanged: (include) => toggle(match.id, include),
            ),
        ],
      ),
    );
  }
}

class _MemberManagementList extends ConsumerWidget {
  const _MemberManagementList({required this.leagueId});

  final String leagueId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(leagueMembersProvider(leagueId));
    final currentUserId = ref.watch(currentUserProvider).valueOrNull?.id;

    return membersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => const Text('Non è stato possibile caricare i membri.'),
      data: (members) => Column(
        children: [
          for (final member in members)
            Padding(
              padding: const EdgeInsets.only(bottom: TotoSpace.sm),
              child: TotoCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Text('@${member.username}',
                          style: Theme.of(context).textTheme.bodyMedium),
                    ),
                    if (member.role == LeagueMemberRole.owner)
                      const TotoBadge('Proprietario', uppercase: false)
                    else if (member.userId != currentUserId)
                      IconButton(
                        icon: const Icon(Icons.person_remove_outlined),
                        tooltip: 'Rimuovi dalla lega',
                        onPressed: () => _confirmRemove(context, ref, member),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmRemove(
      BuildContext context, WidgetRef ref, LeagueMember member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rimuovere il membro?'),
        content: Text('@${member.username} non farà più parte di questa lega.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annulla')),
          FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Rimuovi')),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await ref
          .read(leagueRepositoryProvider)
          .removeMember(leagueId, member.userId);
    } catch (error) {
      if (context.mounted) showFailureSnackBar(context, error);
    }
  }
}
