import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/core/analytics/app_analytics.dart';
import 'package:galaxy_novels_app/features/onboarding/application/app_onboarding_controller.dart';
import 'package:galaxy_novels_app/features/onboarding/application/app_onboarding_store.dart';
import 'package:galaxy_novels_app/features/onboarding/domain/app_onboarding_state.dart';

void main() {
  final now = DateTime.utc(2026, 8, 12, 10);

  test(
    'missing state schedules the automatic tour and suppresses cold ad',
    () async {
      final controller = AppOnboardingController(
        store: _MemoryStore(),
        analytics: _RecordingAnalytics(),
        now: () => now,
      );

      await controller.initialize();

      expect(controller.shouldShowAutomatic, isTrue);
      expect(controller.suppressColdStartAdForSession, isTrue);
    },
  );

  test('completed current version skips the tour and keeps cold ad', () async {
    final controller = AppOnboardingController(
      store: _MemoryStore(
        value: AppOnboardingState.completed(
          completedAt: now,
          method: AppOnboardingCompletionMethod.completed,
        ),
      ),
      analytics: _RecordingAnalytics(),
      now: () => now,
    );

    await controller.initialize();

    expect(controller.shouldShowAutomatic, isFalse);
    expect(controller.suppressColdStartAdForSession, isFalse);
  });

  test(
    'completion persists and records the expected analytics event',
    () async {
      final store = _MemoryStore();
      final analytics = _RecordingAnalytics();
      final controller = AppOnboardingController(
        store: store,
        analytics: analytics,
        now: () => now,
      );
      await controller.initialize();

      await controller.completeAutomatic(AppOnboardingCompletionMethod.skipped);

      expect(controller.shouldShowAutomatic, isFalse);
      expect(
        store.value?.completionMethod,
        AppOnboardingCompletionMethod.skipped,
      );
      expect(analytics.events, contains('onboarding_skipped'));
    },
  );

  test('write failure does not trap the user in the tour', () async {
    final analytics = _RecordingAnalytics();
    final controller = AppOnboardingController(
      store: _MemoryStore(failWrites: true),
      analytics: analytics,
      now: () => now,
    );
    await controller.initialize();

    await controller.completeAutomatic(AppOnboardingCompletionMethod.completed);

    expect(controller.shouldShowAutomatic, isFalse);
    expect(analytics.events, contains('onboarding_persistence_failed'));
    expect(analytics.events, contains('onboarding_completed'));
  });

  test('read failure shows the tour and records persistence failure', () async {
    final analytics = _RecordingAnalytics();
    final controller = AppOnboardingController(
      store: _MemoryStore(failReads: true),
      analytics: analytics,
      now: () => now,
    );

    await controller.initialize();

    expect(controller.shouldShowAutomatic, isTrue);
    expect(analytics.events, contains('onboarding_persistence_failed'));
  });

  test('analytics failure never interrupts onboarding startup', () async {
    final controller = AppOnboardingController(
      store: _MemoryStore(),
      analytics: _RecordingAnalytics(failScreenViews: true),
      now: () => now,
    );
    await controller.initialize();

    await expectLater(
      controller.recordShown(AppOnboardingEntryPoint.automatic),
      completes,
    );
  });

  test('manual replay analytics never changes persisted completion', () async {
    final completed = AppOnboardingState.completed(
      completedAt: now,
      method: AppOnboardingCompletionMethod.completed,
    );
    final store = _MemoryStore(value: completed);
    final analytics = _RecordingAnalytics();
    final controller = AppOnboardingController(
      store: store,
      analytics: analytics,
      now: () => now,
    );
    await controller.initialize();

    await controller.recordManualReopened();

    expect(store.value, completed);
    expect(analytics.events, contains('onboarding_reopened'));
  });
}

class _MemoryStore implements AppOnboardingStore {
  _MemoryStore({this.value, this.failReads = false, this.failWrites = false});

  AppOnboardingState? value;
  final bool failReads;
  final bool failWrites;

  @override
  Future<AppOnboardingState?> read() async {
    if (failReads) throw Exception('read failed');
    return value;
  }

  @override
  Future<void> write(AppOnboardingState state) async {
    if (failWrites) throw Exception('write failed');
    value = state;
  }
}

class _RecordingAnalytics implements AppAnalytics {
  _RecordingAnalytics({this.failScreenViews = false});

  final List<String> events = [];
  final bool failScreenViews;

  @override
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    events.add(name);
  }

  @override
  Future<void> logScreenView(String screenName) async {
    if (failScreenViews) throw Exception('screen view failed');
  }
}
