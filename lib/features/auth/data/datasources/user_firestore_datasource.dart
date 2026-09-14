import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/user_role.dart';

/// Legge/scrive il profilo utente in `users/{uid}`. Unico punto che
/// conosce la forma del documento Firestore per questa entità.
class UserFirestoreDatasource {
  UserFirestoreDatasource(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(FirestorePaths.users);

  Future<bool> isUsernameTaken(String username) async {
    final snapshot =
        await _users.where('username', isEqualTo: username).limit(1).get();
    return snapshot.docs.isNotEmpty;
  }

  Future<void> createUser(AppUser user) {
    return _users.doc(user.id).set({
      'email': user.email,
      'username': user.username,
      'firstName': user.firstName,
      'lastName': user.lastName,
      'photoUrl': user.photoUrl,
      'referralCode': user.referralCode,
      'referredBy': user.referredBy,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'role': user.role.name,
      'totalPoints': user.totalPoints,
      'predictionsCount': user.predictionsCount,
      'correctPredictions': user.correctPredictions,
      'exactPredictions': user.exactPredictions,
      'successRate': user.successRate,
      'isActive': user.isActive,
      'leagueCount': user.leagueCount,
    });
  }

  Future<void> deleteUser(String uid) => _users.doc(uid).delete();

  Future<AppUser?> getUser(String uid) async {
    final doc = await _users.doc(uid).get();
    return _fromDoc(doc);
  }

  Stream<AppUser?> watchUser(String uid) {
    return _users.doc(uid).snapshots().map(_fromDoc);
  }

  /// Classifica generale: utenti attivi ordinati per punti totali
  /// decrescenti. Letto da tutti gli utenti autenticati (regola `users`
  /// già lo permette), non richiede una collection separata per l'MVP.
  Stream<List<AppUser>> watchLeaderboard({int limit = 100}) {
    return _users
        .where('isActive', isEqualTo: true)
        .orderBy('totalPoints', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => _fromDoc(doc)!).toList());
  }

  Future<void> updateProfile(
    String uid, {
    String? firstName,
    String? lastName,
    String? photoUrl,
  }) {
    return _users.doc(uid).update({
      if (firstName != null) 'firstName': firstName,
      if (lastName != null) 'lastName': lastName,
      if (photoUrl != null) 'photoUrl': photoUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  AppUser? _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) return null;

    final createdAt = data['createdAt'];
    final updatedAt = data['updatedAt'];

    return AppUser(
      id: doc.id,
      email: data['email'] as String? ?? '',
      username: data['username'] as String? ?? '',
      firstName: data['firstName'] as String? ?? '',
      lastName: data['lastName'] as String? ?? '',
      photoUrl: data['photoUrl'] as String?,
      referralCode: data['referralCode'] as String? ?? '',
      referredBy: data['referredBy'] as String?,
      createdAt: createdAt is Timestamp ? createdAt.toDate() : DateTime.now(),
      updatedAt: updatedAt is Timestamp ? updatedAt.toDate() : DateTime.now(),
      role: UserRole.fromString(data['role'] as String?),
      totalPoints: (data['totalPoints'] as num?)?.toInt() ?? 0,
      predictionsCount: (data['predictionsCount'] as num?)?.toInt() ?? 0,
      correctPredictions: (data['correctPredictions'] as num?)?.toInt() ?? 0,
      exactPredictions: (data['exactPredictions'] as num?)?.toInt() ?? 0,
      successRate: (data['successRate'] as num?)?.toDouble() ?? 0.0,
      isActive: data['isActive'] as bool? ?? true,
      leagueCount: (data['leagueCount'] as num?)?.toInt() ?? 0,
    );
  }
}
