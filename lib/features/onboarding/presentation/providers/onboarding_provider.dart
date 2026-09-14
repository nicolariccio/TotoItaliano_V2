import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/shared_preferences_provider.dart';

/// Tiene traccia del completamento dell'onboarding, persistito localmente.
class OnboardingController extends StateNotifier<bool> {
  OnboardingController(this._ref)
      : super(_ref
                .read(sharedPreferencesProvider)
                .getBool(AppConstants.prefsOnboardingComplete) ??
            false);

  final Ref _ref;

  Future<void> complete() async {
    await _ref
        .read(sharedPreferencesProvider)
        .setBool(AppConstants.prefsOnboardingComplete, true);
    state = true;
  }
}

final StateNotifierProvider<OnboardingController, bool>
    onboardingCompleteProvider =
    StateNotifierProvider<OnboardingController, bool>(
        (ref) => OnboardingController(ref));
