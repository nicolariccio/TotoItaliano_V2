import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/errors/app_exception_mapper.dart';
import '../../../../core/errors/failure.dart';
import '../../../leagues/domain/repositories/league_repository.dart';
import '../../domain/entities/prediction.dart';
import '../../domain/repositories/prediction_repository.dart';
import '../datasources/prediction_firestore_datasource.dart';

class PredictionRepositoryImpl implements PredictionRepository {
  PredictionRepositoryImpl(this._auth, this._datasource, this._leagueRepository);

  final FirebaseAuth _auth;
  final PredictionFirestoreDatasource _datasource;
  final LeagueRepository _leagueRepository;

  String _requireUserId() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw const NotAuthenticatedFailure();
    return uid;
  }

  @override
  Future<void> saveSchedina(List<PredictionPick> picks) async {
    if (picks.isEmpty) return;
    try {
      final userId = _requireUserId();

      if (!await _leagueRepository.hasAnyLeague()) {
        throw const ValidationFailure('Devi far parte di una lega per salvare la schedina.');
      }

      await _datasource.saveSchedina(userId, picks);
    } catch (error) {
      throw AppExceptionMapper.map(error);
    }
  }

  @override
  Future<Prediction?> getPrediction(String matchId) async {
    try {
      return await _datasource.get(_requireUserId(), matchId);
    } catch (error) {
      throw AppExceptionMapper.map(error);
    }
  }

  @override
  Stream<Prediction?> watchPrediction(String matchId) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(null);
    return _datasource.watch(uid, matchId);
  }

  @override
  Stream<List<Prediction>> watchMyPredictions() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(const []);
    return _datasource.watchForUser(uid);
  }

  @override
  Stream<List<Prediction>> watchMyPredictionsForMatchday(String matchdayId) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(const []);
    return _datasource.watchForUserAndMatchday(uid, matchdayId);
  }
}
