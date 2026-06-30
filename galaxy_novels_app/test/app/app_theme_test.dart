import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/app/app_theme_controller.dart';
import 'package:galaxy_novels_app/app/app_theme.dart';

void main() {
  test('app theme choices map to the expected material theme mode', () {
    expect(AppThemeChoice.system.themeMode, ThemeMode.system);
    expect(AppThemeChoice.galaxyNoir.themeMode, ThemeMode.dark);
    expect(AppThemeChoice.starlightPaper.themeMode, ThemeMode.light);
    expect(AppThemeChoice.deepSpace.themeMode, ThemeMode.dark);
    expect(AppThemeChoice.crimsonPagoda.themeMode, ThemeMode.dark);
    expect(AppThemeChoice.desertAstronaut.themeMode, ThemeMode.light);
    expect(AppThemeChoice.blueberryNebula.themeMode, ThemeMode.dark);
  });

  test('Galaxy Noir exposes Velvet Cosmos dark theme tokens', () {
    final theme = AppTheme.dark();
    final tokens = theme.extension<AppThemeTokens>();

    expect(tokens, isNotNull);
    expect(tokens!.preset, AppThemePreset.galaxyNoir);
    expect(tokens.background, const Color(0xFF0B0911));
    expect(tokens.primary, const Color(0xFFDCCBFF));
    expect(tokens.accent, const Color(0xFF55D6E8));
    expect(tokens.gold, const Color(0xFFF2C66D));
  });

  test(
    'Starlight Paper light theme is prepared for future theme switching',
    () {
      final theme = AppTheme.light();
      final tokens = theme.extension<AppThemeTokens>();

      expect(tokens, isNotNull);
      expect(tokens!.preset, AppThemePreset.starlightPaper);
      expect(tokens.background, const Color(0xFFF8F6FC));
      expect(tokens.primary, const Color(0xFF5C3EA5));
      expect(tokens.accent, const Color(0xFF087C8E));
    },
  );

  test('Deep Space matches the captured website dark palette', () {
    final theme = AppTheme.deepSpaceTheme();
    final tokens = theme.extension<AppThemeTokens>();

    expect(tokens, isNotNull);
    expect(tokens!.preset, AppThemePreset.deepSpace);
    expect(tokens.background, const Color(0xFF000000));
    expect(tokens.surface, const Color(0xFF040911));
    expect(tokens.surfaceRaised, const Color(0xFF0F1218));
    expect(tokens.surfaceSoft, const Color(0xFF1E283A));
    expect(tokens.primary, const Color(0xFF60A8F8));
    expect(tokens.textPrimary, const Color(0xFFFFFFFF));
  });

  test('Crimson Pagoda keeps red as an accent, not a full-screen surface', () {
    final theme = AppTheme.crimsonPagodaTheme();
    final tokens = theme.extension<AppThemeTokens>();

    expect(tokens, isNotNull);
    expect(tokens!.preset, AppThemePreset.crimsonPagoda);
    expect(tokens.background, const Color(0xFF070709));
    expect(tokens.surface, const Color(0xFF120B0D));
    expect(tokens.surfaceRaised, const Color(0xFF211416));
    expect(tokens.surfaceSoft, const Color(0xFF4B2D2E));
    expect(tokens.primary, const Color(0xFFAE1918));
    expect(tokens.accent, const Color(0xFFF42C1D));
  });

  test(
    'Desert Astronaut uses sand as identity without flattening surfaces',
    () {
      final theme = AppTheme.desertAstronautTheme();
      final tokens = theme.extension<AppThemeTokens>();

      expect(theme.brightness, Brightness.light);
      expect(tokens, isNotNull);
      expect(tokens!.preset, AppThemePreset.desertAstronaut);
      expect(tokens.background, const Color(0xFFE9E5DE));
      expect(tokens.surface, const Color(0xFFF4EFE7));
      expect(tokens.surfaceRaised, const Color(0xFFE1D6CA));
      expect(tokens.surfaceSoft, const Color(0xFFB9987C));
      expect(tokens.primary, const Color(0xFF805539));
      expect(tokens.accent, const Color(0xFF3C2C1E));
    },
  );

  test(
    'Blueberry Nebula keeps blue surfaces calm enough for long browsing',
    () {
      final theme = AppTheme.blueberryNebulaTheme();
      final tokens = theme.extension<AppThemeTokens>();

      expect(tokens, isNotNull);
      expect(tokens!.preset, AppThemePreset.blueberryNebula);
      expect(tokens.background, const Color(0xFF111523));
      expect(tokens.surface, const Color(0xFF101A2E));
      expect(tokens.surfaceRaised, const Color(0xFF14233C));
      expect(tokens.surfaceSoft, const Color(0xFF15326D));
      expect(tokens.primary, const Color(0xFF5C9FD9));
      expect(tokens.accent, const Color(0xFF255DAC));
    },
  );

  test('theme foreground pairs keep readable contrast', () {
    final themes = [
      AppTheme.dark(),
      AppTheme.light(),
      AppTheme.deepSpaceTheme(),
      AppTheme.crimsonPagodaTheme(),
      AppTheme.desertAstronautTheme(),
      AppTheme.blueberryNebulaTheme(),
    ];

    for (final theme in themes) {
      final tokens = theme.extension<AppThemeTokens>()!;
      expect(
        _contrastRatio(tokens.textPrimary, tokens.background),
        greaterThanOrEqualTo(4.5),
        reason: '${tokens.preset.name} primary text on background',
      );
      expect(
        _contrastRatio(tokens.textPrimary, tokens.surface),
        greaterThanOrEqualTo(4.5),
        reason: '${tokens.preset.name} primary text on surface',
      );
      expect(
        _contrastRatio(tokens.textSecondary, tokens.background),
        greaterThanOrEqualTo(3),
        reason: '${tokens.preset.name} secondary text on background',
      );
    }
  });

  test('system bar icons follow theme brightness for readable chrome', () {
    final lightTheme = AppTheme.desertAstronautTheme();
    final lightTokens = lightTheme.extension<AppThemeTokens>()!;
    final lightOverlay = AppTheme.systemOverlayStyleFor(lightTheme);

    expect(lightOverlay.statusBarColor, lightTokens.background);
    expect(lightOverlay.statusBarIconBrightness, Brightness.dark);
    expect(lightOverlay.systemNavigationBarIconBrightness, Brightness.dark);

    final darkTheme = AppTheme.crimsonPagodaTheme();
    final darkTokens = darkTheme.extension<AppThemeTokens>()!;
    final darkOverlay = AppTheme.systemOverlayStyleFor(darkTheme);

    expect(darkOverlay.statusBarColor, darkTokens.background);
    expect(darkOverlay.statusBarIconBrightness, Brightness.light);
    expect(darkOverlay.systemNavigationBarIconBrightness, Brightness.light);
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
