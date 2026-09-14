import 'package:flutter/foundation.dart';

/// Riga generica di una classifica (utenti o membri di lega): quanto
/// serve per disegnare podio + lista, indipendentemente dalla fonte dati.
@immutable
class RankedEntry {
  const RankedEntry(
      {required this.id,
      required this.username,
      this.photoUrl,
      required this.points});

  final String id;
  final String username;
  final String? photoUrl;
  final int points;
}
