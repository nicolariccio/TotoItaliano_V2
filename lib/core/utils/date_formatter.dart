/// Formattazione date in italiano senza dipendere dal caricamento asincrono
/// dei dati locale di `intl` (`initializeDateFormatting`): per le poche
/// stringhe che ci servono, una mappa statica è più semplice e affidabile.
class DateFormatter {
  const DateFormatter._();

  static const List<String> _weekdays = ['Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab', 'Dom'];
  static const List<String> _months = [
    'Gen', 'Feb', 'Mar', 'Apr', 'Mag', 'Giu',
    'Lug', 'Ago', 'Set', 'Ott', 'Nov', 'Dic',
  ];

  /// Es. "Sab 20 Set, 18:00".
  static String matchKickoff(DateTime dateTime) {
    final weekday = _weekdays[dateTime.weekday - 1];
    final month = _months[dateTime.month - 1];
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$weekday ${dateTime.day} $month, $hour:$minute';
  }

  /// Es. "20/09/2026".
  static String shortDate(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    return '$day/$month/${dateTime.year}';
  }
}
