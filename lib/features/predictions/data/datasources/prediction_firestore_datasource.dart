import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../domain/entities/prediction.dart';

class PredictionFirestoreDatasource {
  PredictionFirestoreDatasource(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _predictions =>
      _firestore.collection(FirestorePaths.predictions);

  String _docId(String userId, String matchId) => '${userId}_$matchId';

  Future<void> upsert({
    required String userId,
    required String matchId,
    required String competitionId,
    required String matchdayId,
    int? exactHomeScore,
    int? exactAwayScore,
    String? result1x2,
    bool? goalNoGoal,
    Map<String, bool>? overUnder,
  }) {
    final docId = _docId(userId, matchId);
    return _predictions.doc(docId).set({
      'userId': userId,
      'matchId': matchId,
      'competitionId': competitionId,
      'matchdayId': matchdayId,
      'exactHomeScore': exactHomeScore,
      'exactAwayScore': exactAwayScore,
      'result1x2': result1x2,
      'goalNoGoal': goalNoGoal,
      'overUnder': overUnder,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
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
      exactHomeScore: (data['exactHomeScore'] as num?)?.toInt(),
      exactAwayScore: (data['exactAwayScore'] as num?)?.toInt(),
      result1x2: data['result1x2'] as String?,
      goalNoGoal: data['goalNoGoal'] as bool?,
      overUnder: (data['overUnder'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key, value as bool),
      ),
      createdAt: createdAt is Timestamp ? createdAt.toDate() : DateTime.now(),
      updatedAt: updatedAt is Timestamp ? updatedAt.toDate() : DateTime.now(),
    );
  }
}
