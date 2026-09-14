import 'dart:math';

/// Genera codici alfanumerici casuali (referral, invite code di lega...).
///
/// Non fornisce garanzie di unicità: il chiamante deve verificarla lato
/// Firestore (query o transazione) prima di persistere il codice.
class CodeGenerator {
  const CodeGenerator._();

  static const String _alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  static final Random _random = Random.secure();

  static String _randomChars(int length) {
    return List.generate(
        length, (_) => _alphabet[_random.nextInt(_alphabet.length)]).join();
  }

  /// Codice referral personale, es. "MARIOX7K3".
  static String referralCode({String? seed}) {
    final String prefix =
        (seed ?? '').replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
    final String base = prefix.isEmpty
        ? _randomChars(6)
        : prefix.substring(0, min(prefix.length, 6));
    return '$base${_randomChars(4)}';
  }

  /// Invite code di lega, es. "TOTO-8K4P2".
  static String leagueInviteCode() => 'TOTO-${_randomChars(5)}';
}
