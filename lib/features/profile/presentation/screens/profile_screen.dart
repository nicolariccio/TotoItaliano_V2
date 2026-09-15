import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/toto_theme.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/toto_widgets.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/providers/auth_repository_provider.dart';
import '../../../auth/presentation/providers/current_user_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profilo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(RoutePaths.settings),
          ),
        ],
      ),
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
          return _ProfileContent(user: user);
        },
      ),
    );
  }
}

class _ProfileContent extends ConsumerWidget {
  const _ProfileContent({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final c = context.c;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          TotoSpace.lg, TotoSpace.lg, TotoSpace.lg, TotoSpace.navClearance),
      children: [
        Center(
          child: Column(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: c.brandFill,
                backgroundImage:
                    user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
                child: user.photoUrl == null
                    ? Text(
                        user.username.isNotEmpty
                            ? user.username[0].toUpperCase()
                            : '?',
                        style: theme.textTheme.displaySmall
                            ?.copyWith(color: c.textOnPrimary),
                      )
                    : null,
              ),
              const SizedBox(height: TotoSpace.md),
              Text('@${user.username}', style: theme.textTheme.titleLarge),
              Text(user.fullName, style: theme.textTheme.bodyMedium),
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
            _StatTile(label: 'Punti', value: '${user.totalPoints}'),
            _StatTile(label: 'Pronostici', value: '${user.predictionsCount}'),
            _StatTile(
                label: 'Esatti', value: '${user.exactPredictions}', gold: true),
            _StatTile(
                label: 'Successo',
                value: '${(user.successRate * 100).toStringAsFixed(0)}%'),
          ],
        ),
        const SizedBox(height: TotoSpace.md),
        TotoCard(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Codice referral', style: theme.textTheme.bodyMedium),
              Text(user.referralCode,
                  style: TotoType.number(18, display: false, color: c.brand)),
            ],
          ),
        ),
        const SizedBox(height: TotoSpace.md),
        TotoCard(
          onTap: () => context.push(RoutePaths.predictionHistory),
          child: Row(
            children: [
              Icon(Icons.history_rounded, color: c.brand),
              const SizedBox(width: TotoSpace.md),
              Expanded(
                  child: Text('I miei pronostici',
                      style: theme.textTheme.titleSmall)),
              Icon(Icons.chevron_right_rounded, color: c.textTertiary),
            ],
          ),
        ),
        const SizedBox(height: TotoSpace.x3l),
        OutlinedButton.icon(
          onPressed: () => ref.read(authRepositoryProvider).signOut(),
          icon: Icon(Icons.logout_rounded, color: c.danger),
          label: Text('Esci', style: TextStyle(color: c.danger)),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile(
      {required this.label, required this.value, this.gold = false});

  final String label;
  final String value;
  final bool gold;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.c;
    return TotoCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value,
              style: TotoType.number(28, color: gold ? c.gold : c.textPrimary)),
          const SizedBox(height: TotoSpace.xs),
          Text(label, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
