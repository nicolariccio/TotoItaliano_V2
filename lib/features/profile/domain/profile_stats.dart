import '../../../data/models/matchday.dart';
import '../../predictions/domain/entities/prediction.dart';

/// Un pronostico segnato (risultato ufficiale disponibile) con la sua
/// giornata risolta — quanto basta per costruire storico e "miglior
/// giornata" senza rifare i join ogni volta.
class ScoredPrediction {
  const ScoredPrediction({required this.prediction, required this.matchday});

  final Prediction prediction;
  final Matchday matchday;
}

/// Statistiche del Profilo derivate client-side dallo storico pronostici
/// (nessun campo dedicato in `AppUser`, se non quelli già aggregati come
/// `totalPoints`/`successRate`): miglior giornata, serie di pronostici
/// corretti in corso, e precisione per mercato.
class ProfileStats {
  const ProfileStats({
    required this.bestMatchdayPoints,
    required this.currentStreak,
    required this.accuracyByMarket,
    required this.recentMatchdays,
  });

  factory ProfileStats.compute(List<ScoredPrediction> scored) {
    if (scored.isEmpty) {
      return const ProfileStats(
        bestMatchdayPoints: 0,
        currentStreak: 0,
        accuracyByMarket: {},
        recentMatchdays: [],
      );
    }

    // Più recente per primo: la grading avviene a match concluso, quindi
    // l'orario di aggiornamento del pronostico approssima bene "quando è
    // stato segnato" — non abbiamo un timestamp di grading dedicato.
    final byRecency = [...scored]
      ..sort((a, b) =>
          b.prediction.updatedAt.compareTo(a.prediction.updatedAt));

    var streak = 0;
    for (final s in byRecency) {
      if (s.prediction.correct == true) {
        streak++;
      } else {
        break;
      }
    }

    final pointsByMatchday = <String, int>{};
    final matchdayById = <String, Matchday>{};
    for (final s in scored) {
      pointsByMatchday.update(
        s.matchday.id,
        (v) => v + (s.prediction.pointsAwarded ?? 0),
        ifAbsent: () => s.prediction.pointsAwarded ?? 0,
      );
      matchdayById[s.matchday.id] = s.matchday;
    }
    final bestPoints =
        pointsByMatchday.values.fold(0, (a, b) => a > b ? a : b);

    final recentIds = matchdayById.values.toList()
      ..sort((a, b) => b.startDate.compareTo(a.startDate));
    final recentMatchdays = [
      for (final m in recentIds.take(3))
        (matchday: m, points: pointsByMatchday[m.id] ?? 0),
    ];

    final byMarket = <PredictionMarket, List<bool>>{};
    for (final s in scored) {
      byMarket
          .putIfAbsent(s.prediction.market, () => [])
          .add(s.prediction.correct ?? false);
    }
    final accuracy = <PredictionMarket, double>{
      for (final entry in byMarket.entries)
        entry.key:
            entry.value.where((c) => c).length / entry.value.length,
    };

    return ProfileStats(
      bestMatchdayPoints: bestPoints,
      currentStreak: streak,
      accuracyByMarket: accuracy,
      recentMatchdays: recentMatchdays,
    );
  }

  final int bestMatchdayPoints;
  final int currentStreak;
  final Map<PredictionMarket, double> accuracyByMarket;
  final List<({Matchday matchday, int points})> recentMatchdays;
}
