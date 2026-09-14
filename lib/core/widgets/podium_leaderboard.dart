import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import 'fade_slide_in.dart';
import 'ranked_entry.dart';
import 'state_views.dart';

/// Podio (top 3) + lista posizioni 4+ per una lista di [RankedEntry] già
/// ordinata per punti decrescenti. Usato sia dalla classifica generale
/// sia da quella di lega.
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
      padding: const EdgeInsets.all(20),
      children: [
        FadeSlideIn(child: _Podium(entries: podium)),
        const SizedBox(height: 24),
        for (var i = 0; i < rest.length; i++)
          FadeSlideIn(
            delay: Duration(milliseconds: 40 * i.clamp(0, 10)),
            child: _RankedRow(position: i + 4, entry: rest[i]),
          ),
      ],
    );
  }
}

class _Podium extends StatelessWidget {
  const _Podium({required this.entries});

  final List<RankedEntry> entries;

  @override
  Widget build(BuildContext context) {
    RankedEntry? at(int index) =>
        index < entries.length ? entries[index] : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
            child: _PodiumSlot(
                entry: at(1),
                position: 2,
                height: 84,
                color: AppColors.podiumSilver)),
        const SizedBox(width: 8),
        Expanded(
            child: _PodiumSlot(
                entry: at(0),
                position: 1,
                height: 110,
                color: AppColors.podiumGold)),
        const SizedBox(width: 8),
        Expanded(
            child: _PodiumSlot(
                entry: at(2),
                position: 3,
                height: 64,
                color: AppColors.podiumBronze)),
      ],
    );
  }
}

class _PodiumSlot extends StatelessWidget {
  const _PodiumSlot(
      {required this.entry,
      required this.position,
      required this.height,
      required this.color});

  final RankedEntry? entry;
  final int position;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final item = entry;
    if (item == null) return const SizedBox.shrink();

    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: color.withValues(alpha: 0.25),
              backgroundImage:
                  item.photoUrl != null ? NetworkImage(item.photoUrl!) : null,
              child: item.photoUrl == null
                  ? Text(
                      item.username.isNotEmpty
                          ? item.username[0].toUpperCase()
                          : '?',
                      style: theme.textTheme.titleMedium,
                    )
                  : null,
            ),
            Positioned(
              bottom: -4,
              right: -4,
              child: Container(
                width: 20,
                height: 20,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: theme.scaffoldBackgroundColor, width: 2),
                ),
                child: Text(
                  '$position',
                  style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.black87, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text('@${item.username}',
            style: theme.textTheme.labelMedium,
            overflow: TextOverflow.ellipsis,
            maxLines: 1),
        Text('${item.points} pt', style: theme.textTheme.labelSmall),
        const SizedBox(height: 8),
        Container(
          height: height,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
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
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            SizedBox(
                width: 28,
                child: Text('$position',
                    style: theme.textTheme.labelLarge,
                    textAlign: TextAlign.center)),
            const SizedBox(width: 12),
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.azzurro,
              backgroundImage:
                  entry.photoUrl != null ? NetworkImage(entry.photoUrl!) : null,
              child: entry.photoUrl == null
                  ? Text(
                      entry.username.isNotEmpty
                          ? entry.username[0].toUpperCase()
                          : '?',
                      style: theme.textTheme.labelMedium
                          ?.copyWith(color: Colors.white),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text('@${entry.username}',
                  style: theme.textTheme.labelLarge,
                  overflow: TextOverflow.ellipsis),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: AppColors.darkSurfaceElevated,
                  borderRadius: AppRadii.pillRadius),
              child: Text('${entry.points} pt',
                  style: theme.textTheme.labelMedium),
            ),
          ],
        ),
      ),
    );
  }
}
