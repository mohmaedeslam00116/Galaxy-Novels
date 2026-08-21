import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/features/reader/presentation/reader_chrome_palette.dart';

void main() {
  test('reader chrome always follows the active app color scheme', () {
    const scheme = ColorScheme.dark(
      surface: Color(0xFF141E2B),
      onSurface: Color(0xFFE8EDF4),
      primary: Color(0xFF8EA9D1),
      onPrimary: Color(0xFF101820),
      outlineVariant: Color(0xFF34475D),
    );
    final palette = resolveReaderChromePalette(scheme: scheme);

    expect(palette.background, scheme.surface);
    expect(palette.foreground, scheme.onSurface);
    expect(palette.border, scheme.outlineVariant);
    expect(palette.primary, scheme.primary);
    expect(palette.primaryForeground, scheme.onPrimary);
  });

  test('custom reader palettes keep their semantic colors', () {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: const Color(0xFF60A5FA),
          brightness: Brightness.dark,
        ).copyWith(
          surface: const Color(0xFF07111F),
          onSurface: const Color(0xFFE6F0FF),
          primary: const Color(0xFF60A5FA),
          outlineVariant: const Color(0xFF1E3A5F),
        );

    final palette = resolveReaderChromePalette(scheme: scheme);

    expect(palette.background, scheme.surface);
    expect(palette.foreground, scheme.onSurface);
    expect(palette.border, scheme.outlineVariant);
    expect(palette.primary, scheme.primary);
    expect(palette.primaryForeground, scheme.onPrimary);
  });
}
