import 'package:flutter/foundation.dart';

/// Riga generica di una classifica (utenti o membri di lega): quanto
/// serve per disegnare podio + lista, indipendentemente dalla fonte dati.
@immutable
class RankedEntry {
  const RankedEntry(
      {required this.id,
      required this.username,
      this.photoUrl,
      required this.points,
      this.last5 = const <bool>[],
      this.exactCount = 0});

  final String id;
  final String username;
  final String? photoUrl;
  final int points;
  // Esito degli ultimi pronostici segnati, più recente per primo (vedi
  // LeagueMember.last5) — vuoto per la classifica generale, dove non è
  // ancora tracciato per lega.
  final List<bool> last5;
  final int exactCount;
}
