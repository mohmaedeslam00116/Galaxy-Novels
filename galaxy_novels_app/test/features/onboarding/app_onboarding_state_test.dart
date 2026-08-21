import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/features/onboarding/domain/app_onboarding_state.dart';

void main() {
  test('completed state round-trips without losing its UTC timestamp', () {
    final state = AppOnboardingState.completed(
      completedAt: DateTime.utc(2026, 8, 12, 9, 30),
      method: AppOnboardingCompletionMethod.completed,
    );

    expect(AppOnboardingState.tryFromMap(state.toJson()), state);
    expect(state.isCurrentVersionComplete, isTrue);
  });

  test('older completed version remains pending for the current tour', () {
    final state = AppOnboardingState(
      completedVersion: 0,
      completedAt: DateTime.utc(2026, 8, 12),
      completionMethod: AppOnboardingCompletionMethod.skipped,
    );

    expect(state.isCurrentVersionComplete, isFalse);
  });

  test('invalid persisted values are rejected', () {
    expect(
      AppOnboardingState.tryFromMap({
        'completed_version': -1,
        'completed_at': 'not-a-date',
        'completion_method': 'unknown',
      }),
      isNull,
    );
  });
}
