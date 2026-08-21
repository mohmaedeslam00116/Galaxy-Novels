import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/core/analytics/app_analytics.dart';
import 'package:galaxy_novels_app/core/analytics/app_screen_names.dart';
import 'package:galaxy_novels_app/features/app_review/application/app_review_policy_repository.dart';
import 'package:galaxy_novels_app/features/app_review/application/app_review_prompt_controller.dart';
import 'package:galaxy_novels_app/features/app_review/application/app_review_prompt_store.dart';
import 'package:galaxy_novels_app/features/app_review/application/play_app_review_gateway.dart';
import 'package:galaxy_novels_app/features/app_review/domain/app_review_prompt_state.dart';
import 'package:galaxy_novels_app/features/app_review/presentation/app_review_prompt_navigator_observer.dart';

void main() {
  testWidgets('requests after the reader pops to a stable page', (
    tester,
  ) async {
    final harness = await _Harness.create();
    addTearDown(harness.dispose);
    await tester.pumpWidget(harness.app);

    harness.pushReader();
    await tester.pumpAndSettle();
    harness.navigator.currentState!.pop();
    await tester.pump(const Duration(milliseconds: 120));

    expect(harness.gateway.requestCount, 1);
  });

  testWidgets('a dialog defers the request until the dialog closes', (
    tester,
  ) async {
    final harness = await _Harness.create();
    addTearDown(harness.dispose);
    await tester.pumpWidget(harness.app);

    harness.pushReader();
    await tester.pumpAndSettle();
    harness.navigator.currentState!.pop();
    showDialog<void>(
      context: harness.navigator.currentContext!,
      builder: (_) => const AlertDialog(title: Text('حوار')),
    );
    await tester.pump(const Duration(milliseconds: 120));
    expect(harness.gateway.requestCount, 0);

    harness.navigator.currentState!.pop();
    await tester.pump(const Duration(milliseconds: 120));
    expect(harness.gateway.requestCount, 1);
  });
}

class _Harness {
  _Harness._({
    required this.controller,
    required this.gateway,
    required this.observer,
  });

  static Future<_Harness> create() async {
    final now = DateTime.utc(2026, 8, 11);
    final gateway = _Gateway();
    final controller = AppReviewPromptController(
      policies: NoopAppReviewPolicyRepository(),
      store: _Store(
        AppReviewPromptState(
          firstOpenedAt: now.subtract(const Duration(days: 30)),
          completedChapterCount: 10,
          qualifyingSessionCount: 2,
          lastAutomaticAttemptAt: null,
          automaticAttemptCount: 0,
          lastUnavailableAt: null,
          lastManualStoreOpenAt: null,
        ),
      ),
      play: gateway,
      analytics: const NoopAppAnalytics(),
      now: () => now,
    );
    await controller.initialize();
    controller.startReadingSession();
    await controller.recordChapterProgress(chapterId: 1, progress: 92);
    await controller.finishReadingSession();
    final observer = AppReviewPromptNavigatorObserver(
      controller: controller,
      isForcedUpdateActive: () => false,
      stabilityDelay: const Duration(milliseconds: 100),
    );
    return _Harness._(
      controller: controller,
      gateway: gateway,
      observer: observer,
    );
  }

  final navigator = GlobalKey<NavigatorState>();
  final AppReviewPromptController controller;
  final _Gateway gateway;
  final AppReviewPromptNavigatorObserver observer;

  Widget get app => MaterialApp(
    navigatorKey: navigator,
    navigatorObservers: [observer],
    home: const Scaffold(body: Text('الرئيسية')),
  );

  void pushReader() {
    navigator.currentState!.push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: AppScreenNames.reader),
        builder: (_) => const Scaffold(body: Text('القارئ')),
      ),
    );
  }

  void dispose() {
    observer.dispose();
    controller.dispose();
  }
}

class _Store implements AppReviewPromptStore {
  _Store(this.value);
  AppReviewPromptState? value;

  @override
  Future<AppReviewPromptState?> read() async => value;

  @override
  Future<void> write(AppReviewPromptState state) async => value = state;
}

class _Gateway implements PlayAppReviewGateway {
  int requestCount = 0;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<void> openStoreListing() async {}

  @override
  Future<void> requestReview() async => requestCount += 1;
}
