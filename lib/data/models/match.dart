import 'package:freezed_annotation/freezed_annotation.dart';

import 'team.dart';

part 'match.freezed.dart';

enum MatchStatus { scheduled, live, finished, postponed }

/// Esito ufficiale 1X2 a partita conclusa. Non è un pronostico: è il
/// risultato reale usato dal motore di scoring (Phase 5) per confrontarlo
/// con i pronostici degli utenti.
enum MatchWinner { home, draw, away }

@freezed
abstract class Match with _$Match {
  const factory Match({
    required String id,
    required String competitionId,
    required String matchdayId,
    required Team homeTeam,
    required Team awayTeam,
    required DateTime kickoff,
    @Default(MatchStatus.scheduled) MatchStatus status,
    int? homeScore,
    int? awayScore,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default(false) bool predictionLocked,
    MatchWinner? winner,
    bool? goalNoGoal,
    // Esito over/under a partita conclusa per ciascuna soglia standard.
    // Es. {'1.5': true, '2.5': false, '3.5': false}.
    Map<String, bool>? overUnder,
  }) = _Match;

  const Match._();

  /// Vero se l'utente può ancora salvare/modificare un pronostico: il
  /// client lo usa solo per l'interfaccia (abilitare/disabilitare la CTA),
  /// MAI come unica fonte di verità — il blocco reale è imposto lato
  /// backend confrontando il server timestamp con il kickoff.
  bool get isPredictionOpen => !predictionLocked && DateTime.now().isBefore(kickoff);
}
