import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/features/onboarding/data/shared_preferences_app_onboarding_store.dart';
import 'package:galaxy_novels_app/features/onboarding/domain/app_onboarding_state.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test('missing value means the tour has not been completed', () async {
    final store = SharedPreferencesAppOnboardingStore();

    expect(await store.read(), isNull);
  });

  test('writes and restores a completed tour', () async {
    final store = SharedPreferencesAppOnboardingStore();
    final state = AppOnboardingState.completed(
      completedAt: DateTime.utc(2026, 8, 12),
      method: AppOnboardingCompletionMethod.skipped,
    );

    await store.write(state);

    expect(await store.read(), state);
  });

  test('corrupt JSON is treated as missing state', () async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.withData({
          SharedPreferencesAppOnboardingStore.key: '{broken',
        });

    expect(await SharedPreferencesAppOnboardingStore().read(), isNull);
  });
}
