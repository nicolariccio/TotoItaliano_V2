import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Istanza condivisa di FirebaseAuth. La logica di business (login,
/// registrazione, sign-out...) verrà incapsulata in `AuthRepository`
/// nella Phase 2: questo provider resta il solo punto d'accesso all'SDK.
final Provider<FirebaseAuth> firebaseAuthProvider = Provider<FirebaseAuth>(
  (ref) => FirebaseAuth.instance,
);

/// Stream dello stato di autenticazione, usato dal router per proteggere
/// le route e per decidere lo schermo iniziale.
final StreamProvider<User?> authStateChangesProvider = StreamProvider<User?>(
  (ref) => ref.watch(firebaseAuthProvider).authStateChanges(),
);
