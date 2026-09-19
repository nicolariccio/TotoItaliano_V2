import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/league_tournament.dart';
import '../../../../data/models/tournament_bracket_tie.dart';
import '../../../../data/models/tournament_group.dart';
import '../../../../data/models/tournament_participant.dart';
import '../../data/datasources/tournament_firestore_datasource.dart';
import '../../data/repositories/tournament_repository_impl.dart';
import '../../domain/repositories/tournament_repository.dart';

typedef TournamentKey = ({String leagueId, String tournamentId});

final Provider<TournamentFirestoreDatasource>
    tournamentFirestoreDatasourceProvider =
    Provider<TournamentFirestoreDatasource>(
  (ref) => TournamentFirestoreDatasource(FirebaseFirestore.instance),
);

final Provider<TournamentRepository> tournamentRepositoryProvider =
    Provider<TournamentRepository>(
  (ref) => TournamentRepositoryImpl(
    ref.watch(tournamentFirestoreDatasourceProvider),
  ),
);

final StreamProviderFamily<List<LeagueTournament>, String>
    leagueTournamentsProvider =
    StreamProvider.family<List<LeagueTournament>, String>(
  (ref, leagueId) => ref.watch(tournamentRepositoryProvider).watchTournaments(leagueId),
);

final FutureProviderFamily<LeagueTournament?, TournamentKey>
    tournamentByIdProvider =
    FutureProvider.family<LeagueTournament?, TournamentKey>(
  (ref, key) =>
      ref.watch(tournamentRepositoryProvider).getTournament(key.leagueId, key.tournamentId),
);

final StreamProviderFamily<List<TournamentParticipant>, TournamentKey>
    tournamentParticipantsProvider =
    StreamProvider.family<List<TournamentParticipant>, TournamentKey>(
  (ref, key) => ref
      .watch(tournamentRepositoryProvider)
      .watchParticipants(key.leagueId, key.tournamentId),
);

final StreamProviderFamily<List<BracketTie>, TournamentKey>
    tournamentBracketProvider =
    StreamProvider.family<List<BracketTie>, TournamentKey>(
  (ref, key) =>
      ref.watch(tournamentRepositoryProvider).watchBracket(key.leagueId, key.tournamentId),
);

final StreamProviderFamily<List<TournamentGroup>, TournamentKey>
    tournamentGroupsProvider =
    StreamProvider.family<List<TournamentGroup>, TournamentKey>(
  (ref, key) =>
      ref.watch(tournamentRepositoryProvider).watchGroups(key.leagueId, key.tournamentId),
);
