import 'package:freezed_annotation/freezed_annotation.dart';

part 'competition.freezed.dart';

enum CompetitionStatus { upcoming, active, finished }

@freezed
abstract class Competition with _$Competition {
  const factory Competition({
    required String id,
    required String name,
    required String season,
    @Default('calcio') String sport,
    required DateTime startDate,
    required DateTime endDate,
    @Default(CompetitionStatus.upcoming) CompetitionStatus status,
    @Default(0) num entryFee,
    @Default('EUR') String currency,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Competition;
}
