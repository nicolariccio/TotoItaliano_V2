import 'package:freezed_annotation/freezed_annotation.dart';

part 'league.freezed.dart';

@freezed
abstract class League with _$League {
  const factory League({
    required String id,
    required String name,
    String? description,
    required String ownerId,
    required String inviteCode,
    String? imageUrl,
    required DateTime createdAt,
    @Default(true) bool isActive,
    @Default(1) int memberCount,
  }) = _League;
}
