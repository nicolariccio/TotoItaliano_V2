import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../domain/entities/prediction.dart';

/// Un pronostico da salvare come parte della schedina: la scelta di un
/// solo mercato per una partita.
class PredictionPick {
  const PredictionPick({
    required this.matchId,
    required this.competitionId,
    required this.matchdayId,
    required this.market,
    this.result1x2Value,
    this.goalNoGoalValue,
    this.overUnder25Value,
    this.exactHomeScore,
    this.exactAwayScore,
  });

  final String matchId;
  final String competitionId;
  final String matchdayId;
  final PredictionMarket market;
  final String? result1x2Value;
  final bool? goalNoGoalValue;
  final bool? overUnder25Value;
  final int? exactHomeScore;
  final int? exactAwayScore;
}

class PredictionFirestoreDatasource {
  PredictionFirestoreDatasource(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _predictions =>
      _firestore.collection(FirestorePaths.predictions);

  String _docId(String userId, String matchId) => '${userId}_$matchId';

  /// Salva l'intera schedina (uno o più pronostici) in un'unica scrittura
  /// atomica: o vengono salvati tutti, o nessuno.
  Future<void> saveSchedina(String userId, List<PredictionPick> picks) async {
    final batch = _firestore.batch();
    for (final pick in picks) {
      final docRef = _predictions.doc(_docId(userId, pick.matchId));
      batch.set(docRef, {
        'userId': userId,
        'matchId': pick.matchId,
        'competitionId': pick.competitionId,
        'matchdayId': pick.matchdayId,
        'market': pick.market.name,
        'result1x2Value': pick.result1x2Value,
        'goalNoGoalValue': pick.goalNoGoalValue,
        'overUnder25Value': pick.overUnder25Value,
        'exactHomeScore': pick.exactHomeScore,
        'exactAwayScore': pick.exactAwayScore,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    await batch.commit();
  }

  Future<Prediction?> get(String userId, String matchId) async {
    final doc = await _predictions.doc(_docId(userId, matchId)).get();
    return _fromDoc(doc);
  }

  Stream<Prediction?> watch(String userId, String matchId) {
    return _predictions.doc(_docId(userId, matchId)).snapshots().map(_fromDoc);
  }

  Stream<List<Prediction>> watchForUser(String userId) {
    return _predictions.where('userId', isEqualTo: userId).snapshots().map(
          (snapshot) => snapshot.docs.map(_fromDocRequired).toList(),
        );
  }

  Stream<List<Prediction>> watchForUserAndMatchday(String userId, String matchdayId) {
    return _predictions
        .where('userId', isEqualTo: userId)
        .where('matchdayId', isEqualTo: matchdayId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_fromDocRequired).toList());
  }

  Prediction? _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) return null;
    return _mapToPrediction(doc.id, data);
  }

  Prediction _fromDocRequired(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    return _mapToPrediction(doc.id, doc.data());
  }

  Prediction _mapToPrediction(String id, Map<String, dynamic> data) {
    final createdAt = data['createdAt'];
    final updatedAt = data['updatedAt'];
    return Prediction(
      id: id,
      userId: data['userId'] as String? ?? '',
      matchId: data['matchId'] as String? ?? '',
      competitionId: data['competitionId'] as String? ?? '',
      matchdayId: data['matchdayId'] as String? ?? '',
      market: _marketFromString(data['market'] as String?),
      result1x2Value: data['result1x2Value'] as String?,
      goalNoGoalValue: data['goalNoGoalValue'] as bool?,
      overUnder25Value: data['overUnder25Value'] as bool?,
      exactHomeScore: (data['exactHomeScore'] as num?)?.toInt(),
      exactAwayScore: (data['exactAwayScore'] as num?)?.toInt(),
      createdAt: createdAt is Timestamp ? createdAt.toDate() : DateTime.now(),
      updatedAt: updatedAt is Timestamp ? updatedAt.toDate() : DateTime.now(),
    );
  }

  PredictionMarket _marketFromString(String? value) {
    return PredictionMarket.values.firstWhere(
      (m) => m.name == value,
      orElse: () => PredictionMarket.result1x2,
    );
  }
}
