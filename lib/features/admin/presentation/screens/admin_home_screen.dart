import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/toto_theme.dart';
import '../../../../core/utils/error_snackbar.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/toto_widgets.dart';
import '../../../../data/constants/serie_a_teams.dart';
import '../../../../data/models/competition.dart';
import '../../../../data/models/matchday.dart';
import '../../../../data/providers/football_data_providers.dart';
import '../providers/admin_providers.dart';

class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(isGlobalAdminProvider);

    if (!isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Gestione')),
        body: const AppErrorView(
            message: 'Non hai i permessi per accedere a questa sezione.'),
      );
    }

    final competitionsAsync = ref.watch(competitionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Gestione admin')),
      body: competitionsAsync.when(
        loading: () => const AppLoadingView(),
        error: (error, stackTrace) => AppErrorView(
          message: 'Non è stato possibile caricare la competizione.',
          onRetry: () => ref.invalidate(competitionsProvider),
        ),
        data: (competitions) {
          if (competitions.isEmpty) return const _CreateCompetitionForm();
          return _CompetitionManagement(competition: competitions.first);
        },
      ),
    );
  }
}

class _CreateCompetitionForm extends ConsumerStatefulWidget {
  const _CreateCompetitionForm();

  @override
  ConsumerState<_CreateCompetitionForm> createState() =>
      _CreateCompetitionFormState();
}

class _CreateCompetitionFormState extends ConsumerState<_CreateCompetitionForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'Serie A');
  final _seasonController = TextEditingController(text: '2026/27');
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _seasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await ref.read(adminRepositoryProvider).createCompetition(
            name: _nameController.text.trim(),
            season: _seasonController.text.trim(),
          );
      ref.invalidate(competitionsProvider);
    } catch (error) {
      if (!mounted) return;
      showFailureSnackBar(context, error);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(TotoSpace.lg),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Nessuna competizione impostata',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: TotoSpace.sm),
            Text(
              'Crea la competizione per iniziare a gestire giornate, '
              'partite e risultati.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: TotoSpace.lg),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nome'),
              validator: (v) => Validators.required(v, field: 'Nome'),
            ),
            const SizedBox(height: TotoSpace.md),
            TextFormField(
              controller: _seasonController,
              decoration: const InputDecoration(labelText: 'Stagione'),
              validator: (v) => Validators.required(v, field: 'Stagione'),
            ),
            const SizedBox(height: TotoSpace.lg),
            FilledButton(
              onPressed: _isSaving ? null : _submit,
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Crea competizione'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompetitionManagement extends ConsumerWidget {
  const _CompetitionManagement({required this.competition});

  final Competition competition;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final theme = Theme.of(context);
    final teamsAsync = ref.watch(teamsProvider);
    final matchdaysAsync = ref.watch(matchdaysProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          TotoSpace.lg, TotoSpace.lg, TotoSpace.lg, TotoSpace.navClearance),
      children: [
        TotoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${competition.name} · ${competition.season}',
                  style: theme.textTheme.titleMedium),
              const SizedBox(height: TotoSpace.xs),
              teamsAsync.when(
                loading: () => const Text('Squadre: caricamento...'),
                error: (e, s) => const Text('Squadre: errore di caricamento'),
                data: (teams) => Row(
                  children: [
                    Text('${teams.length} squadre',
                        style: theme.textTheme.bodyMedium),
                    const Spacer(),
                    if (teams.isEmpty)
                      TextButton(
                        onPressed: () async {
                          try {
                            await ref
                                .read(adminRepositoryProvider)
                                .seedTeams(competition.id, serieATeams);
                            ref.invalidate(teamsProvider);
                          } catch (error) {
                            if (context.mounted) {
                              showFailureSnackBar(context, error);
                            }
                          }
                        },
                        child: const Text('Importa squadre Serie A'),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: TotoSpace.lg),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Giornate', style: theme.textTheme.titleSmall),
            TextButton.icon(
              onPressed: teamsAsync.valueOrNull == null ||
                      teamsAsync.valueOrNull!.isEmpty
                  ? null
                  : () => _createMatchday(context, ref, competition.id,
                      matchdaysAsync.valueOrNull?.length ?? 0),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Nuova giornata'),
            ),
          ],
        ),
        const SizedBox(height: TotoSpace.sm),
        matchdaysAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(TotoSpace.lg),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, s) => const Text('Non è stato possibile caricare le giornate.'),
          data: (matchdays) {
            if (matchdays.isEmpty) {
              return const AppEmptyView(
                  title: 'Nessuna giornata',
                  subtitle: 'Crea la prima giornata per aggiungere partite.');
            }
            return Column(
              children: [
                for (final matchday in matchdays)
                  Padding(
                    padding: const EdgeInsets.only(bottom: TotoSpace.sm),
                    child: TotoCard(
                      onTap: () => context
                          .push(RoutePaths.adminMatchdayPath(matchday.id)),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text('Giornata ${matchday.number}',
                                style: theme.textTheme.titleSmall),
                          ),
                          TotoBadge(
                            switch (matchday.status) {
                              MatchdayStatus.active => 'In corso',
                              MatchdayStatus.finished => 'Conclusa',
                              MatchdayStatus.upcoming => 'Futura',
                            },
                            uppercase: false,
                            tone: matchday.status == MatchdayStatus.active
                                ? TotoBadgeTone.success
                                : TotoBadgeTone.neutral,
                          ),
                          const SizedBox(width: TotoSpace.xs),
                          Icon(Icons.chevron_right_rounded, color: c.textTertiary),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Future<void> _createMatchday(BuildContext context, WidgetRef ref,
      String competitionId, int existingCount) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 7)),
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365)),
      helpText: 'Data del primo calcio d\'inizio',
    );
    if (date == null || !context.mounted) return;

    final matchdayId = await ref.read(adminRepositoryProvider).createMatchday(
          competitionId: competitionId,
          number: existingCount + 1,
          startDate: date.subtract(const Duration(hours: 1)),
          endDate: date.add(const Duration(days: 3)),
          predictionDeadline: date,
        );
    ref.invalidate(matchdaysProvider);
    if (context.mounted) {
      await context.push(RoutePaths.adminMatchdayPath(matchdayId));
    }
  }
}
