import '../domain/app_onboarding_state.dart';

abstract interface class AppOnboardingStore {
  Future<AppOnboardingState?> read();

  Future<void> write(AppOnboardingState state);
}

class MemoryAppOnboardingStore implements AppOnboardingStore {
  MemoryAppOnboardingStore([this.storedState]);

  AppOnboardingState? storedState;

  @override
  Future<AppOnboardingState?> read() async => storedState;

  @override
  Future<void> write(AppOnboardingState state) async => storedState = state;
}
