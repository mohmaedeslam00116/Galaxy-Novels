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

  test('Crimson Pagoda exposes the red temple palette', () {
    final theme = AppTheme.crimsonPagodaTheme();
    final tokens = theme.extension<AppThemeTokens>();

    expect(tokens, isNotNull);
    expect(tokens!.preset, AppThemePreset.crimsonPagoda);
    expect(tokens.background, const Color(0xFF070709));
    expect(tokens.surface, const Color(0xFF4B2D2E));
    expect(tokens.surfaceSoft, const Color(0xFF824334));
    expect(tokens.primary, const Color(0xFFF42C1D));
    expect(tokens.accent, const Color(0xFFAE1918));
  });

  test('Desert Astronaut exposes the sand and suit palette', () {
    final theme = AppTheme.desertAstronautTheme();
    final tokens = theme.extension<AppThemeTokens>();

    expect(theme.brightness, Brightness.light);
    expect(tokens, isNotNull);
    expect(tokens!.preset, AppThemePreset.desertAstronaut);
    expect(tokens.background, const Color(0xFFDDDDD8));
    expect(tokens.surface, const Color(0xFFB9987C));
    expect(tokens.surfaceRaised, const Color(0xFFD6C6B6));
    expect(tokens.primary, const Color(0xFF805539));
    expect(tokens.accent, const Color(0xFF3C2C1E));
  });

  test('Blueberry Nebula exposes the blue palette', () {
    final theme = AppTheme.blueberryNebulaTheme();
    final tokens = theme.extension<AppThemeTokens>();

    expect(tokens, isNotNull);
    expect(tokens!.preset, AppThemePreset.blueberryNebula);
    expect(tokens.background, const Color(0xFF111523));
    expect(tokens.surface, const Color(0xFF0E1E40));
    expect(tokens.surfaceRaised, const Color(0xFF15326D));
    expect(tokens.primary, const Color(0xFF5C9FD9));
    expect(tokens.accent, const Color(0xFF255DAC));
  });
}
