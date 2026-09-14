import 'package:freezed_annotation/freezed_annotation.dart';

part 'matchday.freezed.dart';

enum MatchdayStatus { upcoming, active, finished }

@freezed
abstract class Matchday with _$Matchday {
  const factory Matchday({
    required String id,
    required String competitionId,
    required int number,
    required DateTime startDate,
    required DateTime endDate,
    @Default(MatchdayStatus.upcoming) MatchdayStatus status,
    required DateTime predictionDeadline,
  }) = _Matchday;
}
