import 'package:freezed_annotation/freezed_annotation.dart';

part 'prediction.freezed.dart';

/// Per ciascuna partita l'utente sceglie UN solo tipo di pronostico (non
/// più mercati indipendenti): è la scelta fatta in fase di compilazione
/// della schedina.
enum PredictionMarket { result1x2, goalNoGoal, overUnder25, exactScore }

/// Il pronostico di un utente per una partita, indipendente per ciascuna
/// lega: un documento per tripla (utente, lega, partita), id Firestore
/// `{userId}_{leagueId}_{matchId}`. Lo stesso utente può pronosticare in
/// modo diverso la stessa partita in leghe diverse — ogni lega ha la
/// propria schedina, come su totoamici.net. Fa parte della schedina della
/// giornata per quella lega, salvata in blocco per tutte le partite.
@freezed
abstract class Prediction with _$Prediction {
  const factory Prediction({
    required String id,
    required String userId,
    required String leagueId,
    required String matchId,
    required String competitionId,
    required String matchdayId,
    required PredictionMarket market,
    // Valorizzato solo se market == result1x2: '1' | 'X' | '2'.
    String? result1x2Value,
    // Valorizzato solo se market == goalNoGoal: true = GOAL, false = NO GOAL.
    bool? goalNoGoalValue,
    // Valorizzato solo se market == overUnder25: true = Over 2.5, false = Under 2.5.
    bool? overUnder25Value,
    // Valorizzati solo se market == exactScore.
    int? exactHomeScore,
    int? exactAwayScore,
    // Valorizzati solo dopo che un admin ha inserito il risultato ufficiale
    // e il ricalcolo (vedi AdminRepository.recomputeForMatch) è passato su
    // questo pronostico: null = partita non ancora segnata. Mai scrivibili
    // dal proprietario del pronostico (solo da un admin globale, vedi
    // firestore.rules).
    int? pointsAwarded,
    bool? correct,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Prediction;
}
