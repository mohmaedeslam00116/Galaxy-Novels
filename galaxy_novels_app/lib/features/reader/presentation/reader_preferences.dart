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
    };
  }
}
