import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../../../data/models/match.dart';
import '../../../../data/models/scoring_config.dart';
import '../../../../data/scoring/scoring_engine.dart';
import '../../../predictions/domain/entities/prediction.dart';

/// Sostituisce la Cloud Function di scoring mai attivata (piano Spark):
/// dopo che l'admin inserisce il risultato ufficiale di una partita,
/// [recomputeForMatch] assegna i punti a tutti i pronostici di quella
/// partita non ancora segnati, in un'unica scrittura batch. Idempotente per
/// costruzione: filtra solo i pronostici con `pointsAwarded == null`, quindi
/// rilanciarlo sulla stessa partita non assegna punti una seconda volta.
class ScoringRecomputeDatasource {
  ScoringRecomputeDatasource(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _predictions =>
      _firestore.collection(FirestorePaths.predictions);

  CollectionReference<Map<String, dynamic>> get _leagues =>
      _firestore.collection(FirestorePaths.leagues);

  /// Ritorna il numero di pronostici effettivamente segnati.
  Future<int> recomputeForMatch(Match match) async {
    final snapshot =
        await _predictions.where('matchId', isEqualTo: match.id).get();
    final pending = snapshot.docs
        .where((doc) => doc.data()['pointsAwarded'] == null)
        .toList();
    if (pending.isEmpty) return 0;

    final configByLeague = <String, ScoringConfig>{};
    Future<ScoringConfig> configFor(String leagueId) async {
      final cached = configByLeague[leagueId];
      if (cached != null) return cached;
      final leagueDoc = await _leagues.doc(leagueId).get();
      final config = ScoringConfig.fromMap(
              leagueDoc.data()?['scoringConfig'] as Map<String, dynamic>?) ??
          const ScoringConfig();
      configByLeague[leagueId] = config;
      return config;
    }

    final batch = _firestore.batch();
    var scored = 0;

    for (final doc in pending) {
      final data = doc.data();
      final leagueId = data['leagueId'] as String;
      final userId = data['userId'] as String;
      final prediction = _predictionFromData(doc.id, data);
      final config = await configFor(leagueId);
      final result = ScoringEngine.calculate(
          prediction: prediction, match: match, config: config);
      if (result == null) continue;

      batch.update(doc.reference, {
        'pointsAwarded': result.points,
        'correct': result.correct,
      });

      // last5/exactCount sono denormalizzati sul membro (vedi
      // LeagueMember): un membro non può leggere i pronostici di un altro
      // (Security Rules), quindi la striscia "ultimi 5" e il conteggio
      // "esatti" in classifica devono essere già pronti lì. Richiede una
      // lettura per pronostico (non solo FieldValue.increment come per
      // totalPoints, perché "ultimi 5" è un array troncato, non una somma)
      // — accettabile per un'azione admin su scala di lega tra amici.
      final memberRef = _leagues
          .doc(leagueId)
          .collection(FirestorePaths.leagueMembersSubcollection)
          .doc(userId);
      final memberDoc = await memberRef.get();
      final currentLast5 = (memberDoc.data()?['last5'] as List<dynamic>?)
              ?.map((e) => e as bool)
              .toList() ??
          const <bool>[];
      final newLast5 = [result.correct, ...currentLast5].take(5).toList();
      final exactCountDelta =
          prediction.market == PredictionMarket.exactScore && result.correct
              ? 1
              : 0;

      batch.update(memberRef, {
        if (result.points > 0) 'totalPoints': FieldValue.increment(result.points),
        'last5': newLast5,
        if (exactCountDelta > 0) 'exactCount': FieldValue.increment(exactCountDelta),
      });
      scored++;
    }

    if (scored > 0) await batch.commit();
    return scored;
  }

  Prediction _predictionFromData(String id, Map<String, dynamic> data) {
    return Prediction(
      id: id,
      userId: data['userId'] as String? ?? '',
      leagueId: data['leagueId'] as String? ?? '',
      matchId: data['matchId'] as String? ?? '',
      competitionId: data['competitionId'] as String? ?? '',
      matchdayId: data['matchdayId'] as String? ?? '',
      market: PredictionMarket.values.firstWhere(
        (m) => m.name == data['market'] as String?,
        orElse: () => PredictionMarket.result1x2,
      ),
      result1x2Value: data['result1x2Value'] as String?,
      goalNoGoalValue: data['goalNoGoalValue'] as bool?,
      overUnder25Value: data['overUnder25Value'] as bool?,
      exactHomeScore: (data['exactHomeScore'] as num?)?.toInt(),
      exactAwayScore: (data['exactAwayScore'] as num?)?.toInt(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
