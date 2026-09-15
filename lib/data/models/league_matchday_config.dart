import 'package:freezed_annotation/freezed_annotation.dart';

part 'league_matchday_config.freezed.dart';

/// Quali partite di una giornata contano per una specifica lega, salvato in
/// `leagues/{leagueId}/matchdayConfig/{matchdayId}`. Assenza del documento
/// (o `excludedMatchIds` vuoto) = tutte le partite della giornata contano,
/// il comportamento di default. Permette a ciascuna lega di restringere il
/// programma esattamente come su totoamici.net (es. una lega tra amici che
/// segue solo alcune partite della giornata).
@freezed
abstract class LeagueMatchdayConfig with _$LeagueMatchdayConfig {
  const factory LeagueMatchdayConfig({
    required String leagueId,
    required String matchdayId,
    @Default(<String>[]) List<String> excludedMatchIds,
  }) = _LeagueMatchdayConfig;
}
