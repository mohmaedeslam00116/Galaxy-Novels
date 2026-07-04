enum ReaderPaletteMode { system, light, dark, paper, sepia, nightBlue, amoled }

enum ReaderTextWidth { compact, comfortable, wide }

enum ReaderBrightnessMode { system, manual }

class ReaderPreferences {
  const ReaderPreferences({
    required this.fontScale,
    required this.lineHeight,
    required this.paletteMode,
    required this.textWidth,
    required this.immersiveMode,
    required this.brightnessMode,
    required this.screenBrightness,
  });

  static const defaults = ReaderPreferences(
    fontScale: 1,
    lineHeight: 2.05,
    paletteMode: ReaderPaletteMode.system,
    textWidth: ReaderTextWidth.comfortable,
    immersiveMode: false,
    brightnessMode: ReaderBrightnessMode.system,
    screenBrightness: 0.65,
  );

  static const _fontStep = 0.1;
  static const _lineStep = 0.1;
  static const _minFontScale = 0.85;
  static const _maxFontScale = 1.35;
  static const _minLineHeight = 1.75;
  static const _maxLineHeight = 2.35;
  static const _minScreenBrightness = 0.2;
  static const _maxScreenBrightness = 1.0;

  final double fontScale;
  final double lineHeight;
  final ReaderPaletteMode paletteMode;
  final ReaderTextWidth textWidth;
  final bool immersiveMode;
  final ReaderBrightnessMode brightnessMode;
  final double screenBrightness;

  factory ReaderPreferences.fromJson(Map<String, dynamic> json) {
    final paletteName = json['palette_mode']?.toString();
    final paletteMode = ReaderPaletteMode.values.firstWhere(
      (mode) => mode.name == paletteName,
      orElse: () => ReaderPaletteMode.system,
    );
    final textWidthName = json['text_width']?.toString();
    final textWidth = ReaderTextWidth.values.firstWhere(
      (width) => width.name == textWidthName,
      orElse: () => ReaderTextWidth.comfortable,
    );
    final brightnessModeName = json['brightness_mode']?.toString();
    final brightnessMode = ReaderBrightnessMode.values.firstWhere(
      (mode) => mode.name == brightnessModeName,
      orElse: () => ReaderBrightnessMode.system,
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
      textWidth: textWidth,
      immersiveMode: json['immersive_mode'] == true,
      brightnessMode: brightnessMode,
      screenBrightness: _clamp(
        _asDouble(json['screen_brightness']) ?? defaults.screenBrightness,
        _minScreenBrightness,
        _maxScreenBrightness,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'font_scale': fontScale,
      'line_height': lineHeight,
      'palette_mode': paletteMode.name,
      'text_width': textWidth.name,
      'immersive_mode': immersiveMode,
      'brightness_mode': brightnessMode.name,
      'screen_brightness': screenBrightness,
    };
  }

  ReaderPreferences copyWith({
    double? fontScale,
    double? lineHeight,
    ReaderPaletteMode? paletteMode,
    ReaderTextWidth? textWidth,
    bool? immersiveMode,
    ReaderBrightnessMode? brightnessMode,
    double? screenBrightness,
  }) {
    return ReaderPreferences(
      fontScale: fontScale ?? this.fontScale,
      lineHeight: lineHeight ?? this.lineHeight,
      paletteMode: paletteMode ?? this.paletteMode,
      textWidth: textWidth ?? this.textWidth,
      immersiveMode: immersiveMode ?? this.immersiveMode,
      brightnessMode: brightnessMode ?? this.brightnessMode,
      screenBrightness: screenBrightness == null
          ? this.screenBrightness
          : _clamp(
              screenBrightness,
              _minScreenBrightness,
              _maxScreenBrightness,
            ),
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
        other.paletteMode == paletteMode &&
        other.textWidth == textWidth &&
        other.immersiveMode == immersiveMode &&
        other.brightnessMode == brightnessMode &&
        other.screenBrightness == screenBrightness;
  }

  @override
  int get hashCode => Object.hash(
    fontScale,
    lineHeight,
    paletteMode,
    textWidth,
    immersiveMode,
    brightnessMode,
    screenBrightness,
  );
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
