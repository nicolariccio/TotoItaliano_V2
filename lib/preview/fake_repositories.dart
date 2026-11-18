// ─────────────────────────────────────────────────────────────────────────────
//  Implementazioni finte dei repository, solo per l'anteprima visiva.
//  Ogni metodo è un no-op sicuro: bastano a far compilare/toccare la UI
//  senza Firebase, non a testare la logica di business.
// ─────────────────────────────────────────────────────────────────────────────

import '../data/models/league.dart';
import '../data/models/league_matchday_config.dart';
import '../data/models/league_member.dart';
import '../data/models/league_tournament.dart';
import '../data/models/scoring_config.dart';
import '../data/models/tournament_bracket_tie.dart';
import '../data/models/tournament_group.dart';
import '../data/models/tournament_participant.dart';
import '../features/auth/domain/entities/app_user.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/leagues/domain/repositories/league_repository.dart';
import '../features/leagues/domain/repositories/tournament_repository.dart';
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

class FakeTournamentRepository implements TournamentRepository {
  @override
  Stream<List<LeagueTournament>> watchTournaments(String leagueId) =>
      Stream.value(fakeTournamentsFor(leagueId));

  @override
  Future<LeagueTournament?> getTournament(
          String leagueId, String tournamentId) =>
      Future.value(fakeTournamentById(tournamentId));

  @override
  Stream<List<TournamentParticipant>> watchParticipants(
          String leagueId, String tournamentId) =>
      Stream.value(fakeParticipantsFor(tournamentId));

  @override
  Stream<List<BracketTie>> watchBracket(String leagueId, String tournamentId) =>
      Stream.value(fakeBracketFor(tournamentId));

  @override
  Stream<List<TournamentGroup>> watchGroups(
          String leagueId, String tournamentId) =>
      Stream.value(fakeGroupsFor(tournamentId));

  @override
  Future<String> createTournament({
    required String leagueId,
    required String name,
    required TournamentType type,
    required List<String> participantUserIds,
    required List<TournamentSeedMember> seedMembers,
    String? createdFromMatchdayId,
    CoppaFormat? coppaFormat,
    int? groupSize,
    int? advancePerGroup,
    int eliminationsPerMatchday = 1,
    List<HighlanderTiebreak> tiebreakOrder = const [],
  }) =>
      Future.value(tournamentCampionatoId);

  @override
  Future<HighlanderEliminationPreview> previewHighlanderMatchday({
    required String leagueId,
    required String tournamentId,
    required String matchdayId,
  }) {
    final active =
        fakeParticipantsFor(tournamentId).where((p) => p.active).toList();
    final pointsByUser = {for (final p in active) p.userId: p.points};
    final worst = [...active]..sort((a, b) => a.points.compareTo(b.points));
    return Future.value(HighlanderEliminationPreview(
      matchdayId: matchdayId,
      pointsByUser: pointsByUser,
      eliminatedUserIds: worst.isEmpty ? const [] : [worst.first.userId],
    ));
  }

  @override
  Future<void> confirmHighlanderMatchday({
    required String leagueId,
    required String tournamentId,
    required HighlanderEliminationPreview preview,
  }) =>
      Future.value();

  @override
  Future<void> assignMatchdayToRound({
    required String leagueId,
    required String tournamentId,
    required int round,
    required String matchdayId,
  }) =>
      Future.value();

  @override
  Future<void> resolveBracketRound({
    required String leagueId,
    required String tournamentId,
    required int round,
  }) =>
      Future.value();

  @override
  Future<void> processGroupsMatchday({
    required String leagueId,
    required String tournamentId,
    required String matchdayId,
  }) =>
      Future.value();

  @override
  Future<void> closeGroupsPhaseAndSeedBracket({
    required String leagueId,
    required String tournamentId,
  }) =>
      Future.value();

  @override
  Future<void> refreshCampionatoStandings({
    required String leagueId,
    required String tournamentId,
    required List<String> matchdayIds,
  }) =>
      Future.value();
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
