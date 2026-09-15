import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/errors/app_exception_mapper.dart';
import '../../../../core/errors/failure.dart';
import '../../../leagues/domain/repositories/league_repository.dart';
import '../../domain/entities/prediction.dart';
import '../../domain/repositories/prediction_repository.dart';
import '../datasources/prediction_firestore_datasource.dart';

class PredictionRepositoryImpl implements PredictionRepository {
  PredictionRepositoryImpl(
      this._auth, this._datasource, this._leagueRepository);

  final FirebaseAuth _auth;
  final PredictionFirestoreDatasource _datasource;
  final LeagueRepository _leagueRepository;

  String _requireUserId() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw const NotAuthenticatedFailure();
    return uid;
  }

  @override
  Future<void> saveSchedina(String leagueId, List<PredictionPick> picks) async {
    if (picks.isEmpty) return;
    try {
      final userId = _requireUserId();

      if (!await _leagueRepository.isMember(leagueId)) {
        throw const ValidationFailure(
            'Devi far parte di questa lega per salvare la schedina.');
      }

      await _datasource.saveSchedina(userId, leagueId, picks);
    } catch (error) {
      throw AppExceptionMapper.map(error);
    }
  }

  @override
  Stream<List<Prediction>> watchMyPredictions() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(const []);
    return _datasource.watchForUser(uid);
  }

  @override
  Stream<List<Prediction>> watchMyPredictionsForLeagueAndMatchday(
      String leagueId, String matchdayId) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(const []);
    return _datasource.watchForUserLeagueAndMatchday(
        uid, leagueId, matchdayId);
  }
}
