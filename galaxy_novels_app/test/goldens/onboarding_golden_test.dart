import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/app/app_theme.dart';
import 'package:galaxy_novels_app/app/app_theme_controller.dart';
import 'package:galaxy_novels_app/core/analytics/app_analytics.dart';
import 'package:galaxy_novels_app/features/onboarding/application/app_onboarding_controller.dart';
import 'package:galaxy_novels_app/features/onboarding/application/app_onboarding_store.dart';
import 'package:galaxy_novels_app/features/onboarding/presentation/app_onboarding_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await Future.wait([
      (FontLoader(
        'Readex Pro',
      )..addFont(rootBundle.load('assets/fonts/ReadexPro.ttf'))).load(),
      (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load(),
    ]);
  });

  for (final themeChoice in AppThemeChoice.values) {
    for (final width in const [320, 600, 840]) {
      testWidgets('onboarding ${themeChoice.name} at ${width}dp', (
        tester,
      ) async {
        await _pumpOnboarding(
          tester,
          themeChoice: themeChoice,
          size: Size(width.toDouble(), 1000),
          textScale: 2,
        );

        expect(tester.takeException(), isNull);
        await expectLater(
          find.byKey(const ValueKey('app-onboarding-screen')),
          matchesGoldenFile(
            'goldens/onboarding_${themeChoice.name}_$width.png',
          ),
        );
      });
    }
  }

  testWidgets('onboarding remains usable in landscape', (tester) async {
    await _pumpOnboarding(
      tester,
      themeChoice: AppThemeChoice.galaxyNoir,
      size: const Size(840, 480),
      textScale: 1,
    );

    expect(tester.takeException(), isNull);
    await expectLater(
      find.byKey(const ValueKey('app-onboarding-screen')),
      matchesGoldenFile('goldens/onboarding_galaxyNoir_landscape.png'),
    );
  });
}

Future<void> _pumpOnboarding(
  WidgetTester tester, {
  required AppThemeChoice themeChoice,
  required Size size,
  required double textScale,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    tester.platformDispatcher.clearTextScaleFactorTestValue();
  });

  final controller = AppOnboardingController(
    store: MemoryAppOnboardingStore(),
    analytics: const NoopAppAnalytics(),
  );
  await controller.initialize();
  addTearDown(controller.dispose);

  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('ar'),
      theme: _themeFor(themeChoice),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: AppOnboardingScreen(
          controller: controller,
          entryPoint: AppOnboardingEntryPoint.automatic,
          onFinished: () {},
          onExitRequested: () {},
        ),
      ),
    ),
  );
  await tester.pump();
}

ThemeData _themeFor(AppThemeChoice choice) => switch (choice) {
  AppThemeChoice.starlightPaper => AppTheme.light(),
  AppThemeChoice.neutralDark => AppTheme.neutralDarkTheme(),
  AppThemeChoice.galaxyNoir => AppTheme.dark(),
  AppThemeChoice.cosmicNight => AppTheme.cosmicNightTheme(),
  AppThemeChoice.lightNature => AppTheme.lightNatureTheme(),
  AppThemeChoice.oceanAsh => AppTheme.oceanAshTheme(),
  AppThemeChoice.moonForest => AppTheme.moonForestTheme(),
  AppThemeChoice.garnetVelvet => AppTheme.garnetVelvetTheme(),
  AppThemeChoice.copperDusk => AppTheme.copperDuskTheme(),
  AppThemeChoice.midnightTide => AppTheme.midnightTideTheme(),
};
