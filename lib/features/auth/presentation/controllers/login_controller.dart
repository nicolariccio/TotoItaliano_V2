import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception_mapper.dart';
import '../providers/auth_repository_provider.dart';

/// Stato della submit del form di login. `AsyncData(null)` = idle/successo,
/// `AsyncLoading` = in corso, `AsyncError` = fallita (con [Failure] come
/// errore, pronto per essere mostrato in UI).
class LoginController extends StateNotifier<AsyncValue<void>> {
  LoginController(this._ref) : super(const AsyncData(null));

  final Ref _ref;

  Future<void> submit({required String email, required String password}) async {
    state = const AsyncLoading();
    try {
      await _ref
          .read(authRepositoryProvider)
          .loginWithEmail(email: email, password: password);
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(AppExceptionMapper.map(error), stackTrace);
    }
  }

  Future<void> submitWithGoogle() async {
    state = const AsyncLoading();
    try {
      await _ref.read(authRepositoryProvider).signInWithGoogle();
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(AppExceptionMapper.map(error), stackTrace);
    }
  }
}

final StateNotifierProvider<LoginController, AsyncValue<void>>
    loginControllerProvider =
    StateNotifierProvider<LoginController, AsyncValue<void>>(
        (ref) => LoginController(ref));
