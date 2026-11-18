import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/competition.dart';
import '../models/match.dart';
import '../models/matchday.dart';
import '../models/team.dart';
import '../models/team_standing.dart';
import 'football_data_service.dart';

/// Implementazione reale di [FootballDataService]: legge i dati di
/// competizioni/squadre/giornate/partite/classifica da Firestore, dove
/// arrivano scritti a mano dall'admin globale tramite il pannello admin
/// (vedi AdminFootballDatasource) — nessuna dipendenza da un'API calcistica
/// esterna, per restare a costo zero (piano Firebase Spark).
class FirestoreFootballDataService implements FootballDataService {
  FirestoreFootballDataService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<List<Competition>> getCompetitions() async {
    final snapshot = await _firestore.collection('competitions').get();
    return snapshot.docs.map(_competitionFromDoc).toList();
  }

  @override
  Future<List<Team>> getTeams({required String competitionId}) async {
    final snapshot =
        await _competitionRef(competitionId).collection('teams').get();
    return snapshot.docs.map((doc) => _teamFromMap(doc.data())).toList();
  }

  @override
  Future<List<Matchday>> getMatchdays({required String competitionId}) async {
    final snapshot = await _competitionRef(competitionId)
        .collection('matchdays')
        .orderBy('number')
        .get();
    return snapshot.docs.map(_matchdayFromDoc).toList();
  }

  @override
  Future<List<Match>> getMatches(
      {required String competitionId, String? matchdayId}) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection('matches')
        .where('competitionId', isEqualTo: competitionId);
    if (matchdayId != null) {
      query = query.where('matchdayId', isEqualTo: matchdayId);
    }
    final snapshot = await query.get();
    return snapshot.docs.map(_matchFromData).toList();
  }

  @override
  Future<Match?> getMatch(String matchId) async {
    final doc = await _firestore.collection('matches').doc(matchId).get();
    if (!doc.exists) return null;
    return _matchFromData(doc);
  }

  @override
  Future<List<TeamStanding>> getStandings(
      {required String competitionId}) async {
    final doc =
        await _firestore.collection('standings').doc(competitionId).get();
    if (!doc.exists) return [];
    final rows = doc.data()?['rows'] as List<dynamic>? ?? [];
    return rows.map((raw) {
      final row = raw as Map<String, dynamic>;
      return TeamStanding(
        teamId: row['teamId'] as String,
        teamName: row['teamName'] as String,
        position: row['position'] as int,
        played: row['played'] as int,
        won: row['won'] as int,
        drawn: row['drawn'] as int,
        lost: row['lost'] as int,
        goalsFor: row['goalsFor'] as int,
        goalsAgainst: row['goalsAgainst'] as int,
        points: row['points'] as int,
      );
    }).toList();
  }

  @override
  Future<List<Match>> getResults(
      {required String competitionId, String? matchdayId}) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection('matches')
        .where('competitionId', isEqualTo: competitionId)
        .where('status', isEqualTo: MatchStatus.finished.name);
    if (matchdayId != null) {
      query = query.where('matchdayId', isEqualTo: matchdayId);
    }
    final snapshot = await query.get();
    return snapshot.docs.map(_matchFromData).toList();
  }

  DocumentReference<Map<String, dynamic>> _competitionRef(
          String competitionId) =>
      _firestore.collection('competitions').doc(competitionId);

  Competition _competitionFromDoc(
      QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final now = DateTime.now();
    return Competition(
      id: doc.id,
      name: data['name'] as String,
      season: data['season'] as String,
      sport: data['sport'] as String? ?? 'calcio',
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? now,
      endDate: (data['endDate'] as Timestamp?)?.toDate() ?? now,
      status: _enumFrom(CompetitionStatus.values, data['status'] as String?,
          CompetitionStatus.active),
      entryFee: (data['entryFee'] as num?) ?? 0,
      currency: data['currency'] as String? ?? 'EUR',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? now,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? now,
    );
  }

  Matchday _matchdayFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return Matchday(
      id: doc.id,
      competitionId: data['competitionId'] as String,
      number: data['number'] as int,
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      status: _enumFrom(MatchdayStatus.values, data['status'] as String?,
          MatchdayStatus.upcoming),
      predictionDeadline: (data['predictionDeadline'] as Timestamp).toDate(),
    );
  }

  Match _matchFromData(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    final now = DateTime.now();
    final overUnderRaw = data['overUnder'] as Map<String, dynamic>?;
    return Match(
      id: doc.id,
      competitionId: data['competitionId'] as String,
      matchdayId: data['matchdayId'] as String,
      homeTeam: _teamFromMap(data['homeTeam'] as Map<String, dynamic>),
      awayTeam: _teamFromMap(data['awayTeam'] as Map<String, dynamic>),
      kickoff: (data['kickoff'] as Timestamp).toDate(),
      status: _enumFrom(
          MatchStatus.values, data['status'] as String?, MatchStatus.scheduled),
      homeScore: data['homeScore'] as int?,
      awayScore: data['awayScore'] as int?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? now,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? now,
      predictionLocked: data['predictionLocked'] as bool? ?? true,
      winner: data['winner'] == null
          ? null
          : _enumFrom(
              MatchWinner.values, data['winner'] as String, MatchWinner.draw),
      goalNoGoal: data['goalNoGoal'] as bool?,
      overUnder:
          overUnderRaw?.map((key, value) => MapEntry(key, value as bool)),
    );
  }

  Team _teamFromMap(Map<String, dynamic> data) => Team(
        id: data['id'] as String,
        name: data['name'] as String,
        shortName: data['shortName'] as String,
        logoUrl: data['logoUrl'] as String?,
        stadium: data['stadium'] as String? ?? '-',
        city: data['city'] as String? ?? '-',
      );

  T _enumFrom<T extends Enum>(List<T> values, String? name, T fallback) {
    if (name == null) return fallback;
    return values.firstWhere((value) => value.name == name,
        orElse: () => fallback);
  }
}
