import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firestore_paths.dart';
import '../models/league_tournament.dart';
import '../models/tournament_bracket_tie.dart';

/// Motore condiviso da Highlander (elimina i peggiori di giornata) e Coppa
/// (decide il vincitore di un incontro): entrambi si riducono alla stessa
/// domanda — "quanti punti ha fatto ciascun utente in questa lega, in
/// questa giornata" — quindi vive in un solo posto invece che duplicato.
class TournamentScoring {
  TournamentScoring(this._firestore);

  final FirebaseFirestore _firestore;

  /// Ordine di spareggio di default per la Coppa (non configurabile come
  /// l'Highlander, che l'admin può riordinare — vedi [LeagueTournament]).
  static const List<HighlanderTiebreak> defaultTiebreakOrder = [
    HighlanderTiebreak.earliestSubmission,
    HighlanderTiebreak.previousMatchdayPoints,
    HighlanderTiebreak.seasonExactCount,
  ];

  CollectionReference<Map<String, dynamic>> get _predictions =>
      _firestore.collection(FirestorePaths.predictions);

  /// Punti totalizzati da ciascun utente in [leagueId] per la giornata
  /// [matchdayId] — somma di `Prediction.pointsAwarded` già segnati da
  /// ScoringEngine/ScoringRecomputeDatasource. Chi non ha un pronostico
  /// segnato per quella giornata semplicemente non compare nella mappa
  /// (il chiamante tratta l'assenza come 0 punti).
  Future<Map<String, int>> pointsByUserForMatchday({
    required String leagueId,
    required String matchdayId,
  }) async {
    final snapshot = await _predictions
        .where('leagueId', isEqualTo: leagueId)
        .where('matchdayId', isEqualTo: matchdayId)
        .get();
    final totals = <String, int>{};
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final userId = data['userId'] as String?;
      final points = (data['pointsAwarded'] as num?)?.toInt();
      if (userId == null || points == null) continue;
      totals.update(userId, (v) => v + points, ifAbsent: () => points);
    }
    return totals;
  }

  /// Orario del pronostico salvato più vecchio di ciascun utente per
  /// [leagueId]+[matchdayId] — usato dal criterio di spareggio "primo ad
  /// inviare la schedina quella giornata".
  Future<Map<String, DateTime>> submissionTimesByUser({
    required String leagueId,
    required String matchdayId,
  }) async {
    final snapshot = await _predictions
        .where('leagueId', isEqualTo: leagueId)
        .where('matchdayId', isEqualTo: matchdayId)
        .get();
    final earliest = <String, DateTime>{};
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final userId = data['userId'] as String?;
      final createdAt = data['createdAt'];
      if (userId == null || createdAt is! Timestamp) continue;
      final at = createdAt.toDate();
      final current = earliest[userId];
      if (current == null || at.isBefore(current)) earliest[userId] = at;
    }
    return earliest;
  }

  /// Ordina [tiedUserIds] dal "migliore" (si salva in Highlander / vince in
  /// Coppa) al "peggiore", applicando [tiebreakOrder] come chiave di
  /// ordinamento composita. Un pareggio residuo dopo tutti i criteri è
  /// risolto a sorteggio ESPLICITO — mai un ordine arbitrario travestito da
  /// criterio: il chiamante deve segnalare all'utente quando è successo.
  static List<String> rankByTiebreak(
    List<String> tiedUserIds,
    List<HighlanderTiebreak> tiebreakOrder,
    TiebreakContext ctx, {
    Random? random,
  }) {
    final rng = random ?? Random();
    final keyed = [
      for (final id in tiedUserIds) (id, _keyTuple(id, tiebreakOrder, ctx)),
    ];
    keyed.sort((a, b) => _compareKeys(a.$2, b.$2));

    // Un pareggio residuo (stessa chiave composita su più utenti) si
    // risolve mescolando solo quel sottogruppo, non l'intera lista.
    var i = 0;
    while (i < keyed.length) {
      var j = i + 1;
      while (j < keyed.length && _compareKeys(keyed[i].$2, keyed[j].$2) == 0) {
        j++;
      }
      if (j - i > 1) {
        final slice = keyed.sublist(i, j)..shuffle(rng);
        keyed.replaceRange(i, j, slice);
      }
      i = j;
    }
    return [for (final entry in keyed) entry.$1];
  }

  static List<num> _keyTuple(
    String userId,
    List<HighlanderTiebreak> order,
    TiebreakContext ctx,
  ) {
    return [
      for (final criterion in order)
        switch (criterion) {
          // Prima è "meglio": valore più basso vince l'ordinamento crescente.
          HighlanderTiebreak.earliestSubmission =>
            (ctx.submittedAt[userId] ?? DateTime(9999))
                .millisecondsSinceEpoch
                .toDouble(),
          // Punti/esatti più alti sono "meglio": invertiamo il segno così
          // l'ordinamento crescente li mette comunque per primi.
          HighlanderTiebreak.previousMatchdayPoints =>
            -(ctx.previousMatchdayPoints[userId] ?? 0),
          HighlanderTiebreak.seasonExactCount =>
            -(ctx.seasonExactCount[userId] ?? 0),
        },
    ];
  }

  static int _compareKeys(List<num> a, List<num> b) {
    for (var i = 0; i < a.length; i++) {
      final cmp = a[i].compareTo(b[i]);
      if (cmp != 0) return cmp;
    }
    return 0;
  }

  /// Genera il primo turno di un tabellone a eliminazione diretta da una
  /// lista di partecipanti già ordinata dal seed migliore al peggiore
  /// (tipicamente per punti classifica generale, decrescente). Bye
  /// assegnati ai seed migliori se i partecipanti non sono una potenza di
  /// 2 — stesso principio di qualunque tabellone sportivo standard.
  static List<BracketTie> generateFirstRound(List<String> seededUserIds) {
    final n = seededUserIds.length;
    if (n < 2) return const [];

    var bracketSize = 1;
    while (bracketSize < n) {
      bracketSize *= 2;
    }
    final slotOrder = _seedSlotOrder(bracketSize);
    // slotOrder[i] = indice di seed (0-based) che occupa lo slot i; un
    // indice >= n è uno slot vuoto (bye).
    String? seedAt(int slotIndex) {
      final seedIndex = slotOrder[slotIndex];
      return seedIndex < n ? seededUserIds[seedIndex] : null;
    }

    final ties = <BracketTie>[];
    for (var slot = 0; slot < bracketSize; slot += 2) {
      final a = seedAt(slot);
      final b = seedAt(slot + 1);
      // Un bye vero ha sempre un lato reale (i seed migliori riempiono gli
      // slot pieni per costruzione di _seedSlotOrder): normalizziamo così
      // participantAId non è mai null quando c'è un solo partecipante.
      final participantA = a ?? b;
      final participantB = a != null && b != null ? b : null;
      ties.add(BracketTie(
        id: 'r1-s${slot ~/ 2}',
        round: 1,
        slot: slot ~/ 2,
        participantAId: participantA,
        participantBId: participantB,
        winnerId: participantB == null ? participantA : null,
      ));
    }
    return ties;
  }

  /// Ordine "a specchio" classico dei tabelloni sportivi (1v8, 4v5, 2v7,
  /// 3v6 per un tabellone da 8): i seed migliori si incontrano il più
  /// tardi possibile.
  static List<int> _seedSlotOrder(int size) {
    if (size == 1) return [0];
    final prev = _seedSlotOrder(size ~/ 2);
    return [
      for (final p in prev) ...[p, size - 1 - p],
    ];
  }
}

/// Contesto pre-caricato per risolvere uno spareggio: ogni mappa è
/// opzionale/parziale, un utente assente equivale al valore peggiore
/// possibile per quel criterio.
class TiebreakContext {
  const TiebreakContext({
    this.submittedAt = const {},
    this.previousMatchdayPoints = const {},
    this.seasonExactCount = const {},
  });

  final Map<String, DateTime> submittedAt;
  final Map<String, int> previousMatchdayPoints;
  final Map<String, int> seasonExactCount;
}
