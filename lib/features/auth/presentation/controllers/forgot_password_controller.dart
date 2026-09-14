import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception_mapper.dart';
import '../providers/auth_repository_provider.dart';

class ForgotPasswordController extends StateNotifier<AsyncValue<void>> {
  ForgotPasswordController(this._ref) : super(const AsyncData(null));

  final Ref _ref;

  Future<void> submit(String email) async {
    state = const AsyncLoading();
    try {
      await _ref.read(authRepositoryProvider).sendPasswordResetEmail(email);
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(AppExceptionMapper.map(error), stackTrace);
    }
  }
}

final StateNotifierProvider<ForgotPasswordController, AsyncValue<void>>
    forgotPasswordControllerProvider =
    StateNotifierProvider<ForgotPasswordController, AsyncValue<void>>(
        (ref) => ForgotPasswordController(ref));
