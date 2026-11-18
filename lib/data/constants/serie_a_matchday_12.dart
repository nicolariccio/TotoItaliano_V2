/// Calendario della 12ª giornata di Serie A 2026/27 (21–23 novembre 2026),
/// usato dal pulsante admin "Carica giornata 12 (prova)" per simulare la
/// schedina con partite reali.
///
/// ATTENZIONE: coppie e giorni sono concordi tra le fonti, ma gli ORARI di
/// alcune gare erano discordanti al momento della raccolta (Juventus-Venezia,
/// Sassuolo-Genoa, Bologna-Udinese, Milan-Frosinone, Monza-Fiorentina):
/// verificali sul sito della Lega Serie A e correggili da "Gestione admin".
/// Orari in ora italiana (CET, UTC+1 a novembre).
class MatchdayFixture {
  const MatchdayFixture(this.home, this.away, this.kickoff);

  final String home;
  final String away;
  final DateTime kickoff;
}

DateTime _cet(int day, int hour, int minute) =>
    DateTime.utc(2026, 11, day, hour - 1, minute);

final List<MatchdayFixture> serieAMatchday12 = [
  MatchdayFixture('Como', 'Cagliari', _cet(21, 15, 0)),
  MatchdayFixture('Lazio', 'Lecce', _cet(21, 15, 0)),
  MatchdayFixture('Parma', 'Roma', _cet(21, 18, 0)),
  MatchdayFixture('Napoli', 'Torino', _cet(21, 20, 45)),
  MatchdayFixture('Juventus', 'Venezia', _cet(22, 12, 30)),
  MatchdayFixture('Bologna', 'Udinese', _cet(22, 15, 0)),
  MatchdayFixture('Sassuolo', 'Genoa', _cet(22, 15, 0)),
  MatchdayFixture('Milan', 'Frosinone', _cet(22, 18, 0)),
  MatchdayFixture('Atalanta', 'Inter', _cet(22, 20, 45)),
  MatchdayFixture('Monza', 'Fiorentina', _cet(23, 20, 45)),
];
