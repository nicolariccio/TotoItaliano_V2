import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../../../data/models/competition.dart';
import '../../../../data/models/match.dart';
import '../../../../data/models/matchday.dart';
import '../../../../data/models/team.dart';

/// Scritture dirette sui dati calcistici ufficiali (competizioni, squadre,
/// giornate, partite): eseguite solo da un admin globale, autorizzate dalle
/// Security Rules (`isGlobalAdmin()`), non dal client. Le letture restano a
/// carico di [FirestoreFootballDataService], usato da tutta l'app.
class AdminFootballDatasource {
  AdminFootballDatasource(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _competitions =>
      _firestore.collection(FirestorePaths.competitions);

  CollectionReference<Map<String, dynamic>> get _matches =>
      _firestore.collection(FirestorePaths.matches);

  CollectionReference<Map<String, dynamic>> _teams(String competitionId) =>
      _competitions.doc(competitionId).collection(FirestorePaths.teams);

  CollectionReference<Map<String, dynamic>> _matchdays(
          String competitionId) =>
      _competitions
          .doc(competitionId)
          .collection(FirestorePaths.matchdaysSubcollection);

  Future<String> createCompetition({
    required String name,
    required String season,
  }) async {
    final now = DateTime.now();
    final ref = await _competitions.add({
      'name': name,
      'season': season,
      'sport': 'calcio',
      'startDate': Timestamp.fromDate(now),
      'endDate': Timestamp.fromDate(now.add(const Duration(days: 300))),
      'status': CompetitionStatus.active.name,
      'entryFee': 0,
      'currency': 'EUR',
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    });
    return ref.id;
  }

  /// Importa in blocco le squadre passate (tipicamente [serieATeams]) nella
  /// competizione: un unico batch, id squadra = id documento.
  Future<void> seedTeams(String competitionId, List<Team> teams) async {
    final batch = _firestore.batch();
    for (final team in teams) {
      batch.set(_teams(competitionId).doc(team.id), _teamToMap(team));
    }
    await batch.commit();
  }

  Future<String> createMatchday({
    required String competitionId,
    required int number,
    required DateTime startDate,
    required DateTime endDate,
    required DateTime predictionDeadline,
    MatchdayStatus status = MatchdayStatus.upcoming,
  }) async {
    final ref = await _matchdays(competitionId).add({
      'competitionId': competitionId,
      'number': number,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'status': status.name,
      'predictionDeadline': Timestamp.fromDate(predictionDeadline),
    });
    return ref.id;
  }

  Future<void> setMatchdayStatus(
      String competitionId, String matchdayId, MatchdayStatus status) {
    return _matchdays(competitionId)
        .doc(matchdayId)
        .update({'status': status.name});
  }

  Future<String> createMatch({
    required String competitionId,
    required String matchdayId,
    required Team homeTeam,
    required Team awayTeam,
    required DateTime kickoff,
  }) async {
    final now = DateTime.now();
    final ref = await _matches.add({
      'competitionId': competitionId,
      'matchdayId': matchdayId,
      'homeTeam': _teamToMap(homeTeam),
      'awayTeam': _teamToMap(awayTeam),
      'kickoff': Timestamp.fromDate(kickoff),
      'status': MatchStatus.scheduled.name,
      'homeScore': null,
      'awayScore': null,
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
      'predictionLocked': false,
      'winner': null,
      'goalNoGoal': null,
      'overUnder': null,
    });
    return ref.id;
  }

  /// Segna il risultato ufficiale: calcola `winner`/`goalNoGoal`/`overUnder`
  /// dai punteggi, blocca ulteriori pronostici. Il ricalcolo dei punti dei
  /// pronostici già salvati è un passo separato (vedi
  /// ScoringRecomputeDatasource), chiamato subito dopo dal controller.
  Future<Match> setMatchResult({
    required Match match,
    required int homeScore,
    required int awayScore,
  }) async {
    final winner = homeScore > awayScore
        ? MatchWinner.home
        : (homeScore < awayScore ? MatchWinner.away : MatchWinner.draw);
    final goalNoGoal = homeScore > 0 && awayScore > 0;
    final totalGoals = homeScore + awayScore;
    final overUnder = {
      '1.5': totalGoals > 1.5,
      '2.5': totalGoals > 2.5,
      '3.5': totalGoals > 3.5,
    };

    await _matches.doc(match.id).update({
      'status': MatchStatus.finished.name,
      'homeScore': homeScore,
      'awayScore': awayScore,
      'winner': winner.name,
      'goalNoGoal': goalNoGoal,
      'overUnder': overUnder,
      'predictionLocked': true,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });

    return match.copyWith(
      status: MatchStatus.finished,
      homeScore: homeScore,
      awayScore: awayScore,
      winner: winner,
      goalNoGoal: goalNoGoal,
      overUnder: overUnder,
      predictionLocked: true,
    );
  }

  Map<String, dynamic> _teamToMap(Team team) => {
        'id': team.id,
        'name': team.name,
        'shortName': team.shortName,
        'logoUrl': team.logoUrl,
        'stadium': team.stadium,
        'city': team.city,
      };
}
