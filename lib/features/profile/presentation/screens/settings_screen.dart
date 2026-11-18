import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/notification_settings_provider.dart';
import '../../../../core/theme/toto_theme.dart';
import '../../../../core/widgets/toto_widgets.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final c = context.c;
    final remindersEnabled = ref.watch(schedinaRemindersEnabledProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Impostazioni')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              TotoSpace.lg, TotoSpace.md, TotoSpace.lg, TotoSpace.navClearance),
          children: [
            Text('Notifiche', style: theme.textTheme.titleSmall),
            const SizedBox(height: TotoSpace.sm),
            TotoCard(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Promemoria schedina',
                            style: theme.textTheme.bodyLarge),
                        const SizedBox(height: TotoSpace.xxs),
                        Text(
                          'Un avviso locale sul telefono quando manca un\'ora '
                          'alla chiusura di una schedina non ancora completa. '
                          'Nessun dato lascia il dispositivo.',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: c.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: TotoSpace.md),
                  Switch(
                    value: remindersEnabled,
                    onChanged: (value) => ref
                        .read(schedinaRemindersEnabledProvider.notifier)
                        .setEnabled(value),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
