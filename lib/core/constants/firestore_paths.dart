/// Nomi delle collection Firestore centralizzati.
///
/// Nessun repository deve scrivere il nome di una collection come stringa
/// letterale al di fuori di questo file: evita refusi e rende i rename
/// tracciabili in un unico posto.
class FirestorePaths {
  const FirestorePaths._();

  static const String users = 'users';
  static const String competitions = 'competitions';
  static const String matchdaysSubcollection = 'matchdays';
  static const String teams = 'teams';
  static const String matches = 'matches';
  static const String predictions = 'predictions';
  static const String leagues = 'leagues';
  static const String leagueMembersSubcollection = 'members';
  static const String leagueMatchdayConfigSubcollection = 'matchdayConfig';
  static const String scores = 'scores';
  static const String referrals = 'referrals';
  static const String payments = 'payments';
  static const String prizes = 'prizes';
  static const String notifications = 'notifications';
  static const String notificationItemsSubcollection = 'items';
  static const String scoringConfigs = 'scoringConfigs';
}
