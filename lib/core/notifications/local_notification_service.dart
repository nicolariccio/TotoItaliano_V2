import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'schedina_reminder_calculator.dart';

/// Wrapper sottile su `flutter_local_notifications`: pianifica/cancella i
/// promemoria "schedina in scadenza" calcolati da
/// [SchedinaReminderCalculator]. Niente Cloud Function, niente FCM — tutto
/// pianificato sul dispositivo, a costo zero. Il plugin stesso è un no-op
/// su web (vedi la sua implementazione di `initialize`/`zonedSchedule`),
/// quindi qui non servono controlli espliciti su `kIsWeb`.
class LocalNotificationService {
  LocalNotificationService._();

  static final LocalNotificationService instance = LocalNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const String _channelId = 'schedina_reminders';
  static const String _channelName = 'Promemoria schedina';

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {
      // Fuso orario del dispositivo non determinabile: restiamo sul default
      // (UTC) piuttosto che far fallire l'inizializzazione — i promemoria
      // sparano comunque, nel peggiore dei casi con qualche ora di scarto.
    }
    await _plugin.initialize(const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    ));
    _initialized = true;
  }

  /// Richiede il permesso di mostrare notifiche (Android 13+ e iOS lo
  /// richiedono esplicitamente). Da chiamare quando l'utente attiva i
  /// promemoria dalle impostazioni, non all'avvio dell'app.
  Future<void> requestPermission() async {
    await _ensureInitialized();
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  /// Applica [plan]: cancella ciò che non serve più, pianifica/ripianifica
  /// il resto. Idempotente — chiamarlo di nuovo con lo stesso piano non
  /// duplica nulla, perché gli ID sono stabili per lega+giornata.
  Future<void> syncSchedinaReminders(SchedinaReminderPlan plan) async {
    await _ensureInitialized();
    for (final id in plan.toCancelIds) {
      await _plugin.cancel(id);
    }
    for (final target in plan.toSchedule) {
      await _plugin.zonedSchedule(
        target.id,
        'Schedina in scadenza',
        'La schedina di "${target.leagueName}" chiude tra un\'ora: completala prima che sia troppo tardi.',
        tz.TZDateTime.from(target.fireAt, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription:
                'Avviso quando manca poco alla chiusura di una schedina non ancora completa.',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  /// Cancella tutti i promemoria pianificati — usato quando l'utente
  /// disattiva i promemoria dalle impostazioni.
  Future<void> cancelAll() async {
    await _ensureInitialized();
    await _plugin.cancelAll();
  }
}
