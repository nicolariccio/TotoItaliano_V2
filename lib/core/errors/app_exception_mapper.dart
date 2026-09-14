import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';

import 'failure.dart';

/// Converte eccezioni tecniche (Firebase, rete, ecc.) in un [Failure]
/// presentabile in UI. Punto unico di traduzione errore -> messaggio utente.
class AppExceptionMapper {
  const AppExceptionMapper._();

  static Failure map(Object error) {
    if (error is Failure) return error;

    if (error is FirebaseAuthException) return _mapAuthException(error);
    if (error is FirebaseException) return _mapFirestoreException(error);
    if (error is SocketException) return const NetworkFailure();
    if (error is TimeoutException) return const TimeoutFailure();

    return const UnknownFailure();
  }

  static Failure _mapAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return const AuthFailure('Email o password non corretti.');
      case 'email-already-in-use':
        return const AuthFailure('Questa email è già registrata.');
      case 'weak-password':
        return const AuthFailure('La password scelta è troppo debole.');
      case 'invalid-email':
        return const AuthFailure('Indirizzo email non valido.');
      case 'too-many-requests':
        return const AuthFailure(
            'Troppi tentativi. Riprova tra qualche minuto.');
      case 'network-request-failed':
        return const NetworkFailure();
      default:
        return const AuthFailure(
            'Non è stato possibile completare l\'operazione.');
    }
  }

  static Failure _mapFirestoreException(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return const AuthFailure('Non hai i permessi per questa operazione.');
      case 'unavailable':
        return const NetworkFailure();
      case 'deadline-exceeded':
        return const TimeoutFailure();
      default:
        return const ServerFailure();
    }
  }
}
