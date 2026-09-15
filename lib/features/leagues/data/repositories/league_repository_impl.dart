import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/errors/app_exception_mapper.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/utils/code_generator.dart';
import '../../../../data/models/league.dart';
import '../../../../data/models/league_member.dart';
import '../../../auth/data/datasources/user_firestore_datasource.dart';
import '../../domain/repositories/league_repository.dart';
import '../datasources/league_firestore_datasource.dart';

class LeagueRepositoryImpl implements LeagueRepository {
  LeagueRepositoryImpl(
      this._auth, this._leagueDatasource, this._userDatasource);

  final FirebaseAuth _auth;
  final LeagueFirestoreDatasource _leagueDatasource;
  final UserFirestoreDatasource _userDatasource;

  String _requireUserId() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw const NotAuthenticatedFailure();
    return uid;
  }

  Future<String> _uniqueInviteCode() async {
    // Le collisioni sono estremamente rare (spazio di ~33^5 combinazioni),
    // ma verifichiamo comunque prima di usare il codice.
    for (var attempt = 0; attempt < 5; attempt++) {
      final code = CodeGenerator.leagueInviteCode();
      if (!await _leagueDatasource.isInviteCodeTaken(code)) return code;
    }
    throw const ServerFailure(
        'Non è stato possibile generare un codice lega univoco. Riprova.');
  }

  @override
  Future<String> createLeague(
      {required String name, String? description}) async {
    try {
      final userId = _requireUserId();
      final owner = await _userDatasource.getUser(userId);
      if (owner == null) throw const NotAuthenticatedFailure();

      final inviteCode = await _uniqueInviteCode();

      return await _leagueDatasource.createLeague(
        name: name,
        description: description,
        ownerId: userId,
        ownerUsername: owner.username,
        ownerPhotoUrl: owner.photoUrl,
        inviteCode: inviteCode,
      );
    } catch (error) {
      throw AppExceptionMapper.map(error);
    }
  }

  @override
  Future<League> joinLeagueByInviteCode(String inviteCode) async {
    try {
      final userId = _requireUserId();
      final normalizedCode = inviteCode.trim().toUpperCase();

      final league = await _leagueDatasource.findByInviteCode(normalizedCode);
      if (league == null) throw const LeagueNotFoundFailure();

      final alreadyMember = await _leagueDatasource.isMember(league.id, userId);
      if (!alreadyMember) {
        final user = await _userDatasource.getUser(userId);
        if (user == null) throw const NotAuthenticatedFailure();
        await _leagueDatasource.joinLeague(
          leagueId: league.id,
          userId: userId,
          username: user.username,
          photoUrl: user.photoUrl,
        );
      }

      return league;
    } catch (error) {
      throw AppExceptionMapper.map(error);
    }
  }

  @override
  Future<League?> getLeague(String leagueId) async {
    try {
      return await _leagueDatasource.getLeague(leagueId);
    } catch (error) {
      throw AppExceptionMapper.map(error);
    }
  }

  @override
  Stream<List<LeagueMember>> watchMembers(String leagueId) {
    return _leagueDatasource.watchMembers(leagueId);
  }

  @override
  Stream<List<League>> watchMyLeagues() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(const []);
    return _leagueDatasource.watchMyLeagues(uid);
  }

  @override
  Future<bool> hasAnyLeague() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;
    return _leagueDatasource.hasAnyLeague(uid);
  }

  @override
  Future<bool> isMember(String leagueId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;
    return _leagueDatasource.isMember(leagueId, uid);
  }
}
