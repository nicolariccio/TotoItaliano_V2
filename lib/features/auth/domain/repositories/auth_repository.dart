import '../entities/app_user.dart';

/// Contratto per le operazioni di autenticazione e per l'accesso al profilo
/// utente. L'implementazione (in `data/`) è l'unico punto che parla con
/// FirebaseAuth/Firestore/GoogleSignIn: la UI dipende solo da questa
/// interfaccia.
abstract class AuthRepository {
  Future<AppUser> registerWithEmail({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String username,
    String? referralCode,
  });

  Future<void> loginWithEmail(
      {required String email, required String password});

  /// Ritorna `true` se è stato creato un nuovo profilo (primo accesso).
  Future<bool> signInWithGoogle();

  Future<void> sendPasswordResetEmail(String email);

  Future<void> signOut();
}
