import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/app/app_theme.dart';
import 'package:galaxy_novels_app/core/analytics/app_analytics.dart';
import 'package:galaxy_novels_app/features/onboarding/application/app_onboarding_controller.dart';
import 'package:galaxy_novels_app/features/onboarding/application/app_onboarding_store.dart';
import 'package:galaxy_novels_app/features/onboarding/domain/app_onboarding_state.dart';
import 'package:galaxy_novels_app/features/onboarding/presentation/app_onboarding_screen.dart';

void main() {
  testWidgets('moves forward and backward through the three pages', (
    tester,
  ) async {
    final harness = await _pumpScreen(tester);

    expect(find.text('اكتشف عالمك القادم'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('onboarding-next')));
    await tester.pumpAndSettle();
    expect(find.text('اقرأ بطريقتك'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('onboarding-previous')));
    await tester.pumpAndSettle();
    expect(find.text('اكتشف عالمك القادم'), findsOneWidget);
    expect(harness.finishedCount, 0);
  });

  testWidgets('rapid next taps do not start overlapping page transitions', (
    tester,
  ) async {
    await _pumpScreen(tester);
    final next = find.byKey(const ValueKey('onboarding-next'));

    await tester.tap(next);
    await tester.tap(next);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('اقرأ بطريقتك'), findsOneWidget);
  });

  testWidgets('skip completes the automatic tour once', (tester) async {
    final harness = await _pumpScreen(tester);

    await tester.tap(find.byKey(const ValueKey('onboarding-skip')));
    await tester.pumpAndSettle();

    expect(
      harness.store.value?.completionMethod,
      AppOnboardingCompletionMethod.skipped,
    );
    expect(harness.finishedCount, 1);
  });

  testWidgets('last page completes the automatic tour', (tester) async {
    final harness = await _pumpScreen(tester);

    await tester.tap(find.byKey(const ValueKey('onboarding-next')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('onboarding-next')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('onboarding-start')));
    await tester.pumpAndSettle();

    expect(
      harness.store.value?.completionMethod,
      AppOnboardingCompletionMethod.completed,
    );
    expect(harness.finishedCount, 1);
  });

  testWidgets('manual replay closes without rewriting completion', (
    tester,
  ) async {
    final completed = AppOnboardingState.completed(
      completedAt: DateTime.utc(2026, 8, 12),
      method: AppOnboardingCompletionMethod.completed,
    );
    final harness = await _pumpScreen(
      tester,
      entryPoint: AppOnboardingEntryPoint.manual,
      initialState: completed,
    );

    await tester.tap(find.byKey(const ValueKey('onboarding-skip')));
    await tester.pumpAndSettle();

    expect(harness.store.value, completed);
    expect(harness.finishedCount, 1);
  });

  testWidgets('fits a 320dp screen with 200 percent text', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpScreen(tester, textScaler: const TextScaler.linear(2));

    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('onboarding-next')), findsOneWidget);
  });
}

Future<_Harness> _pumpScreen(
  WidgetTester tester, {
  AppOnboardingEntryPoint entryPoint = AppOnboardingEntryPoint.automatic,
  AppOnboardingState? initialState,
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  final store = _MemoryStore(initialState);
  final controller = AppOnboardingController(
    store: store,
    analytics: const NoopAppAnalytics(),
    now: () => DateTime.utc(2026, 8, 12),
  );
  await controller.initialize();
  var finishedCount = 0;
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('ar'),
      theme: AppTheme.dark(),
      home: MediaQuery(
        data: MediaQueryData(textScaler: textScaler),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: AppOnboardingScreen(
            controller: controller,
            entryPoint: entryPoint,
            onFinished: () => finishedCount += 1,
            onExitRequested: () {},
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return _Harness(store: store, getFinishedCount: () => finishedCount);
}

class _Harness {
  const _Harness({required this.store, required this.getFinishedCount});

  final _MemoryStore store;
  final int Function() getFinishedCount;

  int get finishedCount => getFinishedCount();
}

class _MemoryStore implements AppOnboardingStore {
  _MemoryStore(this.value);
  AppOnboardingState? value;

  @override
  Future<AppOnboardingState?> read() async => value;

  @override
  Future<void> write(AppOnboardingState state) async => value = state;
}
