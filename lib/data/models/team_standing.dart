import 'package:freezed_annotation/freezed_annotation.dart';

part 'team_standing.freezed.dart';

/// Riga della classifica squadre di una competizione (non va confusa con
/// la classifica utenti/pronostici, che è un concetto separato — vedi
/// feature `leaderboard`).
@freezed
abstract class TeamStanding with _$TeamStanding {
  const factory TeamStanding({
    required String teamId,
    required String teamName,
    required int position,
    required int played,
    required int won,
    required int drawn,
    required int lost,
    required int goalsFor,
    required int goalsAgainst,
    required int points,
  }) = _TeamStanding;
}
