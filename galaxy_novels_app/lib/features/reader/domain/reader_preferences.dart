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

  factory ReaderPreferences.fromJson(Map<String, dynamic> json) {
    final paletteName = json['palette_mode']?.toString();
    final paletteMode = ReaderPaletteMode.values.firstWhere(
      (mode) => mode.name == paletteName,
      orElse: () => ReaderPaletteMode.system,
    );

    return ReaderPreferences(
      fontScale: _clamp(
        _asDouble(json['font_scale']) ?? defaults.fontScale,
        _minFontScale,
        _maxFontScale,
      ),
      lineHeight: _clamp(
        _asDouble(json['line_height']) ?? defaults.lineHeight,
        _minLineHeight,
        _maxLineHeight,
      ),
      paletteMode: paletteMode,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'font_scale': fontScale,
      'line_height': lineHeight,
      'palette_mode': paletteMode.name,
    };
  }

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

  @override
  bool operator ==(Object other) {
    return other is ReaderPreferences &&
        other.fontScale == fontScale &&
        other.lineHeight == lineHeight &&
        other.paletteMode == paletteMode;
  }

  @override
  int get hashCode => Object.hash(fontScale, lineHeight, paletteMode);
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

double? _asDouble(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString() ?? '');
}
