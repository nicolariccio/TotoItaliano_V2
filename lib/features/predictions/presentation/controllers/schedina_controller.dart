import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception_mapper.dart';
import '../../../../data/models/match.dart';
import '../../../../data/providers/football_data_providers.dart';
import '../../data/datasources/prediction_firestore_datasource.dart';
import '../../domain/entities/prediction.dart';
import '../providers/prediction_providers.dart';
import 'schedina_state.dart';

class SchedinaController extends StateNotifier<SchedinaState> {
  SchedinaController(this._ref) : super(const SchedinaState()) {
    _load();
  }

  final Ref _ref;

  Future<void> _load() async {
    try {
      final matchday = await _ref.read(currentMatchdayProvider.future);
      final predictions = await _ref.read(myPredictionsForMatchdayProvider(matchday.id).future);
      final picks = {for (final p in predictions) p.matchId: PickState.fromPrediction(p)};
      state = state.copyWith(picks: picks, isLoading: false);
    } catch (_) {
      // Nessun pronostico pregresso caricabile: si parte da una schedina
      // vuota, non è un errore bloccante per l'utente.
      state = state.copyWith(isLoading: false);
    }
  }

  void _update(String matchId, PickState Function(PickState current) update) {
    final current = state.picks[matchId] ?? const PickState();
    state = state.copyWith(
      picks: {...state.picks, matchId: update(current)},
      clearError: true,
      savedSuccessfully: false,
    );
  }

  void selectMarket(String matchId, PredictionMarket market) => _update(matchId, (p) => p.withMarket(market));

  void setResult1x2(String matchId, String value) =>
      _update(matchId, (p) => p.copyWith(result1x2Value: value));

  void setGoalNoGoal(String matchId, bool value) =>
      _update(matchId, (p) => p.copyWith(goalNoGoalValue: value));

  void setOverUnder25(String matchId, bool value) =>
      _update(matchId, (p) => p.copyWith(overUnder25Value: value));

  void setExactScore(String matchId, {int? home, int? away}) => _update(
        matchId,
        (p) => p.copyWith(exactHomeScore: home, exactAwayScore: away),
      );

  Future<void> save(List<Match> matches) async {
    state = state.copyWith(isSaving: true, clearError: true, savedSuccessfully: false);
    try {
      final picks = <PredictionPick>[];
      for (final match in matches) {
        if (!match.isPredictionOpen) continue;
        final pick = state.picks[match.id];
        if (pick == null || !pick.isComplete) continue;

        picks.add(PredictionPick(
          matchId: match.id,
          competitionId: match.competitionId,
          matchdayId: match.matchdayId,
          market: pick.market!,
          result1x2Value: pick.result1x2Value,
          goalNoGoalValue: pick.goalNoGoalValue,
          overUnder25Value: pick.overUnder25Value,
          exactHomeScore: pick.exactHomeScore,
          exactAwayScore: pick.exactAwayScore,
        ));
      }

      await _ref.read(predictionRepositoryProvider).saveSchedina(picks);
      state = state.copyWith(isSaving: false, savedSuccessfully: true);
    } catch (error) {
      state = state.copyWith(isSaving: false, errorMessage: AppExceptionMapper.map(error).message);
    }
  }
}

final StateNotifierProvider<SchedinaController, SchedinaState> schedinaControllerProvider =
    StateNotifierProvider<SchedinaController, SchedinaState>((ref) => SchedinaController(ref));
