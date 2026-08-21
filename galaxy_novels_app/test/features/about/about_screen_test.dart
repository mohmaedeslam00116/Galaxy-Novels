import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/app/app_theme.dart';
import 'package:galaxy_novels_app/features/about/application/app_version_info.dart';
import 'package:galaxy_novels_app/features/about/presentation/about_screen.dart';
import 'package:galaxy_novels_app/core/analytics/app_analytics.dart';
import 'package:galaxy_novels_app/features/app_review/application/app_review_policy_repository.dart';
import 'package:galaxy_novels_app/features/app_review/application/app_review_prompt_controller.dart';
import 'package:galaxy_novels_app/features/app_review/application/app_review_prompt_store.dart';
import 'package:galaxy_novels_app/features/app_review/application/play_app_review_gateway.dart';
import 'package:galaxy_novels_app/features/onboarding/application/app_onboarding_controller.dart';
import 'package:galaxy_novels_app/features/onboarding/application/app_onboarding_store.dart';
import 'package:galaxy_novels_app/features/onboarding/domain/app_onboarding_state.dart';
import 'package:galaxy_novels_app/features/onboarding/presentation/app_onboarding_screen.dart';
import 'package:galaxy_novels_app/features/reader/application/reader_advanced_terminology_repository.dart';
import 'package:galaxy_novels_app/features/reader/data/stored_reader_advanced_terminology_repository.dart';

void main() {
  testWidgets('shows injected package version and build in licenses', (
    tester,
  ) async {
    Future<AppVersionInfo> loader() async {
      return const AppVersionInfo(version: '9.8.7', buildNumber: '42');
    }

    await tester.pumpWidget(_surface(AboutScreen(versionLoader: loader)));
    await tester.pumpAndSettle();

    expect(find.text('الإصدار 9.8.7 (42)'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('open-source-licenses')));
    await tester.pumpAndSettle();

    expect(
      tester.widget<LicensePage>(find.byType(LicensePage)).applicationVersion,
      '9.8.7 (42)',
    );
  });

  testWidgets('omits parentheses when the build number is empty', (
    tester,
  ) async {
    Future<AppVersionInfo> loader() async {
      return const AppVersionInfo(version: '9.8.7', buildNumber: '');
    }

    await tester.pumpWidget(_surface(AboutScreen(versionLoader: loader)));
    await tester.pumpAndSettle();

    expect(find.text('الإصدار 9.8.7'), findsOneWidget);
    expect(find.textContaining('()'), findsNothing);
  });

  testWidgets('calls the version loader once across rebuilds', (tester) async {
    var calls = 0;
    Future<AppVersionInfo> loader() async {
      calls++;
      return const AppVersionInfo(version: '9.8.7', buildNumber: '42');
    }

    await tester.pumpWidget(_surface(AboutScreen(versionLoader: loader)));
    await tester.pumpAndSettle();
    await tester.pumpWidget(_surface(AboutScreen(versionLoader: loader)));
    await tester.pumpAndSettle();

    expect(calls, 1);
  });

  testWidgets('shows a safe fallback when package loading fails', (
    tester,
  ) async {
    Future<AppVersionInfo> loader() {
      throw PlatformException(code: 'unavailable');
    }

    await tester.pumpWidget(_surface(AboutScreen(versionLoader: loader)));
    await tester.pumpAndSettle();

    expect(find.text('الإصدار غير متاح'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('seven version taps unlock advanced terminology tools', (
    tester,
  ) async {
    final repository = StoredReaderAdvancedTerminologyRepository(
      stateStore: _MemoryStateStore(),
      accessStore: _MemoryAccessStore(),
    );
    await tester.pumpWidget(
      _surface(
        AboutScreen(
          versionLoader: () async =>
              const AppVersionInfo(version: '1.2.3', buildNumber: '4'),
          advancedTerminologyRepository: repository,
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (var index = 0; index < 7; index++) {
      await tester.tap(find.byKey(const ValueKey('about-app-version')));
      await tester.pump(const Duration(milliseconds: 80));
    }
    await tester.pumpAndSettle();

    expect(repository.value.accessUnlocked, isTrue);
    expect(find.text('تم تفعيل أدوات المصطلحات المتقدمة'), findsOneWidget);
  });

  testWidgets('rate row opens the store listing without requesting a review', (
    tester,
  ) async {
    final gateway = _ReviewGateway();
    final controller = AppReviewPromptController(
      policies: NoopAppReviewPolicyRepository(),
      store: MemoryAppReviewPromptStore(),
      play: gateway,
      analytics: const NoopAppAnalytics(),
    );
    await controller.initialize();
    await tester.pumpWidget(
      _surface(AboutScreen(reviewPromptController: controller)),
    );

    await tester.tap(find.byKey(const ValueKey('rate-galaxy-novels')));
    await tester.pumpAndSettle();

    expect(gateway.storeOpenCount, 1);
    expect(gateway.reviewRequestCount, 0);
  });

  testWidgets('tour row reopens onboarding without changing completion', (
    tester,
  ) async {
    final completed = AppOnboardingState.completed(
      completedAt: DateTime.utc(2026, 8, 12),
      method: AppOnboardingCompletionMethod.completed,
    );
    final store = _OnboardingStore(completed);
    final controller = AppOnboardingController(
      store: store,
      analytics: const NoopAppAnalytics(),
    );
    await controller.initialize();
    await tester.pumpWidget(
      _surface(AboutScreen(onboardingController: controller)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('replay-onboarding-tour')));
    await tester.pumpAndSettle();

    expect(find.byType(AppOnboardingScreen), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('onboarding-skip')));
    await tester.pumpAndSettle();
    expect(find.byType(AboutScreen), findsOneWidget);
    expect(store.value, completed);
  });
}

class _ReviewGateway implements PlayAppReviewGateway {
  int storeOpenCount = 0;
  int reviewRequestCount = 0;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<void> openStoreListing() async => storeOpenCount += 1;

  @override
  Future<void> requestReview() async => reviewRequestCount += 1;
}

class _MemoryStateStore implements ReaderAdvancedTerminologyStateStore {
  String? value;

  @override
  Future<void> clear() async => value = null;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String value) async => this.value = value;
}

class _MemoryAccessStore implements ReaderAdvancedTerminologyAccessStore {
  bool value = false;

  @override
  Future<bool> read() async => value;

  @override
  Future<void> write(bool value) async => this.value = value;
}

class _OnboardingStore implements AppOnboardingStore {
  _OnboardingStore(this.value);
  AppOnboardingState? value;

  @override
  Future<AppOnboardingState?> read() async => value;

  @override
  Future<void> write(AppOnboardingState state) async => value = state;
}

Widget _surface(Widget child) {
  return MaterialApp(
    theme: AppTheme.dark(),
    home: Directionality(textDirection: TextDirection.rtl, child: child),
  );
}
