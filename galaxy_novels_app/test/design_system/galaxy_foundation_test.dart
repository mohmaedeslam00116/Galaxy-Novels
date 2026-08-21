import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/app/app_theme.dart';
import 'package:galaxy_novels_app/design_system/foundation/galaxy_adaptive.dart';
import 'package:galaxy_novels_app/design_system/foundation/galaxy_motion.dart';
import 'package:galaxy_novels_app/design_system/foundation/galaxy_route.dart';

void main() {
  test(
    'app themes expose GalaxyDesignTokens through the compatibility alias',
    () {
      final theme = AppTheme.dark();
      final galaxyTokens = theme.extension<GalaxyDesignTokens>();
      final compatibilityTokens = theme.extension<AppThemeTokens>();

      expect(galaxyTokens, isNotNull);
      expect(identical(galaxyTokens, compatibilityTokens), isTrue);
      expect(galaxyTokens!.preset, AppThemePreset.galaxyNoir);
    },
  );

  test('GalaxyMetrics define the approved visual scale', () {
    expect(GalaxyMetrics.radiusSmall, 8);
    expect(GalaxyMetrics.radiusControl, 12);
    expect(GalaxyMetrics.radiusCard, 16);
    expect(GalaxyMetrics.radiusOverlay, 24);
    expect(GalaxyMetrics.minimumTouchTarget, 48);
    expect(GalaxyMetrics.coverAspectRatio, 2 / 3);
  });

  test('GalaxyMotion defines the approved motion budget', () {
    expect(GalaxyMotion.press, const Duration(milliseconds: 120));
    expect(GalaxyMotion.stateChange, const Duration(milliseconds: 180));
    expect(GalaxyMotion.emphasis, const Duration(milliseconds: 220));
    expect(GalaxyMotion.route, const Duration(milliseconds: 240));
    expect(GalaxyMotion.curve, Curves.easeOutCubic);
  });

  test('GalaxyAdaptive classifies phone tablet and expanded widths', () {
    expect(GalaxyAdaptive.windowClassFor(320), GalaxyWindowClass.compact);
    expect(GalaxyAdaptive.windowClassFor(600), GalaxyWindowClass.medium);
    expect(GalaxyAdaptive.windowClassFor(840), GalaxyWindowClass.expanded);
    expect(GalaxyAdaptive.horizontalPaddingFor(320), 16);
    expect(GalaxyAdaptive.horizontalPaddingFor(600), 20);
    expect(GalaxyAdaptive.horizontalPaddingFor(840), 24);
  });

  testWidgets('GalaxyMotion becomes immediate when reduce motion is enabled', (
    tester,
  ) async {
    late Duration resolvedDuration;
    late PageRoute<void> route;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Builder(
            builder: (context) {
              resolvedDuration = GalaxyMotion.resolve(
                context,
                GalaxyMotion.emphasis,
              );
              route = galaxyPageRoute<void>(
                context: context,
                builder: (_) => const SizedBox(),
              );
              return const SizedBox();
            },
          ),
        ),
      ),
    );

    expect(resolvedDuration, Duration.zero);
    expect(route.transitionDuration, Duration.zero);
  });

  testWidgets('Galaxy route uses the 240ms prominent transition budget', (
    tester,
  ) async {
    late PageRoute<void> route;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            route = galaxyPageRoute<void>(
              context: context,
              builder: (_) => const SizedBox(),
            );
            return const SizedBox();
          },
        ),
      ),
    );

    expect(route.transitionDuration, GalaxyMotion.route);
    expect(route.reverseTransitionDuration, GalaxyMotion.route);
  });
}
