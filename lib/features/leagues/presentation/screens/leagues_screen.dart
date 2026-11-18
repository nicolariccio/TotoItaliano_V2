import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/toto_theme.dart';
import '../../../../core/utils/error_snackbar.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/toto_widgets.dart';
import '../../../auth/presentation/providers/current_user_provider.dart';
import '../providers/league_providers.dart';
import '../widgets/league_status_card.dart';

class LeaguesScreen extends ConsumerWidget {
  const LeaguesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaguesAsync = ref.watch(myLeaguesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leghe'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Crea lega',
            onPressed: () => context.push(RoutePaths.leagueCreate),
          ),
        ],
      ),
      body: leaguesAsync.when(
        loading: () => const AppLoadingView(),
        error: (error, stackTrace) => AppErrorView(
          message: 'Non è stato possibile caricare le tue leghe.',
          onRetry: () => ref.invalidate(myLeaguesProvider),
        ),
        data: (leagues) => ListView(
          padding: const EdgeInsets.fromLTRB(
              TotoSpace.lg, TotoSpace.md, TotoSpace.lg, TotoSpace.navClearance),
          children: [
            Text('Le tue leghe', style: theme.textTheme.headlineSmall),
            const SizedBox(height: TotoSpace.lg),
            if (leagues.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: TotoSpace.xl),
                child: AppEmptyView(
                  title: 'Nessuna lega ancora',
                  subtitle:
                      'Crea una lega privata o entra con un invite code.',
                  icon: Icons.groups_outlined,
                ),
              )
            else
              for (var i = 0; i < leagues.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: TotoSpace.md),
                  child: LeagueStatusCard(league: leagues[i]),
                ),
            const SizedBox(height: TotoSpace.sm),
            const _JoinByCodeCard(),
            const SizedBox(height: TotoSpace.lg),
            const _ReferralRow(),
          ],
        ),
      ),
    );
  }
}

class _JoinByCodeCard extends ConsumerStatefulWidget {
  const _JoinByCodeCard();

  @override
  ConsumerState<_JoinByCodeCard> createState() => _JoinByCodeCardState();
}

class _JoinByCodeCardState extends ConsumerState<_JoinByCodeCard> {
  // Il codice invito reale è "TOTO-XXXXX" (vedi CodeGenerator.leagueInviteCode):
  // il prefisso fisso è mostrato come label, le caselle raccolgono solo il
  // suffisso di 5 caratteri che l'utente deve effettivamente digitare.
  static const _suffixLength = 5;

  String _suffix = '';
  bool _isJoining = false;

  Future<void> _submit() async {
    if (_suffix.length != _suffixLength || _isJoining) return;
    setState(() => _isJoining = true);
    try {
      final league = await ref
          .read(leagueRepositoryProvider)
          .joinLeagueByInviteCode('TOTO-${_suffix.toUpperCase()}');
      if (!mounted) return;
      context.push(RoutePaths.leagueDetailPath(league.id));
    } catch (error) {
      if (!mounted) return;
      showFailureSnackBar(context, error);
    } finally {
      if (mounted) setState(() => _isJoining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.c;
    final canSubmit = _suffix.length == _suffixLength && !_isJoining;

    return TotoCard(
      radius: TotoRadius.lg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Entra con codice', style: theme.textTheme.titleMedium),
          const SizedBox(height: TotoSpace.xs),
          Text(
            'Chiedi il codice a chi ha creato la lega.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: TotoSpace.lg),
          Row(
            children: [
              Text('TOTO-', style: TotoType.number(20, color: c.textTertiary)),
              const SizedBox(width: TotoSpace.sm),
              Expanded(
                child: TotoCodeInput(
                  length: _suffixLength,
                  onChanged: (value) => setState(() => _suffix = value),
                  onSubmitted: (_) => _submit(),
                ),
              ),
            ],
          ),
          const SizedBox(height: TotoSpace.lg),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: TextButton(
              onPressed: canSubmit ? _submit : null,
              child: _isJoining
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: c.textPrimary),
                    )
                  : const Text('Entra'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReferralRow extends ConsumerWidget {
  const _ReferralRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final theme = Theme.of(context);
    final c = context.c;

    return TotoCard(
      radius: TotoRadius.lg,
      onTap: user == null
          ? null
          : () async {
              await Clipboard.setData(ClipboardData(text: user.referralCode));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Codice referral "${user.referralCode}" copiato.')));
            },
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: c.brandContainer,
              borderRadius: BorderRadius.circular(TotoRadius.sm),
            ),
            child: Icon(Icons.card_giftcard_rounded, color: c.brand, size: 20),
          ),
          const SizedBox(width: TotoSpace.md),
          Expanded(
            child: Text(
              'Invita un amico · +50 punti per entrambi',
              style: theme.textTheme.bodyLarge,
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: c.textTertiary),
        ],
      ),
    );
  }
}
