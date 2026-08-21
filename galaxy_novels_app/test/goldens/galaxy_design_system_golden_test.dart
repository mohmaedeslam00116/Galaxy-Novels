import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/app/app_theme.dart';
import 'package:galaxy_novels_app/design_system/gallery/galaxy_design_system_gallery.dart';

void main() {
  const widths = [320.0, 600.0, 840.0];

  for (final preset in AppThemePreset.values) {
    for (final width in widths) {
      testWidgets('design system ${preset.name} at ${width.toInt()}px', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 1200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            theme: _themeFor(preset),
            home: MediaQuery(
              data: const MediaQueryData(
                textScaler: TextScaler.linear(2),
                disableAnimations: true,
              ),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: GalaxyDesignSystemGallery(initialPreset: preset),
              ),
            ),
          ),
        );
        await tester.pump();

        await expectLater(
          find.byType(GalaxyDesignSystemGallery),
          matchesGoldenFile(
            'goldens/galaxy_design_${preset.name}_${width.toInt()}.png',
          ),
        );
      });
    }
  }
}

ThemeData _themeFor(AppThemePreset preset) => switch (preset) {
  AppThemePreset.galaxyNoir => AppTheme.dark(),
  AppThemePreset.cosmicNight => AppTheme.cosmicNightTheme(),
  AppThemePreset.neutralDark => AppTheme.neutralDarkTheme(),
  AppThemePreset.starlightPaper => AppTheme.light(),
  AppThemePreset.lightNature => AppTheme.lightNatureTheme(),
  AppThemePreset.oceanAsh => AppTheme.oceanAshTheme(),
  AppThemePreset.moonForest => AppTheme.moonForestTheme(),
  AppThemePreset.garnetVelvet => AppTheme.garnetVelvetTheme(),
  AppThemePreset.copperDusk => AppTheme.copperDuskTheme(),
  AppThemePreset.midnightTide => AppTheme.midnightTideTheme(),
};
