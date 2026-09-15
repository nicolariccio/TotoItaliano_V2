import 'package:flutter/material.dart';

import '../theme/toto_theme.dart';
import 'fade_slide_in.dart';

/// Vista di caricamento standard, da usare al posto di
/// `CircularProgressIndicator()` sparso per l'app.
class AppLoadingView extends StatelessWidget {
  const AppLoadingView({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Center(
      child: FadeSlideIn(
        offset: const Offset(0, 0.02),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child:
                  CircularProgressIndicator(strokeWidth: 2.4, color: c.brand),
            ),
            if (message != null) ...[
              const SizedBox(height: TotoSpace.lg),
              Text(message!, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ],
        ),
      ),
    );
  }
}

/// Vista d'errore con messaggio user-friendly e azione di retry opzionale.
/// Non mostra mai stack trace o dettagli tecnici: passa qui solo il
/// messaggio già mappato da [AppExceptionMapper].
class AppErrorView extends StatelessWidget {
  const AppErrorView({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.c;
    return Center(
      child: FadeSlideIn(
        child: Padding(
          padding: const EdgeInsets.all(TotoSpace.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(TotoSpace.md),
                decoration: BoxDecoration(
                  color: c.dangerContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.error_outline_rounded,
                    color: c.danger, size: 28),
              ),
              const SizedBox(height: TotoSpace.md),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              if (onRetry != null) ...[
                const SizedBox(height: TotoSpace.xl),
                OutlinedButton(
                    onPressed: onRetry, child: const Text('Riprova')),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Vista per liste/stati vuoti (es. "nessun pronostico ancora").
class AppEmptyView extends StatelessWidget {
  const AppEmptyView({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.inbox_rounded,
    this.action,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.c;
    return Center(
      child: FadeSlideIn(
        child: Padding(
          padding: const EdgeInsets.all(TotoSpace.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(TotoSpace.lg),
                decoration: BoxDecoration(
                  color: c.surface2,
                  shape: BoxShape.circle,
                  border: Border.all(color: c.borderSubtle),
                ),
                child: Icon(icon, size: 30, color: c.brand),
              ),
              const SizedBox(height: TotoSpace.xl),
              Text(title,
                  style: theme.textTheme.headlineSmall,
                  textAlign: TextAlign.center),
              if (subtitle != null) ...[
                const SizedBox(height: TotoSpace.sm),
                Text(subtitle!,
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center),
              ],
              if (action != null) ...[
                const SizedBox(height: TotoSpace.xl),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
