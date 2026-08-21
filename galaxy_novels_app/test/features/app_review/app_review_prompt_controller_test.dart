import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/core/analytics/app_analytics.dart';
import 'package:galaxy_novels_app/features/app_review/application/app_review_policy_repository.dart';
import 'package:galaxy_novels_app/features/app_review/application/app_review_prompt_controller.dart';
import 'package:galaxy_novels_app/features/app_review/application/app_review_prompt_store.dart';
import 'package:galaxy_novels_app/features/app_review/application/play_app_review_gateway.dart';
import 'package:galaxy_novels_app/features/app_review/domain/app_review_policy.dart';
import 'package:galaxy_novels_app/features/app_review/domain/app_review_prompt_state.dart';

void main() {
  final now = DateTime.utc(2026, 8, 11, 12);

  test('counts a completed chapter once per reader session', () async {
    final store = _MemoryStore(
      AppReviewPromptState.initial(now.subtract(const Duration(days: 4))),
    );
    final controller = _controller(store: store, now: now);
    await controller.initialize();

    controller.startReadingSession();
    await controller.recordChapterProgress(chapterId: 7, progress: 92);
    await controller.recordChapterProgress(chapterId: 7, progress: 100);
    await controller.finishReadingSession();

    expect(store.value!.completedChapterCount, 1);
    expect(store.value!.qualifyingSessionCount, 1);
  });

  test(
    'requests only after days, chapters, and sessions are eligible',
    () async {
      final gateway = _FakeGateway();
      final store = _MemoryStore(
        AppReviewPromptState(
          firstOpenedAt: now.subtract(const Duration(days: 3)),
          completedChapterCount: 9,
          qualifyingSessionCount: 1,
          lastAutomaticAttemptAt: null,
          automaticAttemptCount: 0,
          lastUnavailableAt: null,
          lastManualStoreOpenAt: null,
        ),
      );
      final controller = _controller(store: store, now: now, gateway: gateway);
      await controller.initialize();
      controller.startReadingSession();
      await controller.recordChapterProgress(chapterId: 10, progress: 92);
      expect(await controller.finishReadingSession(), isTrue);

      expect(
        await controller.tryRequestReview(canPresent: true),
        AppReviewRequestResult.requested,
      );
      expect(gateway.requestCount, 1);
      expect(store.value!.automaticAttemptCount, 1);
    },
  );

  test('reader interstitial defers the current session prompt', () async {
    final gateway = _FakeGateway();
    final store = _MemoryStore(
      AppReviewPromptState(
        firstOpenedAt: now.subtract(const Duration(days: 20)),
        completedChapterCount: 10,
        qualifyingSessionCount: 2,
        lastAutomaticAttemptAt: null,
        automaticAttemptCount: 0,
        lastUnavailableAt: null,
        lastManualStoreOpenAt: null,
      ),
    );
    final controller = _controller(store: store, now: now, gateway: gateway);
    await controller.initialize();
    controller.startReadingSession();
    controller.markFullScreenAdShown();
    await controller.recordChapterProgress(chapterId: 11, progress: 92);

    expect(await controller.finishReadingSession(), isFalse);
    expect(
      await controller.tryRequestReview(canPresent: true),
      AppReviewRequestResult.notScheduled,
    );
    expect(gateway.requestCount, 0);
  });

  test(
    'unavailable Play does not consume an attempt and waits seven days',
    () async {
      final gateway = _FakeGateway(available: false);
      final store = _MemoryStore(_eligibleState(now));
      final controller = _controller(store: store, now: now, gateway: gateway);
      await controller.initialize();
      controller.startReadingSession();
      await controller.recordChapterProgress(chapterId: 12, progress: 92);
      await controller.finishReadingSession();

      expect(
        await controller.tryRequestReview(canPresent: true),
        AppReviewRequestResult.unavailable,
      );
      expect(store.value!.automaticAttemptCount, 0);
      expect(store.value!.lastUnavailableAt, now);
    },
  );

  test(
    'manual store open snoozes automatic requests without an attempt',
    () async {
      final gateway = _FakeGateway();
      final store = _MemoryStore(_eligibleState(now));
      final controller = _controller(store: store, now: now, gateway: gateway);
      await controller.initialize();

      expect(await controller.openStoreListing(), isTrue);
      expect(store.value!.automaticAttemptCount, 0);
      expect(store.value!.lastManualStoreOpenAt, now);
    },
  );

  test('cooldown allows day 120 but not day 119', () async {
    final gateway = _FakeGateway();
    final attemptAt = now.subtract(const Duration(days: 119));
    final store = _MemoryStore(
      _eligibleState(now).copyWith(lastAutomaticAttemptAt: attemptAt),
    );
    var current = now;
    final controller = AppReviewPromptController(
      policies: _FakePolicyRepository(),
      store: store,
      play: gateway,
      analytics: const NoopAppAnalytics(),
      now: () => current,
    );
    await controller.initialize();
    controller.startReadingSession();
    await controller.recordChapterProgress(chapterId: 13, progress: 92);
    expect(await controller.finishReadingSession(), isFalse);

    current = attemptAt.add(const Duration(days: 120));
    controller.startReadingSession();
    await controller.recordChapterProgress(chapterId: 14, progress: 92);
    expect(await controller.finishReadingSession(), isTrue);
  });

  test('three automatic attempts permanently stop scheduling', () async {
    final store = _MemoryStore(
      _eligibleState(now).copyWith(automaticAttemptCount: 3),
    );
    final controller = _controller(store: store, now: now);
    await controller.initialize();
    controller.startReadingSession();
    await controller.recordChapterProgress(chapterId: 15, progress: 92);

    expect(await controller.finishReadingSession(), isFalse);
  });

  test('manual store failure does not start a cooldown', () async {
    final gateway = _FakeGateway(failStoreOpen: true);
    final store = _MemoryStore(_eligibleState(now));
    final controller = _controller(store: store, now: now, gateway: gateway);
    await controller.initialize();

    expect(await controller.openStoreListing(), isFalse);
    expect(store.value!.lastManualStoreOpenAt, isNull);
  });

  test('serializes a completion racing with reader disposal', () async {
    final store = _MemoryStore(
      AppReviewPromptState.initial(now.subtract(const Duration(days: 4))),
      writeDelay: const Duration(milliseconds: 5),
    );
    final controller = _controller(store: store, now: now);
    await controller.initialize();
    controller.startReadingSession();

    final completion = controller.recordChapterProgress(
      chapterId: 21,
      progress: 92,
    );
    final disposal = controller.finishReadingSession();
    await Future.wait<void>([completion, disposal.then((_) {})]);

    expect(store.value!.completedChapterCount, 1);
    expect(store.value!.qualifyingSessionCount, 1);
  });
}

AppReviewPromptController _controller({
  required _MemoryStore store,
  required DateTime now,
  _FakeGateway? gateway,
}) {
  return AppReviewPromptController(
    policies: _FakePolicyRepository(),
    store: store,
    play: gateway ?? _FakeGateway(),
    analytics: const NoopAppAnalytics(),
    now: () => now,
  );
}

AppReviewPromptState _eligibleState(DateTime now) => AppReviewPromptState(
  firstOpenedAt: now.subtract(const Duration(days: 30)),
  completedChapterCount: 10,
  qualifyingSessionCount: 2,
  lastAutomaticAttemptAt: null,
  automaticAttemptCount: 0,
  lastUnavailableAt: null,
  lastManualStoreOpenAt: null,
);

class _MemoryStore implements AppReviewPromptStore {
  _MemoryStore(this.value, {this.writeDelay = Duration.zero});
  AppReviewPromptState? value;
  final Duration writeDelay;

  @override
  Future<AppReviewPromptState?> read() async => value;

  @override
  Future<void> write(AppReviewPromptState state) async {
    if (writeDelay != Duration.zero) await Future<void>.delayed(writeDelay);
    value = state;
  }
}

class _FakePolicyRepository extends NoopAppReviewPolicyRepository {
  @override
  AppReviewPolicy get value => AppReviewPolicy.defaults;
}

class _FakeGateway implements PlayAppReviewGateway {
  _FakeGateway({this.available = true, this.failStoreOpen = false});
  bool available;
  bool failStoreOpen;
  int requestCount = 0;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<void> requestReview() async => requestCount += 1;

  @override
  Future<void> openStoreListing() async {
    if (failStoreOpen) throw Exception('store failed');
  }
}
