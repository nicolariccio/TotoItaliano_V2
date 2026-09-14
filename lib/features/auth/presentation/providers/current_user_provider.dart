import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/app_user.dart';
import 'auth_providers.dart';
import 'auth_repository_provider.dart';

/// Profilo Firestore dell'utente autenticato, reattivo sia ai cambi di
/// stato auth (login/logout) sia agli aggiornamenti del documento
/// `users/{uid}` (es. punteggio aggiornato da una Cloud Function).
final StreamProvider<AppUser?> currentUserProvider = StreamProvider<AppUser?>((ref) {
  final firebaseUser = ref.watch(authStateChangesProvider).valueOrNull;
  if (firebaseUser == null) return Stream.value(null);

  return ref.watch(userFirestoreDatasourceProvider).watchUser(firebaseUser.uid);
});
