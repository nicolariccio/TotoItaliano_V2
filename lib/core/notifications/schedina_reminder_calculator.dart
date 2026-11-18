/// Logica pura (nessun plugin, nessun I/O) per decidere quali promemoria
/// locali "schedina in scadenza" servono adesso — separata dal servizio che
/// li pianifica davvero, così è testabile senza un dispositivo reale.
library;

/// Un promemoria da pianificare: un ID stabile (derivato da lega+giornata,
/// mai casuale) così ripianificarlo con lo stesso ID sovrascrive quello
/// precedente invece di accumularne uno nuovo.
class ReminderTarget {
  const ReminderTarget({
    required this.id,
    required this.leagueId,
    required this.leagueName,
    required this.matchdayId,
    required this.fireAt,
  });

  final int id;
  final String leagueId;
  final String leagueName;
  final String matchdayId;
  final DateTime fireAt;
}

/// Cosa fare adesso: [toSchedule] i promemoria da pianificare/ripianificare,
/// [toCancelIds] gli ID da cancellare (lega ormai completa, o troppo tardi
/// per avere senso un promemoria).
class SchedinaReminderPlan {
  const SchedinaReminderPlan({required this.toSchedule, required this.toCancelIds});

  final List<ReminderTarget> toSchedule;
  final List<int> toCancelIds;

  static const empty = SchedinaReminderPlan(toSchedule: [], toCancelIds: []);
}

class SchedinaReminderCalculator {
  const SchedinaReminderCalculator._();

  /// Quanto prima della chiusura avvisare — fisso, non configurabile
  /// dall'utente: un solo promemoria per lega/giornata è già sufficiente
  /// alla scala "amici" di questa app.
  static const Duration leadTime = Duration(hours: 1);

  /// Calcola il piano per la giornata [matchdayId], data la lista delle
  /// leghe dell'utente con quante partite contano per ciascuna e se la
  /// schedina è già completa. Nessuna lettura qui: [leagues] è già stato
  /// filtrato/derivato dal chiamante (partite escluse dalla config di lega
  /// già tolte a monte).
  static SchedinaReminderPlan compute({
    required List<
            ({String leagueId, String leagueName, bool schedinaComplete})>
        leagues,
    required String matchdayId,
    required DateTime deadline,
    required DateTime now,
  }) {
    final fireAt = deadline.subtract(leadTime);
    // Se il momento del promemoria è già passato (giornata quasi chiusa, o
    // l'app non si apre da un po'), non pianifichiamo nulla di nuovo — un
    // promemoria "adesso" per qualcosa che chiude tra 5 minuti non aiuta e
    // un plugin di notifiche locali non lo mostrerebbe comunque a un orario
    // già trascorso.
    final canSchedule = fireAt.isAfter(now);

    final toSchedule = <ReminderTarget>[];
    final toCancelIds = <int>[];
    for (final league in leagues) {
      final id = stableId(league.leagueId, matchdayId);
      if (canSchedule && !league.schedinaComplete) {
        toSchedule.add(ReminderTarget(
          id: id,
          leagueId: league.leagueId,
          leagueName: league.leagueName,
          matchdayId: matchdayId,
          fireAt: fireAt,
        ));
      } else {
        toCancelIds.add(id);
      }
    }
    return SchedinaReminderPlan(toSchedule: toSchedule, toCancelIds: toCancelIds);
  }

  /// ID a 31 bit (il plugin di notifiche locali richiede un int Android
  /// positivo) derivato in modo deterministico da lega+giornata: la stessa
  /// coppia dà sempre lo stesso ID, così pianificarlo di nuovo sostituisce
  /// il precedente invece di crearne un duplicato.
  static int stableId(String leagueId, String matchdayId) =>
      Object.hash(leagueId, matchdayId) & 0x7fffffff;
}
