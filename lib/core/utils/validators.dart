/// Validatori riusabili per i form (registrazione, login, creazione lega...).
/// Ogni validator ritorna `null` se il valore è valido, altrimenti il
/// messaggio d'errore da mostrare sotto il campo.
class Validators {
  const Validators._();

  static final RegExp _emailRegex =
      RegExp(r'^[\w\.\-\+]+@[\w\-]+\.[a-zA-Z]{2,}$');

  static final RegExp _usernameRegex = RegExp(r'^[a-zA-Z0-9_]{3,20}$');

  static String? required(String? value, {String field = 'Campo'}) {
    if (value == null || value.trim().isEmpty) return '$field obbligatorio.';
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email obbligatoria.';
    if (!_emailRegex.hasMatch(value.trim())) return 'Email non valida.';
    return null;
  }

  static String? username(String? value) {
    if (value == null || value.trim().isEmpty) return 'Username obbligatorio.';
    if (!_usernameRegex.hasMatch(value.trim())) {
      return '3-20 caratteri: lettere, numeri, underscore.';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password obbligatoria.';
    if (value.length < 8) return 'Almeno 8 caratteri.';
    if (!RegExp(r'[A-Z]').hasMatch(value)) return 'Almeno una lettera maiuscola.';
    if (!RegExp(r'[0-9]').hasMatch(value)) return 'Almeno un numero.';
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) return 'Conferma la password.';
    if (value != original) return 'Le password non coincidono.';
    return null;
  }

  static String? inviteCode(String? value) {
    if (value == null || value.trim().isEmpty) return 'Codice obbligatorio.';
    if (value.trim().length < 6) return 'Codice non valido.';
    return null;
  }
}
