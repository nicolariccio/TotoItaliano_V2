import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/errors/app_exception_mapper.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/utils/code_generator.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/firebase_auth_datasource.dart';
import '../datasources/user_firestore_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._authDatasource, this._userDatasource);

  final FirebaseAuthDatasource _authDatasource;
  final UserFirestoreDatasource _userDatasource;

  @override
  Future<AppUser> registerWithEmail({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String username,
    String? referralCode,
  }) async {
    try {
      // Le Security Rules richiedono un utente autenticato anche solo per
      // leggere `users` (niente elenco profili a chi non ha fatto login):
      // per questo l'account Auth va creato PRIMA del controllo di
      // disponibilità dell'username, non dopo. Se l'username risulta già
      // in uso o la scrittura del profilo fallisce, l'account Auth appena
      // creato viene eliminato per non lasciare un account "orfano".
      final UserCredential credential = await _authDatasource.registerWithEmail(email, password);
      final User firebaseUser = credential.user!;

      try {
        if (await _userDatasource.isUsernameTaken(username)) {
          throw const ValidationFailure('Questo username è già in uso.');
        }

        final AppUser user = AppUser(
          id: firebaseUser.uid,
          email: email,
          username: username,
          firstName: firstName,
          lastName: lastName,
          referralCode: CodeGenerator.referralCode(seed: username),
          referredBy: (referralCode == null || referralCode.trim().isEmpty) ? null : referralCode.trim(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _userDatasource.createUser(user);
        return user;
      } catch (error) {
        // Rollback best-effort: se anche l'eliminazione dell'account fallisce,
        // non deve mascherare l'errore originale (es. "username già in uso").
        try {
          await _authDatasource.deleteCurrentUser();
        } catch (_) {
          // ignora: l'errore rilevante per l'utente è quello originale
        }
        rethrow;
      }
    } catch (error) {
      throw AppExceptionMapper.map(error);
    }
  }

  @override
  Future<void> loginWithEmail({required String email, required String password}) async {
    try {
      await _authDatasource.signInWithEmail(email, password);
    } catch (error) {
      throw AppExceptionMapper.map(error);
    }
  }

  @override
  Future<bool> signInWithGoogle() async {
    try {
      final UserCredential credential = await _authDatasource.signInWithGoogle();
      final User firebaseUser = credential.user!;
      final bool isNewUser = credential.additionalUserInfo?.isNewUser ?? false;

      if (isNewUser) {
        final String baseUsername = _usernameFromEmail(firebaseUser.email ?? firebaseUser.uid);
        final String username = await _uniqueUsername(baseUsername);
        final List<String> nameParts = (firebaseUser.displayName ?? '').trim().split(' ');

        final user = AppUser(
          id: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          username: username,
          firstName: nameParts.isNotEmpty ? nameParts.first : username,
          lastName: nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '',
          photoUrl: firebaseUser.photoURL,
          referralCode: CodeGenerator.referralCode(seed: username),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _userDatasource.createUser(user);
      }

      return isNewUser;
    } catch (error) {
      throw AppExceptionMapper.map(error);
    }
  }

  Future<String> _uniqueUsername(String base) async {
    String candidate = base;
    int attempt = 0;
    while (await _userDatasource.isUsernameTaken(candidate)) {
      attempt++;
      candidate = '$base$attempt';
    }
    return candidate;
  }

  String _usernameFromEmail(String email) {
    final String local = email.split('@').first;
    final String cleaned = local.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '');
    return cleaned.isEmpty ? 'utente${DateTime.now().millisecondsSinceEpoch}' : cleaned;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _authDatasource.sendPasswordResetEmail(email);
    } catch (error) {
      throw AppExceptionMapper.map(error);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _authDatasource.signOut();
    } catch (error) {
      throw AppExceptionMapper.map(error);
    }
  }
}
