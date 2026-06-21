import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/app/app_theme.dart';

void main() {
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
}
