import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../../../data/models/league.dart';
import '../../../../data/models/league_matchday_config.dart';
import '../../../../data/models/league_member.dart';
import '../../../../data/models/scoring_config.dart';

class LeagueFirestoreDatasource {
  LeagueFirestoreDatasource(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _leagues =>
      _firestore.collection(FirestorePaths.leagues);

  CollectionReference<Map<String, dynamic>> _members(String leagueId) =>
      _leagues
          .doc(leagueId)
          .collection(FirestorePaths.leagueMembersSubcollection);

  CollectionReference<Map<String, dynamic>> _matchdayConfigs(
          String leagueId) =>
      _leagues
          .doc(leagueId)
          .collection(FirestorePaths.leagueMatchdayConfigSubcollection);

  DocumentReference<Map<String, dynamic>> _userRef(String userId) =>
      _firestore.collection(FirestorePaths.users).doc(userId);

  /// Vero se [userId] è membro di almeno una lega: usato per il gate
  /// "serve una lega per pronosticare" prima di mostrare la schedina.
  Future<bool> hasAnyLeague(String userId) async {
    final snapshot = await _firestore
        .collectionGroup(FirestorePaths.leagueMembersSubcollection)
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  Future<bool> isInviteCodeTaken(String inviteCode) async {
    final snapshot = await _leagues
        .where('inviteCode', isEqualTo: inviteCode)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  Future<League?> findByInviteCode(String inviteCode) async {
    final snapshot = await _leagues
        .where('inviteCode', isEqualTo: inviteCode)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return _leagueFromDoc(snapshot.docs.first);
  }

  Future<League?> getLeague(String leagueId) async {
    final doc = await _leagues.doc(leagueId).get();
    return _leagueFromDoc(doc);
  }

  Future<bool> isMember(String leagueId, String userId) async {
    final doc = await _members(leagueId).doc(userId).get();
    return doc.exists;
  }

  /// Crea la lega e aggiunge automaticamente il proprietario come primo
  /// membro, in un'unica transazione: o succede tutto o niente.
  Future<String> createLeague({
    required String name,
    String? description,
    required String ownerId,
    required String ownerUsername,
    String? ownerPhotoUrl,
    required String inviteCode,
  }) async {
    final leagueRef = _leagues.doc();
    final memberRef = _members(leagueRef.id).doc(ownerId);
    final userRef = _userRef(ownerId);

    await _firestore.runTransaction((transaction) async {
      transaction.set(leagueRef, {
        'name': name,
        'description': description,
        'ownerId': ownerId,
        'inviteCode': inviteCode,
        'imageUrl': null,
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'memberCount': 1,
      });
      transaction.set(memberRef, {
        'userId': ownerId,
        'leagueId': leagueRef.id,
        'username': ownerUsername,
        'photoUrl': ownerPhotoUrl,
        'joinedAt': FieldValue.serverTimestamp(),
        'role': LeagueMemberRole.owner.name,
        'totalPoints': 0,
      });
      transaction.update(userRef, {
        'leagueCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    return leagueRef.id;
  }

  /// Aggiunge [userId] come membro di [leagueId], incrementando
  /// `memberCount` in modo atomico.
  Future<void> joinLeague({
    required String leagueId,
    required String userId,
    required String username,
    String? photoUrl,
  }) async {
    final leagueRef = _leagues.doc(leagueId);
    final memberRef = _members(leagueId).doc(userId);
    final userRef = _userRef(userId);

    await _firestore.runTransaction((transaction) async {
      final existing = await transaction.get(memberRef);
      if (existing.exists) return;

      transaction.set(memberRef, {
        'userId': userId,
        'leagueId': leagueId,
        'username': username,
        'photoUrl': photoUrl,
        'joinedAt': FieldValue.serverTimestamp(),
        'role': LeagueMemberRole.member.name,
        'totalPoints': 0,
      });
      transaction.update(leagueRef, {'memberCount': FieldValue.increment(1)});
      transaction.update(userRef, {
        'leagueCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> updateScoringConfig(String leagueId, ScoringConfig config) {
    return _leagues.doc(leagueId).update({'scoringConfig': config.toMap()});
  }

  Stream<LeagueMatchdayConfig> watchMatchdayConfig(
      String leagueId, String matchdayId) {
    return _matchdayConfigs(leagueId).doc(matchdayId).snapshots().map((doc) {
      final data = doc.data();
      final excluded = (data?['excludedMatchIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[];
      return LeagueMatchdayConfig(
        leagueId: leagueId,
        matchdayId: matchdayId,
        excludedMatchIds: excluded,
      );
    });
  }

  Future<void> setExcludedMatches(
      String leagueId, String matchdayId, List<String> excludedMatchIds) {
    return _matchdayConfigs(leagueId).doc(matchdayId).set({
      'leagueId': leagueId,
      'matchdayId': matchdayId,
      'excludedMatchIds': excludedMatchIds,
    });
  }

  /// Rimuove il membro e decrementa `memberCount`: due scritture separate
  /// (non una transazione) perché le Security Rules valutano ciascuna con
  /// un permesso diverso (delete sul membro, update sulla lega) e una
  /// `runTransaction` le eseguirebbe comunque come scritture indipendenti
  /// ai fini delle regole — la sequenzialità qui è sufficiente.
  Future<void> removeMember(String leagueId, String userId) async {
    await _members(leagueId).doc(userId).delete();
    await _leagues.doc(leagueId).update({
      'memberCount': FieldValue.increment(-1),
    });
  }

  Stream<List<LeagueMember>> watchMembers(String leagueId) {
    return _members(leagueId)
        .orderBy('totalPoints', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_memberFromDoc).toList());
  }

  /// Leghe di cui [userId] è membro, tramite collection group query sulle
  /// subcollection `members` di tutte le leghe.
  Stream<List<League>> watchMyLeagues(String userId) {
    return _firestore
        .collectionGroup(FirestorePaths.leagueMembersSubcollection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .asyncMap((snapshot) async {
      final leagueIds =
          snapshot.docs.map((doc) => doc.data()['leagueId'] as String).toSet();
      final leagues = await Future.wait(leagueIds.map(getLeague));
      return leagues.whereType<League>().toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }

  League? _leagueFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) return null;
    final createdAt = data['createdAt'];
    return League(
      id: doc.id,
      name: data['name'] as String? ?? '',
      description: data['description'] as String?,
      ownerId: data['ownerId'] as String? ?? '',
      inviteCode: data['inviteCode'] as String? ?? '',
      imageUrl: data['imageUrl'] as String?,
      createdAt: createdAt is Timestamp ? createdAt.toDate() : DateTime.now(),
      isActive: data['isActive'] as bool? ?? true,
      memberCount: (data['memberCount'] as num?)?.toInt() ?? 1,
      scoringConfig:
          ScoringConfig.fromMap(data['scoringConfig'] as Map<String, dynamic>?),
    );
  }

  LeagueMember _memberFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final joinedAt = data['joinedAt'];
    return LeagueMember(
      userId: data['userId'] as String? ?? doc.id,
      leagueId: data['leagueId'] as String? ?? '',
      username: data['username'] as String? ?? '',
      photoUrl: data['photoUrl'] as String?,
      joinedAt: joinedAt is Timestamp ? joinedAt.toDate() : DateTime.now(),
      role: data['role'] == 'owner'
          ? LeagueMemberRole.owner
          : LeagueMemberRole.member,
      totalPoints: (data['totalPoints'] as num?)?.toInt() ?? 0,
      last5: (data['last5'] as List<dynamic>?)?.map((e) => e as bool).toList() ??
          const <bool>[],
      exactCount: (data['exactCount'] as num?)?.toInt() ?? 0,
    );
  }
}
