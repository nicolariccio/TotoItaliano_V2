import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/toto_theme.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/toto_widgets.dart';
import '../../../admin/presentation/providers/admin_providers.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/providers/auth_repository_provider.dart';
import '../../../auth/presentation/providers/current_user_provider.dart';
import '../../../predictions/domain/entities/prediction.dart';
import '../../domain/profile_stats.dart';
import '../providers/profile_stats_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      body: userAsync.when(
        loading: () => const AppLoadingView(),
        error: (error, stackTrace) => AppErrorView(
          message: 'Non è stato possibile caricare il profilo.',
          onRetry: () => ref.invalidate(currentUserProvider),
        ),
        data: (user) {
          if (user == null) {
            return const AppErrorView(message: 'Devi effettuare l\'accesso.');
          }
          return SafeArea(child: _ProfileContent(user: user));
        },
      ),
    );
  }
}

const Map<PredictionMarket, String> _marketLabels = {
  PredictionMarket.result1x2: '1X2',
  PredictionMarket.goalNoGoal: 'Gol/NoGol',
  PredictionMarket.overUnder25: 'Under/Over 2.5',
  PredictionMarket.exactScore: 'Risultato esatto',
};

class _ProfileContent extends ConsumerWidget {
  const _ProfileContent({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final c = context.c;
    final isGlobalAdmin = ref.watch(isGlobalAdminProvider);
    final statsAsync = ref.watch(profileStatsProvider);
    final stats = statsAsync.valueOrNull ?? const ProfileStats(
      bestMatchdayPoints: 0,
      currentStreak: 0,
      accuracyByMarket: {},
      recentMatchdays: [],
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          TotoSpace.lg, TotoSpace.lg, TotoSpace.lg, TotoSpace.navClearance),
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(RoutePaths.settings),
          ),
        ),
        Center(
          child: Column(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: c.brandFill,
                backgroundImage:
                    user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
                child: user.photoUrl == null
                    ? Text(
                        user.username.isNotEmpty
                            ? user.username[0].toUpperCase()
                            : '?',
                        style: theme.textTheme.headlineMedium
                            ?.copyWith(color: c.textOnPrimary),
                      )
                    : null,
              ),
              const SizedBox(height: TotoSpace.md),
              Text('@${user.username}', style: theme.textTheme.headlineMedium),
              const SizedBox(height: TotoSpace.xxs),
              Text('${user.totalPoints} punti totali',
                  style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
        const SizedBox(height: TotoSpace.x3l),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: TotoSpace.md,
          crossAxisSpacing: TotoSpace.md,
          childAspectRatio: 1.7,
          children: [
            _StatTile(label: 'Pronostici', value: '${user.predictionsCount}'),
            _StatTile(
                label: 'Precisione',
                value: '${(user.successRate * 100).round()}%'),
            _StatTile(
                label: 'Miglior giornata',
                value: '${stats.bestMatchdayPoints}'),
            _StatTile(
                label: 'Serie in corso',
                value: '${stats.currentStreak}',
                color: c.success),
          ],
        ),
        const SizedBox(height: TotoSpace.x3l),
        Text('Precisione per mercato', style: theme.textTheme.titleSmall),
        const SizedBox(height: TotoSpace.lg),
        TotoCard(
          child: Column(
            children: [
              for (final market in PredictionMarket.values) ...[
                TotoAccuracyBar(
                  label: _marketLabels[market]!,
                  value: stats.accuracyByMarket[market] ?? 0,
                  fillColor: market == PredictionMarket.exactScore
                      ? c.gold
                      : null,
                ),
                if (market != PredictionMarket.values.last)
                  const SizedBox(height: TotoSpace.lg),
              ],
            ],
          ),
        ),
        const SizedBox(height: TotoSpace.x3l),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Storico', style: theme.textTheme.titleSmall),
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.transparent,
                minimumSize: Size.zero,
                padding: EdgeInsets.zero,
                foregroundColor: c.brand,
              ),
              onPressed: () => context.push(RoutePaths.predictionHistory),
              child: const Text('Vedi tutto'),
            ),
          ],
        ),
        const SizedBox(height: TotoSpace.sm),
        if (stats.recentMatchdays.isEmpty)
          TotoCard(
            child: Text('Nessuna giornata segnata ancora.',
                style: theme.textTheme.bodyMedium),
          )
        else
          for (var i = 0; i < stats.recentMatchdays.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: TotoSpace.sm),
              child: TotoCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                          'Giornata ${stats.recentMatchdays[i].matchday.number}',
                          style: theme.textTheme.bodyLarge),
                    ),
                    TotoBadge.points(stats.recentMatchdays[i].points),
                  ],
                ),
              ),
            ),
        const SizedBox(height: TotoSpace.x3l),
        Text('Impostazioni', style: theme.textTheme.titleSmall),
        const SizedBox(height: TotoSpace.sm),
        _SettingsGroup(children: [
          _SettingsRow(
            icon: Icons.notifications_outlined,
            label: 'Notifiche',
            onTap: () => context.push(RoutePaths.settings),
          ),
          _SettingsRow(
            icon: Icons.person_outline_rounded,
            label: 'Account e nickname',
            onTap: () => context.push(RoutePaths.settings),
          ),
          _SettingsRow(
            icon: Icons.rule_rounded,
            label: 'Regolamento punti',
            onTap: () => context.push(RoutePaths.settings),
          ),
          _SettingsRow(
            icon: Icons.history_rounded,
            label: 'I miei pronostici',
            onTap: () => context.push(RoutePaths.predictionHistory),
          ),
          if (isGlobalAdmin)
            _SettingsRow(
              icon: Icons.admin_panel_settings_outlined,
              label: 'Gestione admin',
              onTap: () => context.push(RoutePaths.admin),
            ),
        ]),
        const SizedBox(height: TotoSpace.x3l),
        PressScale(
          onTap: () => ref.read(authRepositoryProvider).signOut(),
          child: Container(
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.surfaceFlat,
              borderRadius: BorderRadius.circular(TotoRadius.md),
            ),
            child: Text('Esci',
                style:
                    theme.textTheme.labelLarge?.copyWith(color: c.danger)),
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.c;
    return TotoCard(
      radius: TotoRadius.lg,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: TotoType.number(28, color: color ?? c.textPrimary)),
          const SizedBox(height: TotoSpace.xs),
          Text(label.toUpperCase(), style: theme.textTheme.labelSmall),
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return TotoCard(
      radius: TotoRadius.lg,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1)
              Divider(height: 1, indent: 56, color: c.borderSubtle),
          ],
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow(
      {required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.c;
    return PressScale(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: TotoSpace.lg, vertical: TotoSpace.md),
        child: Row(
          children: [
            Icon(icon, size: 20, color: c.textSecondary),
            const SizedBox(width: TotoSpace.md),
            Expanded(child: Text(label, style: theme.textTheme.bodyLarge)),
            Icon(Icons.chevron_right_rounded, color: c.textTertiary),
          ],
        ),
      ),
    );
  }
}
