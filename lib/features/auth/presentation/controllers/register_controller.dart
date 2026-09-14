import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception_mapper.dart';
import '../providers/auth_repository_provider.dart';

class RegisterController extends StateNotifier<AsyncValue<void>> {
  RegisterController(this._ref) : super(const AsyncData(null));

  final Ref _ref;

  Future<void> submit({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String username,
    String? referralCode,
  }) async {
    state = const AsyncLoading();
    try {
      await _ref.read(authRepositoryProvider).registerWithEmail(
            email: email,
            password: password,
            firstName: firstName,
            lastName: lastName,
            username: username,
            referralCode: referralCode,
          );
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(AppExceptionMapper.map(error), stackTrace);
    }
  }
}

final StateNotifierProvider<RegisterController, AsyncValue<void>>
    registerControllerProvider =
    StateNotifierProvider<RegisterController, AsyncValue<void>>(
        (ref) => RegisterController(ref));
