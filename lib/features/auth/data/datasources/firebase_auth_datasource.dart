import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Wrapper sottile su FirebaseAuth + GoogleSignIn. Nessuna logica di
/// dominio qui (niente Firestore, niente decisioni su cosa fare con un
/// nuovo utente): quella vive in [AuthRepositoryImpl].
class FirebaseAuthDatasource {
  FirebaseAuthDatasource(this._auth);

  final FirebaseAuth _auth;

  // Costruito solo al primo utilizzo reale del Sign-In Google: su web
  // istanziare GoogleSignIn() prima che il provider OAuth sia configurato
  // in Firebase Console può fallire, e non deve impedire login/registrazione
  // via email — che non toccano affatto Google Sign-In.
  GoogleSignIn? _googleSignIn;
  GoogleSignIn get _googleSignInInstance => _googleSignIn ??= GoogleSignIn();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> registerWithEmail(String email, String password) {
    return _auth.createUserWithEmailAndPassword(
        email: email, password: password);
  }

  Future<UserCredential> signInWithEmail(String email, String password) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> signInWithGoogle() async {
    final GoogleSignInAccount? account = await _googleSignInInstance.signIn();
    if (account == null) {
      throw FirebaseAuthException(
          code: 'sign-in-canceled', message: 'Accesso Google annullato.');
    }
    final GoogleSignInAuthentication googleAuth = await account.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return _auth.signInWithCredential(credential);
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> signOut() async {
    await Future.wait(
        [_auth.signOut(), if (_googleSignIn != null) _googleSignIn!.signOut()]);
  }

  Future<void> deleteCurrentUser() async {
    await _auth.currentUser?.delete();
  }
}
