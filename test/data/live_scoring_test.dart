import 'package:flutter_test/flutter_test.dart';
import 'package:totoitaliano/data/models/match.dart';
import 'package:totoitaliano/data/models/team.dart';
import 'package:totoitaliano/data/scoring/scoring_engine.dart';
import 'package:totoitaliano/features/predictions/domain/entities/prediction.dart';

void main() {
  const home = Team(
      id: 't1',
      name: 'Inter',
      shortName: 'INT',
      stadium: 'Meazza',
      city: 'Milano');
  const away = Team(
      id: 't2',
      name: 'Milan',
      shortName: 'MIL',
      stadium: 'Meazza',
      city: 'Milano');
  final now = DateTime(2026, 1, 1);

  Match match(MatchStatus status, int? h, int? a) => Match(
        id: 'm1',
        competitionId: 'c1',
        matchdayId: 'md1',
        homeTeam: home,
        awayTeam: away,
        kickoff: now,
        status: status,
        homeScore: h,
        awayScore: a,
        createdAt: now,
        updatedAt: now,
      );

  group('ScoringEngine.calculateLivePick', () {
    test('null se la partita non è iniziata o manca il risultato', () {
      expect(
          ScoringEngine.calculateLivePick(
              market: PredictionMarket.result1x2,
              result1x2Value: '1',
              match: match(MatchStatus.scheduled, null, null)),
          isNull);
      expect(
          ScoringEngine.calculateLivePick(
              market: PredictionMarket.result1x2,
              result1x2Value: '1',
              match: match(MatchStatus.live, null, null)),
          isNull);
    });

    test('1X2 segue il risultato attuale ed è provvisorio finché live', () {
      final live = ScoringEngine.calculateLivePick(
          market: PredictionMarket.result1x2,
          result1x2Value: '1',
          match: match(MatchStatus.live, 1, 0))!;
      expect(live.points, 5);
      expect(live.winningNow, isTrue);
      expect(live.settled, isFalse);

      final pareggio = ScoringEngine.calculateLivePick(
          market: PredictionMarket.result1x2,
          result1x2Value: '1',
          match: match(MatchStatus.live, 1, 1))!;
      expect(pareggio.points, 0);
    });

    test('a partita finita l\'esito è definitivo', () {
      final fin = ScoringEngine.calculateLivePick(
          market: PredictionMarket.result1x2,
          result1x2Value: 'X',
          match: match(MatchStatus.finished, 0, 0))!;
      expect(fin.points, 5);
      expect(fin.settled, isTrue);
    });

    test('Gol: si decide appena entrambe segnano, No Gol diventa perso', () {
      final gol = ScoringEngine.calculateLivePick(
          market: PredictionMarket.goalNoGoal,
          goalNoGoalValue: true,
          match: match(MatchStatus.live, 1, 1))!;
      expect(gol.points, 3);
      expect(gol.settled, isTrue);

      final noGol = ScoringEngine.calculateLivePick(
          market: PredictionMarket.goalNoGoal,
          goalNoGoalValue: false,
          match: match(MatchStatus.live, 1, 1))!;
      expect(noGol.points, 0);
      expect(noGol.settled, isTrue);

      final noGolAncora = ScoringEngine.calculateLivePick(
          market: PredictionMarket.goalNoGoal,
          goalNoGoalValue: false,
          match: match(MatchStatus.live, 1, 0))!;
      expect(noGolAncora.points, 3);
      expect(noGolAncora.settled, isFalse);
    });

    test('Over/Under 2.5: Over si decide al terzo gol', () {
      final under = ScoringEngine.calculateLivePick(
          market: PredictionMarket.overUnder25,
          overUnder25Value: false,
          match: match(MatchStatus.live, 1, 1))!;
      expect(under.points, 3);
      expect(under.settled, isFalse);

      final over = ScoringEngine.calculateLivePick(
          market: PredictionMarket.overUnder25,
          overUnder25Value: true,
          match: match(MatchStatus.live, 2, 1))!;
      expect(over.points, 3);
      expect(over.settled, isTrue);
    });

    test('Risultato esatto: perso appena il punteggio supera il pick', () {
      final inCorso = ScoringEngine.calculateLivePick(
          market: PredictionMarket.exactScore,
          exactHomeScore: 2,
          exactAwayScore: 1,
          match: match(MatchStatus.live, 1, 1))!;
      expect(inCorso.points, 0);
      expect(inCorso.settled, isFalse);

      final centrato = ScoringEngine.calculateLivePick(
          market: PredictionMarket.exactScore,
          exactHomeScore: 2,
          exactAwayScore: 1,
          match: match(MatchStatus.live, 2, 1))!;
      expect(centrato.points, 10);

      final perso = ScoringEngine.calculateLivePick(
          market: PredictionMarket.exactScore,
          exactHomeScore: 2,
          exactAwayScore: 1,
          match: match(MatchStatus.live, 3, 1))!;
      expect(perso.points, 0);
      expect(perso.settled, isTrue);
    });
  });
}
