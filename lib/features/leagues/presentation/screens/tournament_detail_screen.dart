import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/toto_theme.dart';
import '../../../../core/utils/error_snackbar.dart';
import '../../../../core/widgets/podium_leaderboard.dart';
import '../../../../core/widgets/ranked_entry.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/toto_widgets.dart';
import '../../../../data/models/league_tournament.dart';
import '../../../../data/models/tournament_bracket_tie.dart';
import '../../../../data/models/tournament_group.dart';
import '../../../../data/models/tournament_participant.dart';
import '../../../../data/providers/football_data_providers.dart';
import '../../../auth/presentation/providers/current_user_provider.dart';
import '../providers/league_providers.dart';
import '../providers/tournament_providers.dart';

/// Dettaglio di un torneo di lega: rendering completamente diverso per
/// [TournamentType], come da piano approvato — Campionato riusa
/// [PodiumLeaderboard], Highlander mostra attivi/eliminati con anteprima
/// prima di confermare l'eliminazione, Coppa mostra gironi e/o tabellone
/// verticale (illeggibile a 390px in orizzontale).
class TournamentDetailScreen extends ConsumerWidget {
  const TournamentDetailScreen(
      {super.key, required this.leagueId, required this.tournamentId});

  final String leagueId;
  final String tournamentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = (leagueId: leagueId, tournamentId: tournamentId);
    final tournamentAsync = ref.watch(tournamentByIdProvider(key));

    return Scaffold(
      appBar: AppBar(title: Text(tournamentAsync.value?.name ?? 'Torneo')),
      body: tournamentAsync.when(
        loading: () => const AppLoadingView(),
        error: (error, stackTrace) => AppErrorView(
          message: 'Non è stato possibile caricare il torneo.',
          onRetry: () => ref.invalidate(tournamentByIdProvider(key)),
        ),
        data: (tournament) {
          if (tournament == null) {
            return const AppErrorView(message: 'Torneo non trovato.');
          }
          final leagueAsync = ref.watch(leagueByIdProvider(leagueId));
          final currentUserId =
              ref.watch(currentUserProvider).valueOrNull?.id;
          final isOwner = currentUserId != null &&
              currentUserId == leagueAsync.value?.ownerId;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    TotoSpace.lg, TotoSpace.md, TotoSpace.lg, TotoSpace.sm),
                child: Row(
                  children: [
                    _typeBadge(tournament.type),
                    const SizedBox(width: TotoSpace.sm),
                    _statusBadge(tournament.status),
                  ],
                ),
              ),
              Expanded(
                child: switch (tournament.type) {
                  TournamentType.campionato => _CampionatoBody(
                      leagueId: leagueId,
                      tournament: tournament,
                      isOwner: isOwner,
                      currentUserId: currentUserId),
                  TournamentType.highlander => _HighlanderBody(
                      leagueId: leagueId,
                      tournament: tournament,
                      isOwner: isOwner),
                  TournamentType.coppa => _CoppaBody(
                      leagueId: leagueId,
                      tournament: tournament,
                      isOwner: isOwner),
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _typeBadge(TournamentType type) => TotoBadge(
        switch (type) {
          TournamentType.campionato => 'Campionato',
          TournamentType.coppa => 'Coppa',
          TournamentType.highlander => 'Highlander',
        },
        tone: TotoBadgeTone.brand,
        uppercase: false,
      );

  Widget _statusBadge(TournamentStatus status) => TotoBadge(
        switch (status) {
          TournamentStatus.upcoming => 'In arrivo',
          TournamentStatus.active => 'In corso',
          TournamentStatus.finished => 'Conclusa',
        },
        tone: switch (status) {
          TournamentStatus.upcoming => TotoBadgeTone.neutral,
          TournamentStatus.active => TotoBadgeTone.success,
          TournamentStatus.finished => TotoBadgeTone.gold,
        },
        uppercase: false,
      );
}

class _CampionatoBody extends ConsumerWidget {
  const _CampionatoBody({
    required this.leagueId,
    required this.tournament,
    required this.isOwner,
    required this.currentUserId,
  });

  final String leagueId;
  final LeagueTournament tournament;
  final bool isOwner;
  final String? currentUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = (leagueId: leagueId, tournamentId: tournament.id);
    final participantsAsync = ref.watch(tournamentParticipantsProvider(key));

    return participantsAsync.when(
      loading: () => const AppLoadingView(),
      error: (error, stackTrace) => AppErrorView(
        message: 'Non è stato possibile caricare la classifica.',
        onRetry: () => ref.invalidate(tournamentParticipantsProvider(key)),
      ),
      data: (participants) => Column(
        children: [
          Expanded(
            child: PodiumLeaderboard(
              currentUserId: currentUserId,
              emptyTitle: 'Nessun partecipante',
              entries: [
                for (final p in participants)
                  RankedEntry(
                      id: p.userId,
                      username: p.username,
                      photoUrl: p.photoUrl,
                      points: p.points),
              ],
            ),
          ),
          if (isOwner)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  TotoSpace.lg, 0, TotoSpace.lg, TotoSpace.navClearance),
              child: FilledButton(
                onPressed: () => _refresh(context, ref),
                child: const Text('Aggiorna classifica'),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _refresh(BuildContext context, WidgetRef ref) async {
    try {
      final matchdays = await ref.read(matchdaysProvider.future);
      final startNumber = tournament.createdFromMatchdayId == null
          ? null
          : matchdays
              .firstWhere(
                  (m) => m.id == tournament.createdFromMatchdayId,
                  orElse: () => matchdays.first)
              .number;
      final matchdayIds = [
        for (final m in matchdays)
          if (startNumber == null || m.number >= startNumber) m.id,
      ];
      await ref.read(tournamentRepositoryProvider).refreshCampionatoStandings(
            leagueId: leagueId,
            tournamentId: tournament.id,
            matchdayIds: matchdayIds,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Classifica aggiornata.')));
      }
    } catch (error) {
      if (context.mounted) showFailureSnackBar(context, error);
    }
  }
}

class _HighlanderBody extends ConsumerStatefulWidget {
  const _HighlanderBody(
      {required this.leagueId, required this.tournament, required this.isOwner});

  final String leagueId;
  final LeagueTournament tournament;
  final bool isOwner;

  @override
  ConsumerState<_HighlanderBody> createState() => _HighlanderBodyState();
}

class _HighlanderBodyState extends ConsumerState<_HighlanderBody> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final key =
        (leagueId: widget.leagueId, tournamentId: widget.tournament.id);
    final participantsAsync = ref.watch(tournamentParticipantsProvider(key));
    final c = context.c;

    return participantsAsync.when(
      loading: () => const AppLoadingView(),
      error: (error, stackTrace) => AppErrorView(
        message: 'Non è stato possibile caricare i partecipanti.',
        onRetry: () => ref.invalidate(tournamentParticipantsProvider(key)),
      ),
      data: (participants) {
        final active = participants.where((p) => p.active).toList()
          ..sort((a, b) => b.points.compareTo(a.points));
        final eliminated = participants.where((p) => !p.active).toList();

        return Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(TotoSpace.lg,
                    TotoSpace.md, TotoSpace.lg, TotoSpace.navClearance),
                children: [
                  Text('In gara (${active.length})',
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: TotoSpace.sm),
                  for (final p in active)
                    Padding(
                      padding: const EdgeInsets.only(bottom: TotoSpace.sm),
                      child: TotoCard(
                        child: Row(
                          children: [
                            Expanded(child: Text('@${p.username}')),
                            Text('${p.points} pt',
                                style: TotoType.number(15,
                                    display: false, color: c.textSecondary)),
                          ],
                        ),
                      ),
                    ),
                  if (eliminated.isNotEmpty) ...[
                    const SizedBox(height: TotoSpace.lg),
                    Text('Eliminati (${eliminated.length})',
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: TotoSpace.sm),
                    for (final p in eliminated)
                      Padding(
                        padding: const EdgeInsets.only(bottom: TotoSpace.sm),
                        child: TotoCard(
                          child: Row(
                            children: [
                              Expanded(child: Text('@${p.username}')),
                              const TotoBadge('Eliminato',
                                  tone: TotoBadgeTone.danger,
                                  dense: true,
                                  uppercase: false),
                            ],
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
            if (widget.isOwner &&
                widget.tournament.status != TournamentStatus.finished)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    TotoSpace.lg, 0, TotoSpace.lg, TotoSpace.navClearance),
                child: FilledButton(
                  onPressed:
                      _isProcessing ? null : () => _elaboraGiornata(active),
                  child: _isProcessing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Elabora giornata'),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _elaboraGiornata(List<TournamentParticipant> active) async {
    setState(() => _isProcessing = true);
    try {
      final matchday = await ref.read(currentMatchdayProvider.future);
      final preview =
          await ref.read(tournamentRepositoryProvider).previewHighlanderMatchday(
                leagueId: widget.leagueId,
                tournamentId: widget.tournament.id,
                matchdayId: matchday.id,
              );
      if (!mounted) return;
      setState(() => _isProcessing = false);

      if (preview.eliminatedUserIds.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:
                Text('Nessun punteggio di giornata disponibile ancora.')));
        return;
      }

      final usernameById = {for (final p in active) p.userId: p.username};
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Confermi l'eliminazione?"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Giornata ${matchday.number} — verranno eliminati:'),
              const SizedBox(height: TotoSpace.sm),
              for (final id in preview.eliminatedUserIds)
                Text(
                    '• @${usernameById[id] ?? id} (${preview.pointsByUser[id] ?? 0} pt)'),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Annulla')),
            FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Confermo')),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;

      setState(() => _isProcessing = true);
      await ref.read(tournamentRepositoryProvider).confirmHighlanderMatchday(
            leagueId: widget.leagueId,
            tournamentId: widget.tournament.id,
            preview: preview,
          );
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Giornata elaborata.')));
      }
    } catch (error) {
      if (mounted) showFailureSnackBar(context, error);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }
}

class _CoppaBody extends ConsumerStatefulWidget {
  const _CoppaBody(
      {required this.leagueId, required this.tournament, required this.isOwner});

  final String leagueId;
  final LeagueTournament tournament;
  final bool isOwner;

  @override
  ConsumerState<_CoppaBody> createState() => _CoppaBodyState();
}

class _CoppaBodyState extends ConsumerState<_CoppaBody> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final tournament = widget.tournament;
    final showGroups = tournament.coppaFormat == CoppaFormat.groupsThenKnockout &&
        tournament.phase == CoppaPhase.groups;

    return showGroups ? _buildGroups(context) : _buildBracket(context);
  }

  Widget _buildGroups(BuildContext context) {
    final key =
        (leagueId: widget.leagueId, tournamentId: widget.tournament.id);
    final groupsAsync = ref.watch(tournamentGroupsProvider(key));
    final participantsAsync = ref.watch(tournamentParticipantsProvider(key));

    if (groupsAsync.isLoading || participantsAsync.isLoading) {
      return const AppLoadingView();
    }
    if (groupsAsync.hasError) {
      return AppErrorView(
        message: 'Non è stato possibile caricare i gironi.',
        onRetry: () => ref.invalidate(tournamentGroupsProvider(key)),
      );
    }
    final groups = groupsAsync.value ?? const <TournamentGroup>[];
    final participants = participantsAsync.value ?? const <TournamentParticipant>[];
    final usernameById = {for (final p in participants) p.userId: p.username};
    final advancePerGroup = widget.tournament.advancePerGroup ?? 2;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
                TotoSpace.lg, TotoSpace.md, TotoSpace.lg, TotoSpace.navClearance),
            children: [
              for (final group in groups)
                _GroupCard(
                    group: group,
                    usernameById: usernameById,
                    advancePerGroup: advancePerGroup),
            ],
          ),
        ),
        if (widget.isOwner) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(
                TotoSpace.lg, 0, TotoSpace.lg, TotoSpace.sm),
            child: OutlinedButton(
              onPressed: _isProcessing ? null : _elaboraGiornataGironi,
              child: const Text('Elabora giornata gironi'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                TotoSpace.lg, 0, TotoSpace.lg, TotoSpace.navClearance),
            child: FilledButton(
              onPressed: _isProcessing ? null : _chiudiGironi,
              child: const Text('Chiudi fase a gironi e genera tabellone'),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _elaboraGiornataGironi() async {
    setState(() => _isProcessing = true);
    try {
      final matchday = await ref.read(currentMatchdayProvider.future);
      await ref.read(tournamentRepositoryProvider).processGroupsMatchday(
            leagueId: widget.leagueId,
            tournamentId: widget.tournament.id,
            matchdayId: matchday.id,
          );
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Giornata elaborata.')));
      }
    } catch (error) {
      if (mounted) showFailureSnackBar(context, error);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _chiudiGironi() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chiudere la fase a gironi?'),
        content: const Text(
            "I migliori di ogni girone passano al tabellone a eliminazione diretta. L'azione non è reversibile."),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annulla')),
          FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Chiudi e genera')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isProcessing = true);
    try {
      await ref
          .read(tournamentRepositoryProvider)
          .closeGroupsPhaseAndSeedBracket(
            leagueId: widget.leagueId,
            tournamentId: widget.tournament.id,
          );
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Tabellone generato.')));
      }
    } catch (error) {
      if (mounted) showFailureSnackBar(context, error);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Widget _buildBracket(BuildContext context) {
    final key =
        (leagueId: widget.leagueId, tournamentId: widget.tournament.id);
    final bracketAsync = ref.watch(tournamentBracketProvider(key));
    final participantsAsync = ref.watch(tournamentParticipantsProvider(key));

    if (bracketAsync.isLoading || participantsAsync.isLoading) {
      return const AppLoadingView();
    }
    if (bracketAsync.hasError) {
      return AppErrorView(
        message: 'Non è stato possibile caricare il tabellone.',
        onRetry: () => ref.invalidate(tournamentBracketProvider(key)),
      );
    }
    final ties = bracketAsync.value ?? const <BracketTie>[];
    final participants = participantsAsync.value ?? const <TournamentParticipant>[];
    final usernameById = {for (final p in participants) p.userId: p.username};

    if (ties.isEmpty) {
      return const AppEmptyView(title: 'Tabellone non ancora generato');
    }

    final rounds = <int, List<BracketTie>>{};
    for (final tie in ties) {
      rounds.putIfAbsent(tie.round, () => []).add(tie);
    }
    final roundNumbers = rounds.keys.toList()..sort();
    // Il numero di turni totali va calcolato dal turno 1 (sempre quello
    // reale degli iscritti al tabellone, sia in knockout puro sia dopo i
    // gironi), non dall'ultimo turno già generato: la finale non esiste
    // ancora finché la semifinale non è risolta, altrimenti quest'ultima
    // verrebbe etichettata erroneamente "Finale".
    final totalRounds = _totalRoundsFromFirstRoundTieCount(
        rounds[1]?.length ?? roundNumbers.length);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          TotoSpace.lg, TotoSpace.md, TotoSpace.lg, TotoSpace.navClearance),
      children: [
        for (final round in roundNumbers) ...[
          Text(_roundLabel(round, totalRounds),
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: TotoSpace.sm),
          for (final tie in rounds[round]!..sort((a, b) => a.slot.compareTo(b.slot)))
            Padding(
              padding: const EdgeInsets.only(bottom: TotoSpace.sm),
              child: _TieCard(
                tie: tie,
                usernameById: usernameById,
                isOwner: widget.isOwner,
                onAssignMatchday: () => _assignMatchday(round),
                onResolveRound: () => _resolveRound(round),
              ),
            ),
          const SizedBox(height: TotoSpace.md),
        ],
      ],
    );
  }

  /// Numero di turni totali di un tabellone il cui turno 1 ha
  /// [round1TieCount] incontri: per costruzione (vedi
  /// [TournamentScoring.generateFirstRound]) è sempre una potenza di 2,
  /// quindi basta risalire a log2 + 1 — funziona sia per la Coppa
  /// knockout pura (turno 1 = tutti i partecipanti) sia per quella con
  /// gironi (turno 1 = solo i qualificati), perché in entrambi i casi il
  /// turno 1 nel tabellone è sempre quello reale.
  int _totalRoundsFromFirstRoundTieCount(int round1TieCount) {
    var ties = round1TieCount <= 0 ? 1 : round1TieCount;
    var rounds = 1;
    while (ties > 1) {
      ties ~/= 2;
      rounds++;
    }
    return rounds;
  }

  String _roundLabel(int round, int totalRounds) {
    if (round == totalRounds) return 'Finale';
    if (round == totalRounds - 1) return 'Semifinale';
    if (round == totalRounds - 2) return 'Quarti di finale';
    return 'Turno $round';
  }

  Future<void> _assignMatchday(int round) async {
    setState(() => _isProcessing = true);
    try {
      final matchday = await ref.read(currentMatchdayProvider.future);
      await ref.read(tournamentRepositoryProvider).assignMatchdayToRound(
            leagueId: widget.leagueId,
            tournamentId: widget.tournament.id,
            round: round,
            matchdayId: matchday.id,
          );
    } catch (error) {
      if (mounted) showFailureSnackBar(context, error);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _resolveRound(int round) async {
    setState(() => _isProcessing = true);
    try {
      await ref.read(tournamentRepositoryProvider).resolveBracketRound(
            leagueId: widget.leagueId,
            tournamentId: widget.tournament.id,
            round: round,
          );
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Turno risolto.')));
      }
    } catch (error) {
      if (mounted) showFailureSnackBar(context, error);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard(
      {required this.group, required this.usernameById, required this.advancePerGroup});

  final TournamentGroup group;
  final Map<String, String> usernameById;
  final int advancePerGroup;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final ranked = [...group.participantUserIds]
      ..sort((a, b) =>
          (group.cumulativePoints[b] ?? 0).compareTo(group.cumulativePoints[a] ?? 0));

    return Padding(
      padding: const EdgeInsets.only(bottom: TotoSpace.md),
      child: TotoCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Girone ${group.id}', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: TotoSpace.sm),
            for (var i = 0; i < ranked.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: TotoSpace.xxs),
                child: Row(
                  children: [
                    Expanded(
                        child:
                            Text('@${usernameById[ranked[i]] ?? ranked[i]}')),
                    if (i < advancePerGroup)
                      const Padding(
                        padding: EdgeInsets.only(right: TotoSpace.sm),
                        child: TotoBadge('Qualificato',
                            tone: TotoBadgeTone.success,
                            dense: true,
                            uppercase: false),
                      ),
                    Text('${group.cumulativePoints[ranked[i]] ?? 0} pt',
                        style: TotoType.number(14,
                            display: false, color: c.textSecondary)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TieCard extends StatelessWidget {
  const _TieCard({
    required this.tie,
    required this.usernameById,
    required this.isOwner,
    required this.onAssignMatchday,
    required this.onResolveRound,
  });

  final BracketTie tie;
  final Map<String, String> usernameById;
  final bool isOwner;
  final VoidCallback onAssignMatchday;
  final VoidCallback onResolveRound;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final nameA = tie.participantAId == null
        ? '—'
        : '@${usernameById[tie.participantAId] ?? tie.participantAId}';
    final nameB = tie.participantBId == null
        ? (tie.isBye ? 'Bye' : '—')
        : '@${usernameById[tie.participantBId] ?? tie.participantBId}';

    return TotoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(nameA,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: tie.winnerId == tie.participantAId
                            ? FontWeight.w700
                            : FontWeight.w400,
                        color: tie.winnerId == tie.participantAId
                            ? c.success
                            : null)),
              ),
              if (tie.pointsA != null)
                Text('${tie.pointsA}', style: TotoType.number(15, display: false)),
            ],
          ),
          const SizedBox(height: TotoSpace.xxs),
          Row(
            children: [
              Expanded(
                child: Text(nameB,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: tie.winnerId == tie.participantBId
                            ? FontWeight.w700
                            : FontWeight.w400,
                        color: tie.winnerId == tie.participantBId
                            ? c.success
                            : null)),
              ),
              if (tie.pointsB != null)
                Text('${tie.pointsB}', style: TotoType.number(15, display: false)),
            ],
          ),
          if (isOwner && !tie.isBye && !tie.isResolved) ...[
            const SizedBox(height: TotoSpace.sm),
            if (tie.matchdayId == null)
              OutlinedButton(
                  onPressed: onAssignMatchday,
                  child: const Text('Assegna giornata corrente'))
            else
              FilledButton(
                  onPressed: onResolveRound, child: const Text('Risolvi turno')),
          ],
        ],
      ),
    );
  }
}
