import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/errors/app_exception_mapper.dart';
import '../../../../core/errors/failure.dart';
import '../../../../data/models/match.dart';
import '../../../../data/models/matchday.dart';
import '../../../../data/models/team.dart';
import '../../../auth/data/datasources/user_firestore_datasource.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../domain/repositories/admin_repository.dart';
import '../datasources/admin_football_datasource.dart';
import '../datasources/scoring_recompute_datasource.dart';

class AdminRepositoryImpl implements AdminRepository {
  AdminRepositoryImpl(
    this._auth,
    this._userDatasource,
    this._adminFootballDatasource,
    this._scoringRecomputeDatasource,
  );

  final FirebaseAuth _auth;
  final UserFirestoreDatasource _userDatasource;
  final AdminFootballDatasource _adminFootballDatasource;
  final ScoringRecomputeDatasource _scoringRecomputeDatasource;

  Future<void> _requireGlobalAdmin() async {
    if (!await isGlobalAdmin()) throw const NotAuthorizedFailure();
  }

  @override
  Future<bool> isGlobalAdmin() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;
    final user = await _userDatasource.getUser(uid);
    return user?.role == UserRole.admin;
  }

  @override
  Future<String> createCompetition(
      {required String name, required String season}) async {
    try {
      await _requireGlobalAdmin();
      return await _adminFootballDatasource.createCompetition(
          name: name, season: season);
    } catch (error) {
      throw AppExceptionMapper.map(error);
    }
  }

  @override
  Future<void> seedTeams(String competitionId, List<Team> teams) async {
    try {
      await _requireGlobalAdmin();
      await _adminFootballDatasource.seedTeams(competitionId, teams);
    } catch (error) {
      throw AppExceptionMapper.map(error);
    }
  }

  @override
  Future<String> createMatchday({
    required String competitionId,
    required int number,
    required DateTime startDate,
    required DateTime endDate,
    required DateTime predictionDeadline,
  }) async {
    try {
      await _requireGlobalAdmin();
      return await _adminFootballDatasource.createMatchday(
        competitionId: competitionId,
        number: number,
        startDate: startDate,
        endDate: endDate,
        predictionDeadline: predictionDeadline,
      );
    } catch (error) {
      throw AppExceptionMapper.map(error);
    }
  }

  @override
  Future<void> setMatchdayStatus(
      String competitionId, String matchdayId, MatchdayStatus status) async {
    try {
      await _requireGlobalAdmin();
      await _adminFootballDatasource.setMatchdayStatus(
          competitionId, matchdayId, status);
    } catch (error) {
      throw AppExceptionMapper.map(error);
    }
  }

  @override
  Future<String> createMatch({
    required String competitionId,
    required String matchdayId,
    required Team homeTeam,
    required Team awayTeam,
    required DateTime kickoff,
  }) async {
    try {
      await _requireGlobalAdmin();
      return await _adminFootballDatasource.createMatch(
        competitionId: competitionId,
        matchdayId: matchdayId,
        homeTeam: homeTeam,
        awayTeam: awayTeam,
        kickoff: kickoff,
      );
    } catch (error) {
      throw AppExceptionMapper.map(error);
    }
  }

  @override
  Future<int> setMatchResultAndRecompute({
    required Match match,
    required int homeScore,
    required int awayScore,
  }) async {
    try {
      await _requireGlobalAdmin();
      final finishedMatch = await _adminFootballDatasource.setMatchResult(
        match: match,
        homeScore: homeScore,
        awayScore: awayScore,
      );
      return await _scoringRecomputeDatasource
          .recomputeForMatch(finishedMatch);
    } catch (error) {
      throw AppExceptionMapper.map(error);
    }
  }
}
