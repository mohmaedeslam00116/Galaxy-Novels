import 'package:flutter/material.dart';

import '../domain/reader_preferences.dart';

export '../domain/reader_preferences.dart';

extension ReaderPreferencesColorScheme on ReaderPreferences {
  ColorScheme colorSchemeFor(BuildContext context) {
    final themeScheme = Theme.of(context).colorScheme;

    return switch (paletteMode) {
      ReaderPaletteMode.system => themeScheme,
      ReaderPaletteMode.light => ColorScheme.fromSeed(
        seedColor: themeScheme.primary,
        brightness: Brightness.light,
      ),
      ReaderPaletteMode.dark => ColorScheme.fromSeed(
        seedColor: themeScheme.primary,
        brightness: Brightness.dark,
      ),
      ReaderPaletteMode.paper => _readerScheme(
        seed: const Color(0xFF8A5A2B),
        brightness: Brightness.light,
        surface: const Color(0xFFF6EEDC),
        onSurface: const Color(0xFF2E2118),
        primary: const Color(0xFF8A5A2B),
        outline: const Color(0xFFD8C5A8),
      ),
      ReaderPaletteMode.sepia => _readerScheme(
        seed: const Color(0xFF7A4F25),
        brightness: Brightness.light,
        surface: const Color(0xFFE7D2B2),
        onSurface: const Color(0xFF2F1F13),
        primary: const Color(0xFF7A4F25),
        outline: const Color(0xFFC6A77E),
      ),
      ReaderPaletteMode.nightBlue => _readerScheme(
        seed: const Color(0xFF60A5FA),
        brightness: Brightness.dark,
        surface: const Color(0xFF07111F),
        onSurface: const Color(0xFFE6F0FF),
        primary: const Color(0xFF60A5FA),
        outline: const Color(0xFF1E3A5F),
      ),
      ReaderPaletteMode.amoled => _readerScheme(
        seed: const Color(0xFF7DD3FC),
        brightness: Brightness.dark,
        surface: const Color(0xFF000000),
        onSurface: const Color(0xFFEDEDED),
        primary: const Color(0xFF7DD3FC),
        outline: const Color(0xFF202020),
      ),
    };
  }
}

ColorScheme _readerScheme({
  required Color seed,
  required Brightness brightness,
  required Color surface,
  required Color onSurface,
  required Color primary,
  required Color outline,
}) {
  return ColorScheme.fromSeed(seedColor: seed, brightness: brightness).copyWith(
    primary: primary,
    surface: surface,
    onSurface: onSurface,
    surfaceContainerHighest: outline.withValues(alpha: 0.36),
    outline: outline,
    outlineVariant: outline,
  );
}
