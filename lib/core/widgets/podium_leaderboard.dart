import 'package:flutter/material.dart';

import '../theme/toto_theme.dart';
import 'fade_slide_in.dart';
import 'ranked_entry.dart';
import 'state_views.dart';
import 'toto_widgets.dart';

/// Podio (top 3, via [TotoPodium]) + lista posizioni 4+ per una lista di
/// [RankedEntry] già ordinata per punti decrescenti. Usato sia dalla
/// classifica generale sia da quella di lega.
class PodiumLeaderboard extends StatelessWidget {
  const PodiumLeaderboard(
      {super.key,
      required this.entries,
      this.emptyTitle = 'Classifica non ancora disponibile',
      this.currentUserId});

  final List<RankedEntry> entries;
  final String emptyTitle;

  /// Se valorizzato e presente in [entries], la sua riga resta fissa sopra
  /// la bottom nav (bordo blu, badge "TU") — cosi' l'utente sa sempre dove
  /// si trova senza dover scorrere fino alla propria posizione.
  final String? currentUserId;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return AppEmptyView(
          title: emptyTitle,
          subtitle: 'Torna qui dopo le prime giornate giocate.');
    }

    final podium = entries.take(3).toList();
    final rest =
        entries.length > 3 ? entries.sublist(3) : const <RankedEntry>[];

    final meIndex =
        currentUserId == null ? -1 : entries.indexWhere((e) => e.id == currentUserId);
    // La riga "TU" nel podio (posizione 1-3) è già ben visibile: la fissiamo
    // in fondo solo se l'utente è in lista (posizione 4+ o non ancora
    // caricata), evitando un duplicato ridondante sopra il podio stesso.
    final pinnedMe = meIndex >= 3 ? entries[meIndex] : null;

    return Stack(
      children: [
        ListView(
          padding: EdgeInsets.fromLTRB(TotoSpace.lg, TotoSpace.lg, TotoSpace.lg,
              pinnedMe != null ? 88 : TotoSpace.navClearance),
          children: [
            FadeSlideIn(
              child: TotoPodium(
                entries: [
                  for (final e in podium)
                    PodiumEntry(
                        name: e.username,
                        points: e.points,
                        avatarUrl: e.photoUrl),
                ],
              ),
            ),
            if (rest.isNotEmpty) const SizedBox(height: TotoSpace.x3l),
            for (var i = 0; i < rest.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: TotoSpace.sm),
                child: FadeSlideIn(
                  delay: Duration(milliseconds: 40 * i.clamp(0, 10)),
                  child: _RankedRow(
                    position: i + 4,
                    entry: rest[i],
                    highlighted: rest[i].id == currentUserId,
                  ),
                ),
              ),
          ],
        ),
        if (pinnedMe != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  TotoSpace.lg, 0, TotoSpace.lg, TotoSpace.navClearance - 16),
              child: _RankedRow(
                position: meIndex + 1,
                entry: pinnedMe,
                highlighted: true,
              ),
            ),
          ),
      ],
    );
  }
}

class _RankedRow extends StatelessWidget {
  const _RankedRow(
      {required this.position, required this.entry, this.highlighted = false});

  final int position;
  final RankedEntry entry;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.c;
    return Container(
      decoration: highlighted
          ? BoxDecoration(
              color: c.brandContainer,
              borderRadius: BorderRadius.circular(TotoRadius.lg),
              border: Border.all(color: c.brand),
            )
          : null,
      child: TotoCard(
      level: highlighted ? TotoCardLevel.flat : TotoCardLevel.interactive,
      padding: const EdgeInsets.symmetric(
          horizontal: TotoSpace.lg, vertical: TotoSpace.md),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text('$position',
                style: TotoType.number(15, display: false, color: c.textSecondary),
                textAlign: TextAlign.center),
          ),
          const SizedBox(width: TotoSpace.md),
          CircleAvatar(
            radius: 18,
            backgroundColor: c.brandFill,
            backgroundImage:
                entry.photoUrl != null ? NetworkImage(entry.photoUrl!) : null,
            child: entry.photoUrl == null
                ? Text(
                    entry.username.isNotEmpty
                        ? entry.username[0].toUpperCase()
                        : '?',
                    style: theme.textTheme.labelMedium
                        ?.copyWith(color: c.textOnPrimary),
                  )
                : null,
          ),
          const SizedBox(width: TotoSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text('@${entry.username}',
                          style: theme.textTheme.labelLarge,
                          overflow: TextOverflow.ellipsis),
                    ),
                    if (highlighted) ...[
                      const SizedBox(width: TotoSpace.xs),
                      const TotoBadge('TU',
                          tone: TotoBadgeTone.brand, dense: true, uppercase: false),
                    ],
                  ],
                ),
                if (entry.last5.isNotEmpty || entry.exactCount > 0) ...[
                  const SizedBox(height: TotoSpace.xxs),
                  Row(
                    children: [
                      for (final correct in entry.last5)
                        Padding(
                          padding: const EdgeInsets.only(right: 3),
                          child: Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: correct ? c.success : c.danger,
                            ),
                          ),
                        ),
                      if (entry.exactCount > 0) ...[
                        if (entry.last5.isNotEmpty)
                          const SizedBox(width: TotoSpace.xs),
                        Text('${entry.exactCount} esatti',
                            style: theme.textTheme.labelSmall
                                ?.copyWith(color: c.textTertiary)),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${entry.points} pt',
                  style: TotoType.number(15,
                      display: false, color: c.textSecondary)),
              if (entry.delta != null) ...[
                const SizedBox(height: 2),
                TotoRankDelta(delta: entry.delta!),
              ],
            ],
          ),
        ],
      ),
      ),
    );
  }
}
