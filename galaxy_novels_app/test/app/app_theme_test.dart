import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/app/app_theme.dart';
import 'package:galaxy_novels_app/app/app_theme_controller.dart';

void main() {
  test('exposes the ten approved app theme presets', () {
    expect(AppThemePreset.values, [
      AppThemePreset.starlightPaper,
      AppThemePreset.neutralDark,
      AppThemePreset.galaxyNoir,
      AppThemePreset.cosmicNight,
      AppThemePreset.lightNature,
      AppThemePreset.oceanAsh,
      AppThemePreset.moonForest,
      AppThemePreset.garnetVelvet,
      AppThemePreset.copperDusk,
      AppThemePreset.midnightTide,
    ]);
  });

  test('theme choices expose the expected brightness', () {
    expect(AppThemeChoice.values, [
      AppThemeChoice.starlightPaper,
      AppThemeChoice.neutralDark,
      AppThemeChoice.galaxyNoir,
      AppThemeChoice.cosmicNight,
      AppThemeChoice.lightNature,
      AppThemeChoice.oceanAsh,
      AppThemeChoice.moonForest,
      AppThemeChoice.garnetVelvet,
      AppThemeChoice.copperDusk,
      AppThemeChoice.midnightTide,
    ]);
    expect(AppThemeChoice.starlightPaper.themeMode, ThemeMode.light);
    expect(AppThemeChoice.neutralDark.themeMode, ThemeMode.dark);
    expect(AppThemeChoice.galaxyNoir.themeMode, ThemeMode.dark);
    expect(AppThemeChoice.cosmicNight.themeMode, ThemeMode.dark);
    expect(AppThemeChoice.lightNature.themeMode, ThemeMode.light);
    expect(AppThemeChoice.oceanAsh.themeMode, ThemeMode.dark);
    expect(AppThemeChoice.moonForest.themeMode, ThemeMode.dark);
    expect(AppThemeChoice.garnetVelvet.themeMode, ThemeMode.dark);
    expect(AppThemeChoice.copperDusk.themeMode, ThemeMode.dark);
    expect(AppThemeChoice.midnightTide.themeMode, ThemeMode.dark);
  });

  test('Galaxy Noir exposes the muted nebula semantic palette', () {
    final tokens = AppTheme.dark().extension<AppThemeTokens>()!;

    expect(tokens.preset, AppThemePreset.galaxyNoir);
    expect(tokens.canvas, const Color(0xFF0E1520));
    expect(tokens.surface, const Color(0xFF141E2B));
    expect(tokens.surfaceRaised, const Color(0xFF1B2838));
    expect(tokens.contentPrimary, const Color(0xFFE8EDF4));
    expect(tokens.contentSecondary, const Color(0xFFA8B3C2));
    expect(tokens.brand, const Color(0xFF8EA9D1));
    expect(tokens.onBrand, const Color(0xFF101820));
    expect(tokens.brandContainer, const Color(0xFF263A52));
    expect(tokens.onBrandContainer, const Color(0xFFDCE8F7));
    expect(tokens.outline, const Color(0xFF34475D));
    expect(tokens.warning, const Color(0xFFC5A568));
  });

  test('Starlight Paper exposes the approved semantic palette', () {
    final tokens = AppTheme.light().extension<AppThemeTokens>()!;

    expect(tokens.preset, AppThemePreset.starlightPaper);
    expect(tokens.canvas, const Color(0xFFF3EFE7));
    expect(tokens.surface, const Color(0xFFFAF7F0));
    expect(tokens.surfaceRaised, const Color(0xFFFFFDF8));
    expect(tokens.contentPrimary, const Color(0xFF252B33));
    expect(tokens.contentSecondary, const Color(0xFF5E6872));
    expect(tokens.brand, const Color(0xFF536C8C));
    expect(tokens.onBrand, const Color(0xFFF7FAFF));
    expect(tokens.warning, const Color(0xFF8A6C2D));
  });

  test('all presets expose their approved muted identity colors', () {
    final expectations = <ThemeData, List<Color>>{
      AppTheme.neutralDarkTheme(): const [
        Color(0xFF111315),
        Color(0xFF181B1E),
        Color(0xFF22262A),
        Color(0xFF9DABB7),
      ],
      AppTheme.cosmicNightTheme(): const [
        Color(0xFF14131B),
        Color(0xFF1B1924),
        Color(0xFF252232),
        Color(0xFFA99AC8),
      ],
      AppTheme.lightNatureTheme(): const [
        Color(0xFFF1EBDD),
        Color(0xFFF8F3E9),
        Color(0xFFFFFAF2),
        Color(0xFF5E7864),
      ],
      AppTheme.oceanAshTheme(): const [
        Color(0xFF181E25),
        Color(0xFF222B34),
        Color(0xFF2D3843),
        Color(0xFF91AFC8),
      ],
      AppTheme.moonForestTheme(): const [
        Color(0xFF101915),
        Color(0xFF17231D),
        Color(0xFF213129),
        Color(0xFF86A98D),
      ],
      AppTheme.garnetVelvetTheme(): const [
        Color(0xFF1A1216),
        Color(0xFF24191E),
        Color(0xFF302228),
        Color(0xFFC28F9C),
      ],
      AppTheme.copperDuskTheme(): const [
        Color(0xFF1A1511),
        Color(0xFF241D17),
        Color(0xFF31271E),
        Color(0xFFC39A72),
      ],
      AppTheme.midnightTideTheme(): const [
        Color(0xFF0E191A),
        Color(0xFF152426),
        Color(0xFF1E3134),
        Color(0xFF79AAA8),
      ],
    };

    for (final entry in expectations.entries) {
      final tokens = entry.key.extension<AppThemeTokens>()!;
      expect([
        tokens.canvas,
        tokens.surface,
        tokens.surfaceRaised,
        tokens.brand,
      ], entry.value);
    }
  });

  test('new dark themes expose their complete approved palettes', () {
    final expectations = <ThemeData, List<Color>>{
      AppTheme.oceanAshTheme(): const [
        Color(0xFF181E25),
        Color(0xFF222B34),
        Color(0xFF2D3843),
        Color(0xFFEDF2F6),
        Color(0xFFABB8C5),
        Color(0xFF91AFC8),
        Color(0xFF12202B),
        Color(0xFF33495D),
        Color(0xFFE3EDF5),
        Color(0xFF485A69),
      ],
      AppTheme.moonForestTheme(): const [
        Color(0xFF101915),
        Color(0xFF17231D),
        Color(0xFF213129),
        Color(0xFFE7EEE9),
        Color(0xFFA6B6AA),
        Color(0xFF86A98D),
        Color(0xFF102017),
        Color(0xFF294232),
        Color(0xFFD9E9DD),
        Color(0xFF3A5645),
      ],
      AppTheme.garnetVelvetTheme(): const [
        Color(0xFF1A1216),
        Color(0xFF24191E),
        Color(0xFF302228),
        Color(0xFFF1E8EB),
        Color(0xFFC0AAB1),
        Color(0xFFC28F9C),
        Color(0xFF2A1118),
        Color(0xFF4A2C35),
        Color(0xFFF0DDE3),
        Color(0xFF62404A),
      ],
      AppTheme.copperDuskTheme(): const [
        Color(0xFF1A1511),
        Color(0xFF241D17),
        Color(0xFF31271E),
        Color(0xFFF2ECE6),
        Color(0xFFBFAFA0),
        Color(0xFFC39A72),
        Color(0xFF27170C),
        Color(0xFF493522),
        Color(0xFFF2DEC8),
        Color(0xFF604A38),
      ],
      AppTheme.midnightTideTheme(): const [
        Color(0xFF0E191A),
        Color(0xFF152426),
        Color(0xFF1E3134),
        Color(0xFFE6EFF0),
        Color(0xFFA4B7B9),
        Color(0xFF79AAA8),
        Color(0xFF0D2222),
        Color(0xFF294447),
        Color(0xFFD8EAEB),
        Color(0xFF3C5B5E),
      ],
    };

    for (final entry in expectations.entries) {
      final tokens = entry.key.extension<AppThemeTokens>()!;
      expect([
        tokens.canvas,
        tokens.surface,
        tokens.surfaceRaised,
        tokens.contentPrimary,
        tokens.contentSecondary,
        tokens.brand,
        tokens.onBrand,
        tokens.brandContainer,
        tokens.onBrandContainer,
        tokens.outline,
      ], entry.value);
    }
  });

  test('themes use Readex Pro and the shared premium component geometry', () {
    for (final theme in [
      AppTheme.light(),
      AppTheme.neutralDarkTheme(),
      AppTheme.dark(),
      AppTheme.cosmicNightTheme(),
      AppTheme.lightNatureTheme(),
      AppTheme.oceanAshTheme(),
      AppTheme.moonForestTheme(),
      AppTheme.garnetVelvetTheme(),
      AppTheme.copperDuskTheme(),
      AppTheme.midnightTideTheme(),
    ]) {
      expect(theme.textTheme.bodyMedium?.fontFamily, 'Readex Pro');
      expect(theme.cardTheme.elevation, 0);
      expect(theme.navigationBarTheme.height, 68);
      expect(theme.dialogTheme.shape, isA<RoundedRectangleBorder>());
    }

    expect(AppVisualMetrics.radiusSmall, 8);
    expect(AppVisualMetrics.radiusControl, 12);
    expect(AppVisualMetrics.radiusCard, 16);
    expect(AppVisualMetrics.radiusOverlay, 24);
    expect(AppVisualMetrics.minimumTouchTarget, 48);
    expect(AppVisualMetrics.themeTransition, const Duration(milliseconds: 220));
  });

  test('semantic foreground pairs meet normal-text AA contrast', () {
    for (final theme in [
      AppTheme.light(),
      AppTheme.neutralDarkTheme(),
      AppTheme.dark(),
      AppTheme.cosmicNightTheme(),
      AppTheme.lightNatureTheme(),
      AppTheme.oceanAshTheme(),
      AppTheme.moonForestTheme(),
      AppTheme.garnetVelvetTheme(),
      AppTheme.copperDuskTheme(),
      AppTheme.midnightTideTheme(),
    ]) {
      final tokens = theme.extension<AppThemeTokens>()!;
      expect(
        _contrastRatio(tokens.contentPrimary, tokens.canvas),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrastRatio(tokens.contentSecondary, tokens.canvas),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrastRatio(tokens.onBrand, tokens.brand),
        greaterThanOrEqualTo(4.5),
      );
    }
  });

  test('system bar icons follow every theme brightness', () {
    for (final theme in [AppTheme.light(), AppTheme.lightNatureTheme()]) {
      final overlay = AppTheme.systemOverlayStyleFor(theme);
      expect(overlay.statusBarIconBrightness, Brightness.dark);
      expect(overlay.systemNavigationBarIconBrightness, Brightness.dark);
    }

    for (final theme in [
      AppTheme.neutralDarkTheme(),
      AppTheme.dark(),
      AppTheme.cosmicNightTheme(),
      AppTheme.oceanAshTheme(),
      AppTheme.moonForestTheme(),
      AppTheme.garnetVelvetTheme(),
      AppTheme.copperDuskTheme(),
      AppTheme.midnightTideTheme(),
    ]) {
      final overlay = AppTheme.systemOverlayStyleFor(theme);
      expect(overlay.statusBarIconBrightness, Brightness.light);
      expect(overlay.systemNavigationBarIconBrightness, Brightness.light);
    }
  });
}

double _contrastRatio(Color foreground, Color background) {
  final lighter = foreground.computeLuminance() > background.computeLuminance()
      ? foreground
      : background;
  final darker = identical(lighter, foreground) ? background : foreground;

  return (lighter.computeLuminance() + 0.05) /
      (darker.computeLuminance() + 0.05);
}
