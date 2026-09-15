// ─────────────────────────────────────────────────────────────────────────────
//  TotoItaliano — Widget di sistema
//  I sei componenti che portano il carattere dell'app. Tutto il resto può
//  restare Material standard, perché il tema lo veste già.
//
//  Richiede toto_theme.dart.
//  Nota: `withValues(alpha:)` richiede Flutter ≥ 3.27. Su versioni precedenti
//  sostituisci con `withOpacity(...)`.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/toto_theme.dart';

// ═════════════════════════════════════════════════════════════════════════════
//  1. PRESS SCALE — feedback tattile su qualsiasi cosa toccabile
//     Regola: lo scale non sposta il layout, quindi è sempre sicuro.
// ═════════════════════════════════════════════════════════════════════════════

class PressScale extends StatefulWidget {
  const PressScale({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.97,
    this.haptic = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final bool haptic;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => setState(() => _down = true) : null,
      onTapCancel: enabled ? () => setState(() => _down = false) : null,
      onTapUp: enabled ? (_) => setState(() => _down = false) : null,
      onTap: enabled
          ? () {
              if (widget.haptic) HapticFeedback.selectionClick();
              widget.onTap!.call();
            }
          : null,
      child: AnimatedScale(
        scale: _down && !context.reducedMotion ? widget.scale : 1.0,
        duration: TotoMotion.instant,
        curve: TotoMotion.standard,
        child: widget.child,
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  2. CARD — tre livelli. La visibilità della card scala con la sua
//     interattività: più una superficie è toccabile, più deve staccarsi.
// ═════════════════════════════════════════════════════════════════════════════

enum TotoCardLevel {
  /// Raggruppamento non interattivo: niente riempimento, solo spazio.
  flat,

  /// Riga/card toccabile: riempimento + hairline.
  interactive,

  /// Card hero, sheet, elemento in evidenza: gradiente + edge speculare.
  elevated,
}

class TotoCard extends StatelessWidget {
  const TotoCard({
    super.key,
    required this.child,
    this.level = TotoCardLevel.interactive,
    this.onTap,
    this.padding = const EdgeInsets.all(TotoSpace.lg),
    this.radius = TotoRadius.lg,
    this.accent,
  });

  final Widget child;
  final TotoCardLevel level;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final double radius;

  /// Se valorizzato, sostituisce il bordo con una tinta di stato
  /// (es. oro per un risultato esatto, verde per un pronostico vinto).
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    final decoration = switch (level) {
      TotoCardLevel.flat => BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
        ),
      TotoCardLevel.interactive => BoxDecoration(
          color: c.surface1,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: accent ?? c.borderSubtle),
        ),
      TotoCardLevel.elevated => BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [c.surface2, c.surface1],
          ),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: accent ?? c.specular),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
    };

    final body = AnimatedContainer(
      duration: TotoMotion.fast,
      curve: TotoMotion.standard,
      decoration: decoration,
      padding: padding,
      child: child,
    );

    return onTap == null ? body : PressScale(onTap: onTap, child: body);
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  3. BADGE / PILL DI STATO
//     Regola ferrea: mai solo colore. Ogni variante porta icona o forma.
// ═════════════════════════════════════════════════════════════════════════════

enum TotoBadgeTone { neutral, brand, success, danger, warning, gold }

class TotoBadge extends StatelessWidget {
  const TotoBadge(
    this.label, {
    super.key,
    this.tone = TotoBadgeTone.neutral,
    this.icon,
    this.dense = false,
    this.uppercase = true,
    this.pulsing = false,
  });

  /// "LOCKED" — pronostici chiusi.
  const TotoBadge.locked({super.key})
      : label = 'CHIUSA',
        tone = TotoBadgeTone.neutral,
        icon = Icons.lock_rounded,
        dense = false,
        uppercase = true,
        pulsing = false;

  /// "LIVE" — partita in corso, con pallino pulsante.
  const TotoBadge.live({super.key})
      : label = 'LIVE',
        tone = TotoBadgeTone.danger,
        icon = null,
        dense = false,
        uppercase = true,
        pulsing = true;

  /// "+10" — punti assegnati. Cifre tabulari, segno sempre esplicito.
  factory TotoBadge.points(int points, {Key? key, bool jackpot = false}) {
    return TotoBadge(
      '${points >= 0 ? '+' : ''}$points',
      key: key,
      tone: jackpot
          ? TotoBadgeTone.gold
          : (points > 0 ? TotoBadgeTone.success : TotoBadgeTone.neutral),
      icon: jackpot
          ? Icons.star_rounded
          : (points > 0 ? Icons.check_rounded : null),
      uppercase: false,
    );
  }

  final String label;
  final TotoBadgeTone tone;
  final IconData? icon;
  final bool dense;
  final bool uppercase;
  final bool pulsing;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    final (Color fg, Color bg, Color border) = switch (tone) {
      TotoBadgeTone.neutral => (
          c.textSecondary,
          c.neutralContainer,
          c.neutralBorder
        ),
      TotoBadgeTone.brand => (
          c.brand,
          c.brandContainer,
          c.brand.withValues(alpha: 0.35)
        ),
      TotoBadgeTone.success => (c.success, c.successContainer, c.successBorder),
      TotoBadgeTone.danger => (c.danger, c.dangerContainer, c.dangerBorder),
      TotoBadgeTone.warning => (c.warning, c.warningContainer, c.warningBorder),
      TotoBadgeTone.gold => (
          c.gold,
          c.goldContainer,
          c.gold.withValues(alpha: 0.40)
        ),
    };

    final style = (uppercase
            ? Theme.of(context).textTheme.labelSmall!
            : Theme.of(context).textTheme.labelMedium!)
        .copyWith(
      color: fg,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return Container(
      height: dense ? 22 : 26,
      padding: EdgeInsets.symmetric(horizontal: dense ? TotoSpace.sm : 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(TotoRadius.full),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (pulsing) ...[
            _PulsingDot(color: fg),
            const SizedBox(width: TotoSpace.xs + 2),
          ] else if (icon != null) ...[
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: TotoSpace.xs + 1),
          ],
          Text(uppercase ? label.toUpperCase() : label, style: style),
        ],
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot({required this.color});
  final Color color;

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void initState() {
    super.initState();
    _ctrl.repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
    );
    // Animiamo solo l'opacità: nessun reflow, e si spegne con "Riduci movimento".
    if (context.reducedMotion) return dot;
    return FadeTransition(
      opacity: Tween<double>(begin: 1.0, end: 0.35).animate(_ctrl),
      child: dot,
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  4. COUNTDOWN
//     Sottoalbero isolato: il tick al secondo ridisegna SOLO questo widget,
//     non l'intera Home. Cifre tabulari in box a larghezza fissa → niente
//     "ballo" dei numeri.
// ═════════════════════════════════════════════════════════════════════════════

class TotoCountdown extends StatefulWidget {
  const TotoCountdown({
    super.key,
    required this.deadline,
    this.size = 36,
    this.onExpired,
  });

  final DateTime deadline;
  final double size;
  final VoidCallback? onExpired;

  @override
  State<TotoCountdown> createState() => _TotoCountdownState();
}

class _TotoCountdownState extends State<TotoCountdown> {
  Timer? _timer;
  late Duration _left = _compute();

  Duration _compute() {
    final d = widget.deadline.difference(DateTime.now());
    return d.isNegative ? Duration.zero : d;
  }

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final next = _compute();
      if (next == Duration.zero && _left != Duration.zero) {
        widget.onExpired?.call();
      }
      if (mounted) setState(() => _left = next);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    // Il colore è uno stato, non una decorazione.
    final color = switch (_left.inMinutes) {
      <= 15 => c.danger,
      <= 120 => c.warning,
      _ => c.textPrimary,
    };

    String two(int n) => n.toString().padLeft(2, '0');
    final h = two(_left.inHours);
    final m = two(_left.inMinutes.remainder(60));
    final s = two(_left.inSeconds.remainder(60));

    final numStyle = TotoType.number(widget.size, color: color);
    final sepStyle = numStyle.copyWith(
      color: color.withValues(alpha: 0.35),
      fontWeight: FontWeight.w400,
    );

    return Semantics(
      liveRegion: _left.inMinutes <= 15,
      label: 'Chiusura pronostici fra $h ore, $m minuti e $s secondi',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(h, style: numStyle),
          Text(':', style: sepStyle),
          Text(m, style: numStyle),
          Text(':', style: sepStyle),
          Text(s, style: numStyle),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  5. SELETTORE DI MERCATO
//     Principio: il cromo neutro sceglie la DOMANDA (quale mercato),
//     il blu brand sceglie la RISPOSTA (quale valore).
//     Così il blu in pagina misura quanto hai compilato.
// ═════════════════════════════════════════════════════════════════════════════

class TotoSegmented<T> extends StatelessWidget {
  const TotoSegmented({
    super.key,
    required this.values,
    required this.labels,
    required this.selected,
    required this.onChanged,
  });

  final List<T> values;
  final String Function(T) labels;
  final T? selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final i = selected == null ? -1 : values.indexOf(selected as T);

    return LayoutBuilder(
      builder: (context, constraints) {
        const trackPad = 3.0;
        final slot = (constraints.maxWidth - trackPad * 2) / values.length;

        return Container(
          height: 40,
          padding: const EdgeInsets.all(trackPad),
          decoration: BoxDecoration(
            color: c.surface2,
            borderRadius: BorderRadius.circular(TotoRadius.sm + trackPad),
          ),
          child: Stack(
            children: [
              if (i >= 0)
                AnimatedPositioned(
                  duration: TotoMotion.fast,
                  curve: TotoMotion.standard,
                  left: slot * i,
                  top: 0,
                  bottom: 0,
                  width: slot,
                  child: Container(
                    decoration: BoxDecoration(
                      color: c.surfacePressed,
                      borderRadius: BorderRadius.circular(TotoRadius.sm),
                      border: Border.all(color: c.specular),
                    ),
                  ),
                ),
              Row(
                children: [
                  for (final v in values)
                    Expanded(
                      child: Semantics(
                        selected: v == selected,
                        button: true,
                        child: PressScale(
                          scale: 0.94,
                          onTap: () => onChanged(v),
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: AnimatedDefaultTextStyle(
                                duration: TotoMotion.fast,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium!
                                    .copyWith(
                                      fontSize: 12,
                                      color: v == selected
                                          ? c.textPrimary
                                          : c.textSecondary,
                                      fontWeight: v == selected
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                    ),
                                child: Text(
                                  labels(v),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Chip di valore: 1 / X / 2, Gol / NoGol, Under / Over…
/// Altezza visiva 40, area di tocco 48 (min 44pt garantito).
class TotoValueChip extends StatelessWidget {
  const TotoValueChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.enabled = true,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Semantics(
      selected: selected,
      button: true,
      enabled: enabled,
      child: PressScale(
        scale: 0.96,
        onTap: enabled ? onTap : null,
        child: SizedBox(
          height: 48, // area di tocco
          child: Center(
            child: AnimatedContainer(
              duration: TotoMotion.fast,
              curve: TotoMotion.standard,
              height: 40,
              constraints: const BoxConstraints(minWidth: 56),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: TotoSpace.lg),
              decoration: BoxDecoration(
                color: !enabled
                    ? c.neutralContainer
                    : selected
                        ? c.brandFill
                        : c.surface2,
                borderRadius: BorderRadius.circular(TotoRadius.sm),
                border: Border.all(
                  color: selected ? c.brandFill : c.borderSubtle,
                ),
              ),
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelLarge!.copyWith(
                      color: !enabled
                          ? c.textDisabled
                          : selected
                              ? c.textOnPrimary
                              : c.textSecondary,
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  6. PODIO
//     Su 375px tre colonne sono strette e illeggibili. Il primo prende una
//     card a tutta larghezza, secondo e terzo una riga a due colonne.
// ═════════════════════════════════════════════════════════════════════════════

class PodiumEntry {
  const PodiumEntry({
    required this.name,
    required this.points,
    this.avatarUrl,
    this.delta = 0,
  });

  final String name;
  final int points;
  final String? avatarUrl;
  final int delta;
}

class TotoPodium extends StatelessWidget {
  const TotoPodium({super.key, required this.entries});

  /// Attese in ordine: 1°, 2°, 3°. Tollerante a liste più corte.
  final List<PodiumEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();
    final c = context.c;

    return Column(
      children: [
        _PodiumHero(entry: entries[0]),
        if (entries.length > 1) ...[
          const SizedBox(height: TotoSpace.md),
          Row(
            children: [
              Expanded(
                child: _PodiumSmall(
                  rank: 2,
                  entry: entries[1],
                  ring: c.silver,
                  tint: c.silverContainer,
                ),
              ),
              if (entries.length > 2) ...[
                const SizedBox(width: TotoSpace.md),
                Expanded(
                  child: _PodiumSmall(
                    rank: 3,
                    entry: entries[2],
                    ring: c.bronze,
                    tint: c.bronzeContainer,
                  ),
                ),
              ] else
                const Spacer(),
            ],
          ),
        ],
      ],
    );
  }
}

class _PodiumHero extends StatelessWidget {
  const _PodiumHero({required this.entry});
  final PodiumEntry entry;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return TotoCard(
      level: TotoCardLevel.elevated,
      radius: TotoRadius.xl,
      padding: const EdgeInsets.all(TotoSpace.xl),
      accent: c.gold.withValues(alpha: 0.28),
      child: Row(
        children: [
          _Avatar(url: entry.avatarUrl, size: 64, ring: c.gold, ringWidth: 2.5),
          const SizedBox(width: TotoSpace.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.emoji_events_rounded, size: 15, color: c.gold),
                    const SizedBox(width: TotoSpace.xs + 2),
                    Text(
                      '1° POSTO',
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall!
                          .copyWith(color: c.gold),
                    ),
                  ],
                ),
                const SizedBox(height: TotoSpace.xs + 2),
                Text(
                  entry.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          ),
          const SizedBox(width: TotoSpace.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${entry.points}',
                  style: TotoType.number(32, color: c.gold)),
              Text('punti', style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
        ],
      ),
    );
  }
}

class _PodiumSmall extends StatelessWidget {
  const _PodiumSmall({
    required this.rank,
    required this.entry,
    required this.ring,
    required this.tint,
  });

  final int rank;
  final PodiumEntry entry;
  final Color ring;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return TotoCard(
      padding: const EdgeInsets.symmetric(
        horizontal: TotoSpace.md,
        vertical: TotoSpace.lg,
      ),
      child: Column(
        children: [
          _Avatar(url: entry.avatarUrl, size: 48, ring: ring, ringWidth: 2),
          const SizedBox(height: TotoSpace.md),
          Text(
            '$rank°',
            style: Theme.of(context)
                .textTheme
                .labelSmall!
                .copyWith(color: ring, letterSpacing: 0.4),
          ),
          const SizedBox(height: TotoSpace.xxs),
          Text(
            entry.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: TotoSpace.xs),
          Text(
            '${entry.points}',
            style: TotoType.number(20, color: c.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    this.url,
    required this.size,
    required this.ring,
    this.ringWidth = 2,
  });

  final String? url;
  final double size;
  final Color ring;
  final double ringWidth;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(ringWidth),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ring, width: ringWidth),
      ),
      child: ClipOval(
        child: Container(
          color: c.surfacePressed,
          child: url == null
              ? Icon(Icons.person_rounded,
                  size: size * 0.5, color: c.textTertiary)
              : Image.network(url!, fit: BoxFit.cover),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  7. BOTTOM NAV IN VETRO
//     Il blur costa GPU: ha senso solo se lo sfondo è davvero traslucido.
//     Con opacità 0.72 il contenuto scorre visibilmente sotto la barra.
// ═════════════════════════════════════════════════════════════════════════════

class TotoGlassNav extends StatelessWidget {
  const TotoGlassNav({
    super.key,
    required this.index,
    required this.onChanged,
    required this.destinations,
  });

  final int index;
  final ValueChanged<int> onChanged;
  final List<NavigationDestination> destinations;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: c.navHairline)),
          ),
          child: NavigationBar(
            selectedIndex: index,
            onDestinationSelected: (i) {
              HapticFeedback.selectionClick();
              onChanged(i);
            },
            destinations: destinations,
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  8. EMPTY STATE
// ═════════════════════════════════════════════════════════════════════════════

class TotoEmptyState extends StatelessWidget {
  const TotoEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    this.preview,
  });

  final IconData icon;
  final String title;
  final String body;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  /// Anteprima sfocata di ciò che l'utente otterrà sbloccando.
  /// Uno stato vuoto che mostra il premio converte meglio di uno che lo nasconde.
  final Widget? preview;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (preview != null)
          Positioned.fill(
            child: ClipRect(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Opacity(opacity: 0.35, child: preview),
              ),
            ),
          ),
        Container(
          alignment: const Alignment(0, -0.15),
          padding: const EdgeInsets.symmetric(horizontal: TotoSpace.x3l),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: c.surface2,
                  shape: BoxShape.circle,
                  border: Border.all(color: c.borderSubtle),
                ),
                child: Icon(icon, size: 36, color: c.brand),
              ),
              const SizedBox(height: TotoSpace.xxl),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: TotoSpace.sm),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 300),
                child: Text(
                  body,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: TotoSpace.x3l),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onPrimary,
                  child: Text(primaryLabel),
                ),
              ),
              if (secondaryLabel != null) ...[
                const SizedBox(height: TotoSpace.md),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: onSecondary,
                    child: Text(secondaryLabel!),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
