import 'package:flutter/material.dart';

enum ReaderPaletteMode { system, light, dark }

class ReaderPreferences {
  const ReaderPreferences({
    required this.fontScale,
    required this.lineHeight,
    required this.paletteMode,
  });

  static const defaults = ReaderPreferences(
    fontScale: 1,
    lineHeight: 2.05,
    paletteMode: ReaderPaletteMode.system,
  );

  static const _fontStep = 0.1;
  static const _lineStep = 0.1;
  static const _minFontScale = 0.85;
  static const _maxFontScale = 1.35;
  static const _minLineHeight = 1.75;
  static const _maxLineHeight = 2.35;

  final double fontScale;
  final double lineHeight;
  final ReaderPaletteMode paletteMode;

  ReaderPreferences copyWith({
    double? fontScale,
    double? lineHeight,
    ReaderPaletteMode? paletteMode,
  }) {
    return ReaderPreferences(
      fontScale: fontScale ?? this.fontScale,
      lineHeight: lineHeight ?? this.lineHeight,
      paletteMode: paletteMode ?? this.paletteMode,
    );
  }

  ReaderPreferences increaseFont() {
    return copyWith(
      fontScale: _clamp(fontScale + _fontStep, _minFontScale, _maxFontScale),
    );
  }

  ReaderPreferences decreaseFont() {
    return copyWith(
      fontScale: _clamp(fontScale - _fontStep, _minFontScale, _maxFontScale),
    );
  }

  ReaderPreferences increaseLineHeight() {
    return copyWith(
      lineHeight: _clamp(
        lineHeight + _lineStep,
        _minLineHeight,
        _maxLineHeight,
      ),
    );
  }

  ReaderPreferences decreaseLineHeight() {
    return copyWith(
      lineHeight: _clamp(
        lineHeight - _lineStep,
        _minLineHeight,
        _maxLineHeight,
      ),
    );
  }

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

double _clamp(double value, double min, double max) {
  if (value < min) {
    return min;
  }
  if (value > max) {
    return max;
  }
  return double.parse(value.toStringAsFixed(2));
}
