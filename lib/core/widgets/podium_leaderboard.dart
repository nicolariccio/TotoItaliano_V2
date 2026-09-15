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
      this.emptyTitle = 'Classifica non ancora disponibile'});

  final List<RankedEntry> entries;
  final String emptyTitle;

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

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          TotoSpace.lg, TotoSpace.lg, TotoSpace.lg, TotoSpace.navClearance),
      children: [
        FadeSlideIn(
          child: TotoPodium(
            entries: [
              for (final e in podium)
                PodiumEntry(
                    name: e.username, points: e.points, avatarUrl: e.photoUrl),
            ],
          ),
        ),
        if (rest.isNotEmpty) const SizedBox(height: TotoSpace.x3l),
        for (var i = 0; i < rest.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: TotoSpace.sm),
            child: FadeSlideIn(
              delay: Duration(milliseconds: 40 * i.clamp(0, 10)),
              child: _RankedRow(position: i + 4, entry: rest[i]),
            ),
          ),
      ],
    );
  }
}

class _RankedRow extends StatelessWidget {
  const _RankedRow({required this.position, required this.entry});

  final int position;
  final RankedEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.c;
    return TotoCard(
      padding: const EdgeInsets.symmetric(
          horizontal: TotoSpace.lg, vertical: TotoSpace.md),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text('$position',
                style: theme.textTheme.labelLarge, textAlign: TextAlign.center),
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
                Text('@${entry.username}',
                    style: theme.textTheme.labelLarge,
                    overflow: TextOverflow.ellipsis),
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
          Text('${entry.points} pt',
              style:
                  TotoType.number(15, display: false, color: c.textSecondary)),
        ],
      ),
    );
  }
}
