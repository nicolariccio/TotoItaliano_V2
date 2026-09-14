import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/errors/app_exception_mapper.dart';
import '../../../../core/errors/failure.dart';
import '../../../../data/models/match.dart';
import '../../domain/entities/prediction.dart';
import '../../domain/repositories/prediction_repository.dart';
import '../datasources/prediction_firestore_datasource.dart';

class PredictionRepositoryImpl implements PredictionRepository {
  PredictionRepositoryImpl(this._auth, this._datasource);

  final FirebaseAuth _auth;
  final PredictionFirestoreDatasource _datasource;

  String _requireUserId() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw const NotAuthenticatedFailure();
    return uid;
  }

  @override
  Future<void> savePrediction({
    required Match match,
    int? exactHomeScore,
    int? exactAwayScore,
    String? result1x2,
    bool? goalNoGoal,
    Map<String, bool>? overUnder,
  }) async {
    if (!match.isPredictionOpen) {
      throw const PredictionLockedFailure();
    }
    try {
      final userId = _requireUserId();
      await _datasource.upsert(
        userId: userId,
        matchId: match.id,
        competitionId: match.competitionId,
        matchdayId: match.matchdayId,
        exactHomeScore: exactHomeScore,
        exactAwayScore: exactAwayScore,
        result1x2: result1x2,
        goalNoGoal: goalNoGoal,
        overUnder: overUnder,
      );
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
}
