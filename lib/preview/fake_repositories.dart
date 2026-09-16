// ─────────────────────────────────────────────────────────────────────────────
//  Implementazioni finte dei repository, solo per l'anteprima visiva.
//  Ogni metodo è un no-op sicuro: bastano a far compilare/toccare la UI
//  senza Firebase, non a testare la logica di business.
// ─────────────────────────────────────────────────────────────────────────────

import '../data/models/league.dart';
import '../data/models/league_matchday_config.dart';
import '../data/models/league_member.dart';
import '../data/models/scoring_config.dart';
import '../features/auth/domain/entities/app_user.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/leagues/domain/repositories/league_repository.dart';
import '../features/predictions/data/datasources/prediction_firestore_datasource.dart';
import '../features/predictions/domain/entities/prediction.dart';
import '../features/predictions/domain/repositories/prediction_repository.dart';
import 'fake_data.dart';

class FakeLeagueRepository implements LeagueRepository {
  @override
  Future<String> createLeague({required String name, String? description}) =>
      Future.value(leagueBarId);

  @override
  Future<League> joinLeagueByInviteCode(String inviteCode) =>
      Future.value(leagueBar);

  @override
  Future<League?> getLeague(String leagueId) =>
      Future.value(fakeLeagueById(leagueId));

  @override
  Stream<List<LeagueMember>> watchMembers(String leagueId) =>
      Stream.value(fakeMembersFor(leagueId));

  @override
  Stream<List<League>> watchMyLeagues() => Stream.value(fakeLeagues);

  @override
  Future<bool> hasAnyLeague() => Future.value(true);

  @override
  Future<bool> isMember(String leagueId) => Future.value(true);

  @override
  Future<void> updateScoringConfig(String leagueId, ScoringConfig config) =>
      Future.value();

  @override
  Stream<LeagueMatchdayConfig> watchMatchdayConfig(
          String leagueId, String matchdayId) =>
      Stream.value(
          LeagueMatchdayConfig(leagueId: leagueId, matchdayId: matchdayId));

  @override
  Future<void> setExcludedMatches(
          String leagueId, String matchdayId, List<String> excludedMatchIds) =>
      Future.value();

  @override
  Future<void> removeMember(String leagueId, String userId) => Future.value();
}

class FakeAuthRepository implements AuthRepository {
  @override
  Future<AppUser> registerWithEmail({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String username,
    String? referralCode,
  }) =>
      Future.value(fakeCurrentUser);

  @override
  Future<void> loginWithEmail(
          {required String email, required String password}) =>
      Future.value();

  @override
  Future<bool> signInWithGoogle() => Future.value(false);

  @override
  Future<void> sendPasswordResetEmail(String email) => Future.value();

  @override
  Future<void> signOut() => Future.value();
}

class FakePredictionRepository implements PredictionRepository {
  @override
  Future<void> saveSchedina(String leagueId, List<PredictionPick> picks) =>
      Future.value();

  @override
  Stream<List<Prediction>> watchMyPredictions() =>
      Stream.value(allFakePredictions);

  @override
  Stream<List<Prediction>> watchMyPredictionsForLeagueAndMatchday(
          String leagueId, String matchdayId) =>
      Stream.value(fakePredictionsFor(leagueId, matchdayId));
}
