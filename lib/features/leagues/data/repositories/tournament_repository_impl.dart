import '../../../../core/errors/app_exception_mapper.dart';
import '../../../../data/models/league_tournament.dart';
import '../../../../data/models/tournament_bracket_tie.dart';
import '../../../../data/models/tournament_group.dart';
import '../../../../data/models/tournament_participant.dart';
import '../../domain/repositories/tournament_repository.dart';
import '../datasources/tournament_firestore_datasource.dart';

/// Applicazione reale sottile: la logica (seeding tabellone, spareggi,
/// eliminazione) vive nel datasource — stesso schema di
/// `ScoringRecomputeDatasource`/`AdminRepositoryImpl` già in questo repo.
/// L'applicazione delle regole di sicurezza reale è lato Firestore Rules
/// (il proprietario di lega è l'unico scrivente); qui mappiamo solo gli
/// errori tecnici in [Failure] user-friendly.
class TournamentRepositoryImpl implements TournamentRepository {
  TournamentRepositoryImpl(this._datasource);

  final TournamentFirestoreDatasource _datasource;

  @override
  Stream<List<LeagueTournament>> watchTournaments(String leagueId) =>
      _datasource.watchTournaments(leagueId);

  @override
  Future<LeagueTournament?> getTournament(
      String leagueId, String tournamentId) async {
    try {
      return await _datasource.getTournament(leagueId, tournamentId);
    } catch (error) {
      throw AppExceptionMapper.map(error);
    }
  }

  @override
  Stream<List<TournamentParticipant>> watchParticipants(
          String leagueId, String tournamentId) =>
      _datasource.watchParticipants(leagueId, tournamentId);

  @override
  Stream<List<BracketTie>> watchBracket(String leagueId, String tournamentId) =>
      _datasource.watchBracket(leagueId, tournamentId);

  @override
  Stream<List<TournamentGroup>> watchGroups(
          String leagueId, String tournamentId) =>
      _datasource.watchGroups(leagueId, tournamentId);

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
  }) async {
    try {
      return await _datasource.createTournament(
        leagueId: leagueId,
        name: name,
        type: type,
        participantUserIds: participantUserIds,
        seedMembers: seedMembers,
        createdFromMatchdayId: createdFromMatchdayId,
        coppaFormat: coppaFormat,
        groupSize: groupSize,
        advancePerGroup: advancePerGroup,
        eliminationsPerMatchday: eliminationsPerMatchday,
        tiebreakOrder: tiebreakOrder,
      );
    } catch (error) {
      throw AppExceptionMapper.map(error);
    }
  }

  @override
  Future<HighlanderEliminationPreview> previewHighlanderMatchday({
    required String leagueId,
    required String tournamentId,
    required String matchdayId,
  }) async {
    try {
      return await _datasource.previewHighlanderMatchday(
        leagueId: leagueId,
        tournamentId: tournamentId,
        matchdayId: matchdayId,
      );
    } catch (error) {
      throw AppExceptionMapper.map(error);
    }
  }

  @override
  Future<void> confirmHighlanderMatchday({
    required String leagueId,
    required String tournamentId,
    required HighlanderEliminationPreview preview,
  }) async {
    try {
      await _datasource.confirmHighlanderMatchday(
        leagueId: leagueId,
        tournamentId: tournamentId,
        preview: preview,
      );
    } catch (error) {
      throw AppExceptionMapper.map(error);
    }
  }

  @override
  Future<void> assignMatchdayToRound({
    required String leagueId,
    required String tournamentId,
    required int round,
    required String matchdayId,
  }) async {
    try {
      await _datasource.assignMatchdayToRound(
        leagueId: leagueId,
        tournamentId: tournamentId,
        round: round,
        matchdayId: matchdayId,
      );
    } catch (error) {
      throw AppExceptionMapper.map(error);
    }
  }

  @override
  Future<void> resolveBracketRound({
    required String leagueId,
    required String tournamentId,
    required int round,
  }) async {
    try {
      await _datasource.resolveBracketRound(
        leagueId: leagueId,
        tournamentId: tournamentId,
        round: round,
      );
    } catch (error) {
      throw AppExceptionMapper.map(error);
    }
  }

  @override
  Future<void> processGroupsMatchday({
    required String leagueId,
    required String tournamentId,
    required String matchdayId,
  }) async {
    try {
      await _datasource.processGroupsMatchday(
        leagueId: leagueId,
        tournamentId: tournamentId,
        matchdayId: matchdayId,
      );
    } catch (error) {
      throw AppExceptionMapper.map(error);
    }
  }

  @override
  Future<void> closeGroupsPhaseAndSeedBracket({
    required String leagueId,
    required String tournamentId,
  }) async {
    try {
      await _datasource.closeGroupsPhaseAndSeedBracket(
        leagueId: leagueId,
        tournamentId: tournamentId,
      );
    } catch (error) {
      throw AppExceptionMapper.map(error);
    }
  }

  @override
  Future<void> refreshCampionatoStandings({
    required String leagueId,
    required String tournamentId,
    required List<String> matchdayIds,
  }) async {
    try {
      await _datasource.refreshCampionatoStandings(
        leagueId: leagueId,
        tournamentId: tournamentId,
        matchdayIds: matchdayIds,
      );
    } catch (error) {
      throw AppExceptionMapper.map(error);
    }
  }
}
