import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../../../data/models/league_tournament.dart';
import '../../../../data/models/tournament_bracket_tie.dart';
import '../../../../data/models/tournament_group.dart';
import '../../../../data/models/tournament_participant.dart';
import '../../../../data/scoring/tournament_scoring.dart';
import '../../domain/repositories/tournament_repository.dart';

class TournamentFirestoreDatasource {
  TournamentFirestoreDatasource(this._firestore)
      : _scoring = TournamentScoring(_firestore);

  final FirebaseFirestore _firestore;
  final TournamentScoring _scoring;

  CollectionReference<Map<String, dynamic>> _tournaments(String leagueId) =>
      _firestore
          .collection(FirestorePaths.leagues)
          .doc(leagueId)
          .collection(FirestorePaths.tournamentsSubcollection);

  CollectionReference<Map<String, dynamic>> _participants(
          String leagueId, String tournamentId) =>
      _tournaments(leagueId)
          .doc(tournamentId)
          .collection(FirestorePaths.tournamentParticipantsSubcollection);

  CollectionReference<Map<String, dynamic>> _bracket(
          String leagueId, String tournamentId) =>
      _tournaments(leagueId)
          .doc(tournamentId)
          .collection(FirestorePaths.tournamentBracketSubcollection);

  CollectionReference<Map<String, dynamic>> _groups(
          String leagueId, String tournamentId) =>
      _tournaments(leagueId)
          .doc(tournamentId)
          .collection(FirestorePaths.tournamentGroupsSubcollection);

  // ── Lettura ──────────────────────────────────────────────────────────────

  Stream<List<LeagueTournament>> watchTournaments(String leagueId) {
    return _tournaments(leagueId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => _tournamentFromDoc(d.id, d.data())).toList());
  }

  Future<LeagueTournament?> getTournament(
      String leagueId, String tournamentId) async {
    final doc = await _tournaments(leagueId).doc(tournamentId).get();
    final data = doc.data();
    if (data == null) return null;
    return _tournamentFromDoc(doc.id, data);
  }

  Stream<List<TournamentParticipant>> watchParticipants(
      String leagueId, String tournamentId) {
    return _participants(leagueId, tournamentId)
        .orderBy('points', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => _participantFromData(d.data())).toList());
  }

  Stream<List<BracketTie>> watchBracket(String leagueId, String tournamentId) {
    return _bracket(leagueId, tournamentId).snapshots().map((s) {
      final ties = s.docs.map((d) => _tieFromData(d.data())).toList()
        ..sort((a, b) =>
            a.round != b.round ? a.round.compareTo(b.round) : a.slot.compareTo(b.slot));
      return ties;
    });
  }

  Stream<List<TournamentGroup>> watchGroups(
      String leagueId, String tournamentId) {
    return _groups(leagueId, tournamentId).snapshots().map(
        (s) => s.docs.map((d) => _groupFromData(d.id, d.data())).toList()
          ..sort((a, b) => a.id.compareTo(b.id)));
  }

  // ── Creazione ────────────────────────────────────────────────────────────

  /// [seedMembers] deve contenere esattamente i membri in
  /// [participantUserIds] (username/foto per la denormalizzazione, punti
  /// per il seeding del tabellone Coppa) — li passa il chiamante perché
  /// sono già disponibili lì (LeagueMember già osservato altrove).
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
    final ref = _tournaments(leagueId).doc();
    final batch = _firestore.batch();

    batch.set(ref, {
      'leagueId': leagueId,
      'name': name,
      'type': type.name,
      'participantUserIds': participantUserIds,
      'status': TournamentStatus.active.name,
      'createdAt': FieldValue.serverTimestamp(),
      'createdFromMatchdayId': createdFromMatchdayId,
      'coppaFormat': coppaFormat?.name,
      'phase': CoppaPhase.groups.name,
      'groupSize': groupSize,
      'advancePerGroup': advancePerGroup,
      'eliminationsPerMatchday': eliminationsPerMatchday,
      'tiebreakOrder': [for (final t in tiebreakOrder) t.name],
      'lastProcessedMatchdayId': null,
    });

    final byId = {for (final m in seedMembers) m.userId: m};
    for (final userId in participantUserIds) {
      final member = byId[userId];
      batch.set(_participants(leagueId, ref.id).doc(userId), {
        'userId': userId,
        'username': member?.username ?? '',
        'photoUrl': member?.photoUrl,
        'points': 0,
        'active': true,
        'eliminatedAtMatchdayId': null,
      });
    }

    if (type == TournamentType.coppa && coppaFormat == CoppaFormat.knockout) {
      batch.update(ref, {'phase': CoppaPhase.knockout.name});
      final seeded = [...participantUserIds]
        ..sort((a, b) =>
            (byId[b]?.totalPoints ?? 0).compareTo(byId[a]?.totalPoints ?? 0));
      for (final tie in TournamentScoring.generateFirstRound(seeded)) {
        batch.set(_bracket(leagueId, ref.id).doc(tie.id), _tieToMap(tie));
      }
    } else if (type == TournamentType.coppa &&
        coppaFormat == CoppaFormat.groupsThenKnockout) {
      final size = groupSize ?? 4;
      final seeded = [...participantUserIds]
        ..sort((a, b) =>
            (byId[b]?.totalPoints ?? 0).compareTo(byId[a]?.totalPoints ?? 0));
      var groupIndex = 0;
      for (var i = 0; i < seeded.length; i += size) {
        final groupId = String.fromCharCode('A'.codeUnitAt(0) + groupIndex);
        final members = seeded.sublist(i, (i + size).clamp(0, seeded.length));
        batch.set(_groups(leagueId, ref.id).doc(groupId), {
          'participantUserIds': members,
          'cumulativePoints': {for (final m in members) m: 0},
        });
        groupIndex++;
      }
    }

    await batch.commit();
    return ref.id;
  }

  // ── Highlander ───────────────────────────────────────────────────────────

  Future<HighlanderEliminationPreview> previewHighlanderMatchday({
    required String leagueId,
    required String tournamentId,
    required String matchdayId,
  }) async {
    final tournament = await getTournament(leagueId, tournamentId);
    if (tournament == null) {
      return HighlanderEliminationPreview(
          matchdayId: matchdayId, pointsByUser: const {}, eliminatedUserIds: const []);
    }
    final participantsSnap =
        await _participants(leagueId, tournamentId).get();
    final active = participantsSnap.docs
        .map((d) => _participantFromData(d.data()))
        .where((p) => p.active)
        .toList();

    final points = await _scoring.pointsByUserForMatchday(
        leagueId: leagueId, matchdayId: matchdayId);
    final pointsByUser = {for (final p in active) p.userId: points[p.userId] ?? 0};

    final toEliminate = tournament.eliminationsPerMatchday.clamp(0, active.length);
    final eliminated = _pickWorst(
      pointsByUser: pointsByUser,
      count: toEliminate,
      tiebreakOrder: tournament.tiebreakOrder,
      ctx: await _tiebreakContext(
          leagueId, active.map((p) => p.userId).toList(), matchdayId),
    );

    return HighlanderEliminationPreview(
      matchdayId: matchdayId,
      pointsByUser: pointsByUser,
      eliminatedUserIds: eliminated,
    );
  }

  Future<void> confirmHighlanderMatchday({
    required String leagueId,
    required String tournamentId,
    required HighlanderEliminationPreview preview,
  }) async {
    final batch = _firestore.batch();
    for (final entry in preview.pointsByUser.entries) {
      final isEliminated = preview.eliminatedUserIds.contains(entry.key);
      final ref = _participants(leagueId, tournamentId).doc(entry.key);
      batch.update(ref, {
        'points': entry.value,
        if (isEliminated) 'active': false,
        if (isEliminated) 'eliminatedAtMatchdayId': preview.matchdayId,
      });
    }
    batch.update(_tournaments(leagueId).doc(tournamentId), {
      'lastProcessedMatchdayId': preview.matchdayId,
    });
    await batch.commit();

    final remainingActive = preview.pointsByUser.length - preview.eliminatedUserIds.length;
    if (remainingActive <= 1) {
      await _tournaments(leagueId)
          .doc(tournamentId)
          .update({'status': TournamentStatus.finished.name});
    }
  }

  /// Elimina i [count] peggiori per punti, applicando lo spareggio a un
  /// eventuale gruppo pareggiato a cavallo del taglio.
  List<String> _pickWorst({
    required Map<String, int> pointsByUser,
    required int count,
    required List<HighlanderTiebreak> tiebreakOrder,
    required TiebreakContext ctx,
  }) {
    if (count <= 0) return const [];
    final byPointsAsc = pointsByUser.keys.toList()
      ..sort((a, b) => pointsByUser[a]!.compareTo(pointsByUser[b]!));

    final eliminated = <String>[];
    var i = 0;
    while (i < byPointsAsc.length && eliminated.length < count) {
      final value = pointsByUser[byPointsAsc[i]]!;
      var j = i;
      while (j < byPointsAsc.length && pointsByUser[byPointsAsc[j]] == value) {
        j++;
      }
      final tiedGroup = byPointsAsc.sublist(i, j);
      final remainingSlots = count - eliminated.length;
      if (tiedGroup.length <= remainingSlots) {
        eliminated.addAll(tiedGroup);
      } else {
        // Il taglio cade dentro questo gruppo pareggiato: lo spareggio
        // decide chi dei pareggiati viene eliminato (i peggiori dello
        // spareggio, cioè la coda dell'ordinamento "migliore -> peggiore").
        final ranked = TournamentScoring.rankByTiebreak(tiedGroup, tiebreakOrder, ctx);
        eliminated.addAll(ranked.sublist(ranked.length - remainingSlots));
      }
      i = j;
    }
    return eliminated;
  }

  Future<TiebreakContext> _tiebreakContext(
      String leagueId, List<String> userIds, String matchdayId) async {
    final submittedAt = await _scoring.submissionTimesByUser(
        leagueId: leagueId, matchdayId: matchdayId);
    // "Punti giornata precedente" e "totale esatti stagionali" sono già
    // disponibili sul documento partecipante/membro in molti casi, ma qui
    // teniamoci semplici e derivali dal solo storico pronostici quando
    // servono davvero (raramente si arriva a questo criterio).
    return TiebreakContext(submittedAt: submittedAt);
  }

  // ── Coppa: tabellone ─────────────────────────────────────────────────────

  Future<void> assignMatchdayToRound({
    required String leagueId,
    required String tournamentId,
    required int round,
    required String matchdayId,
  }) async {
    final snapshot = await _bracket(leagueId, tournamentId)
        .where('round', isEqualTo: round)
        .get();
    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      final tie = _tieFromData(doc.data());
      if (tie.isBye || tie.isResolved) continue;
      batch.update(doc.reference, {'matchdayId': matchdayId});
    }
    await batch.commit();
  }

  Future<void> resolveBracketRound({
    required String leagueId,
    required String tournamentId,
    required int round,
  }) async {
    final snapshot = await _bracket(leagueId, tournamentId)
        .where('round', isEqualTo: round)
        .get();
    final ties = snapshot.docs.map((d) => (d.reference, _tieFromData(d.data()))).toList();

    final pointsByMatchday = <String, Map<String, int>>{};
    final batch = _firestore.batch();

    for (final (ref, tie) in ties) {
      if (tie.isResolved || tie.isBye) continue;
      final matchdayId = tie.matchdayId;
      if (matchdayId == null) continue;

      final points = pointsByMatchday[matchdayId] ??= await _scoring
          .pointsByUserForMatchday(leagueId: leagueId, matchdayId: matchdayId);
      final pointsA = points[tie.participantAId] ?? 0;
      final pointsB = points[tie.participantBId] ?? 0;

      String winnerId;
      if (pointsA != pointsB) {
        winnerId = pointsA > pointsB ? tie.participantAId! : tie.participantBId!;
      } else {
        final ctx = await _tiebreakContext(
            leagueId, [tie.participantAId!, tie.participantBId!], matchdayId);
        final ranked = TournamentScoring.rankByTiebreak(
            [tie.participantAId!, tie.participantBId!],
            TournamentScoring.defaultTiebreakOrder,
            ctx);
        winnerId = ranked.first;
      }

      batch.update(ref, {
        'pointsA': pointsA,
        'pointsB': pointsB,
        'winnerId': winnerId,
      });
    }
    await batch.commit();

    await _maybeGenerateNextRound(leagueId, tournamentId, round);
  }

  Future<void> _maybeGenerateNextRound(
      String leagueId, String tournamentId, int round) async {
    final snapshot = await _bracket(leagueId, tournamentId)
        .where('round', isEqualTo: round)
        .get();
    final ties = snapshot.docs.map((d) => _tieFromData(d.data())).toList()
      ..sort((a, b) => a.slot.compareTo(b.slot));
    if (ties.isEmpty || ties.any((t) => !t.isResolved)) return;

    if (ties.length == 1) {
      // Era la finale.
      await _tournaments(leagueId)
          .doc(tournamentId)
          .update({'status': TournamentStatus.finished.name});
      return;
    }

    final batch = _firestore.batch();
    for (var i = 0; i < ties.length; i += 2) {
      final winnerA = ties[i].winnerId!;
      final winnerB = ties[i + 1].winnerId!;
      final nextRound = round + 1;
      final nextSlot = i ~/ 2;
      batch.set(
        _bracket(leagueId, tournamentId).doc('r$nextRound-s$nextSlot'),
        {
          'round': nextRound,
          'slot': nextSlot,
          'participantAId': winnerA,
          'participantBId': winnerB,
          'matchdayId': null,
          'pointsA': null,
          'pointsB': null,
          'winnerId': null,
        },
      );
    }
    await batch.commit();
  }

  // ── Coppa: gironi ────────────────────────────────────────────────────────

  Future<void> processGroupsMatchday({
    required String leagueId,
    required String tournamentId,
    required String matchdayId,
  }) async {
    final points = await _scoring.pointsByUserForMatchday(
        leagueId: leagueId, matchdayId: matchdayId);
    final groupsSnapshot = await _groups(leagueId, tournamentId).get();
    final batch = _firestore.batch();
    for (final doc in groupsSnapshot.docs) {
      final group = _groupFromData(doc.id, doc.data());
      final updated = {...group.cumulativePoints};
      for (final userId in group.participantUserIds) {
        updated[userId] = (updated[userId] ?? 0) + (points[userId] ?? 0);
      }
      batch.update(doc.reference, {'cumulativePoints': updated});
    }
    await batch.commit();
    await _tournaments(leagueId)
        .doc(tournamentId)
        .update({'lastProcessedMatchdayId': matchdayId});
  }

  Future<void> closeGroupsPhaseAndSeedBracket({
    required String leagueId,
    required String tournamentId,
  }) async {
    final tournament = await getTournament(leagueId, tournamentId);
    if (tournament == null) return;
    final advancePerGroup = tournament.advancePerGroup ?? 2;

    final groupsSnapshot = await _groups(leagueId, tournamentId).get();
    final qualified = <String>[];
    for (final doc in groupsSnapshot.docs) {
      final group = _groupFromData(doc.id, doc.data());
      final ranked = [...group.participantUserIds]
        ..sort((a, b) => (group.cumulativePoints[b] ?? 0)
            .compareTo(group.cumulativePoints[a] ?? 0));
      qualified.addAll(ranked.take(advancePerGroup));
    }

    // Seeding del tabellone per punti cumulati nella fase a gironi
    // (già calcolati sopra, li rileggiamo in un'unica mappa per ordinare).
    final allCumulative = <String, int>{};
    for (final doc in groupsSnapshot.docs) {
      final group = _groupFromData(doc.id, doc.data());
      allCumulative.addAll(group.cumulativePoints);
    }
    qualified.sort((a, b) => (allCumulative[b] ?? 0).compareTo(allCumulative[a] ?? 0));

    final batch = _firestore.batch();
    for (final tie in TournamentScoring.generateFirstRound(qualified)) {
      batch.set(_bracket(leagueId, tournamentId).doc(tie.id), _tieToMap(tie));
    }
    batch.update(_tournaments(leagueId).doc(tournamentId), {
      'phase': CoppaPhase.knockout.name,
    });
    await batch.commit();
  }

  // ── Campionato ───────────────────────────────────────────────────────────

  Future<void> refreshCampionatoStandings({
    required String leagueId,
    required String tournamentId,
    required List<String> matchdayIds,
  }) async {
    final participantsSnap = await _participants(leagueId, tournamentId).get();
    final participantIds = participantsSnap.docs.map((d) => d.id).toSet();

    final totals = <String, int>{for (final id in participantIds) id: 0};
    for (final matchdayId in matchdayIds) {
      final points = await _scoring.pointsByUserForMatchday(
          leagueId: leagueId, matchdayId: matchdayId);
      for (final id in participantIds) {
        totals[id] = totals[id]! + (points[id] ?? 0);
      }
    }

    final batch = _firestore.batch();
    for (final doc in participantsSnap.docs) {
      batch.update(doc.reference, {'points': totals[doc.id] ?? 0});
    }
    await batch.commit();
  }

  // ── Mapping ──────────────────────────────────────────────────────────────

  LeagueTournament _tournamentFromDoc(String id, Map<String, dynamic> data) {
    final createdAt = data['createdAt'];
    return LeagueTournament(
      id: id,
      leagueId: data['leagueId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      type: TournamentType.values.firstWhere(
          (t) => t.name == data['type'], orElse: () => TournamentType.campionato),
      participantUserIds: (data['participantUserIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      status: TournamentStatus.values.firstWhere(
          (s) => s.name == data['status'], orElse: () => TournamentStatus.upcoming),
      createdAt: createdAt is Timestamp ? createdAt.toDate() : DateTime.now(),
      createdFromMatchdayId: data['createdFromMatchdayId'] as String?,
      coppaFormat: data['coppaFormat'] == null
          ? null
          : CoppaFormat.values.firstWhere((f) => f.name == data['coppaFormat']),
      phase: CoppaPhase.values.firstWhere(
          (p) => p.name == data['phase'], orElse: () => CoppaPhase.knockout),
      groupSize: (data['groupSize'] as num?)?.toInt(),
      advancePerGroup: (data['advancePerGroup'] as num?)?.toInt(),
      eliminationsPerMatchday: (data['eliminationsPerMatchday'] as num?)?.toInt() ?? 1,
      tiebreakOrder: (data['tiebreakOrder'] as List<dynamic>?)
              ?.map((e) => HighlanderTiebreak.values.firstWhere((t) => t.name == e))
              .toList() ??
          const [],
      lastProcessedMatchdayId: data['lastProcessedMatchdayId'] as String?,
    );
  }

  TournamentParticipant _participantFromData(Map<String, dynamic> data) {
    return TournamentParticipant(
      userId: data['userId'] as String? ?? '',
      username: data['username'] as String? ?? '',
      photoUrl: data['photoUrl'] as String?,
      points: (data['points'] as num?)?.toInt() ?? 0,
      active: data['active'] as bool? ?? true,
      eliminatedAtMatchdayId: data['eliminatedAtMatchdayId'] as String?,
    );
  }

  BracketTie _tieFromData(Map<String, dynamic> data) {
    return BracketTie(
      id: data['id'] as String? ?? '',
      round: (data['round'] as num?)?.toInt() ?? 1,
      slot: (data['slot'] as num?)?.toInt() ?? 0,
      participantAId: data['participantAId'] as String?,
      participantBId: data['participantBId'] as String?,
      matchdayId: data['matchdayId'] as String?,
      pointsA: (data['pointsA'] as num?)?.toInt(),
      pointsB: (data['pointsB'] as num?)?.toInt(),
      winnerId: data['winnerId'] as String?,
    );
  }

  Map<String, dynamic> _tieToMap(BracketTie tie) => {
        'id': tie.id,
        'round': tie.round,
        'slot': tie.slot,
        'participantAId': tie.participantAId,
        'participantBId': tie.participantBId,
        'matchdayId': tie.matchdayId,
        'pointsA': tie.pointsA,
        'pointsB': tie.pointsB,
        'winnerId': tie.winnerId,
      };

  TournamentGroup _groupFromData(String id, Map<String, dynamic> data) {
    return TournamentGroup(
      id: id,
      participantUserIds: (data['participantUserIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      cumulativePoints: (data['cumulativePoints'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, (v as num).toInt())) ??
          const {},
    );
  }
}
