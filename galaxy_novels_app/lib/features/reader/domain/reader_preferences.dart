enum ReaderPaletteMode { system, light, dark, paper, sepia, nightBlue, amoled }

enum ReaderFontFamily {
  system,
  amiri,
  cairo,
  tajawal,
  readexPro,
  ibmPlexSansArabic,
  almarai,
  arefRuqaa,
  elMessiri,
  changa,
}

enum ReaderTextWidth { compact, comfortable, wide }

enum ReaderBrightnessMode { system, manual }

class ReaderPreferences {
  const ReaderPreferences({
    required this.fontScale,
    required this.lineHeight,
    required this.paletteMode,
    required this.fontFamily,
    required this.textWidth,
    required this.immersiveMode,
    required this.continuousReading,
    required this.autoScrollEnabled,
    required this.autoScrollSpeed,
    required this.pinchZoomEnabled,
    required this.highlightReplacedTerms,
    required this.brightnessMode,
    required this.screenBrightness,
  });

  static const defaults = ReaderPreferences(
    fontScale: 1,
    lineHeight: 2.05,
    paletteMode: ReaderPaletteMode.system,
    fontFamily: ReaderFontFamily.system,
    textWidth: ReaderTextWidth.comfortable,
    immersiveMode: false,
    continuousReading: false,
    autoScrollEnabled: false,
    autoScrollSpeed: 32,
    pinchZoomEnabled: true,
    highlightReplacedTerms: true,
    brightnessMode: ReaderBrightnessMode.system,
    screenBrightness: 0.65,
  );

  static const _fontStep = 0.1;
  static const _lineStep = 0.1;
  static const minFontScale = 0.85;
  static const maxFontScale = 2.0;
  static const _minLineHeight = 1.75;
  static const _maxLineHeight = 2.35;
  static const _minScreenBrightness = 0.2;
  static const _maxScreenBrightness = 1.0;
  static const minAutoScrollSpeed = 16.0;
  static const maxAutoScrollSpeed = 72.0;

  final double fontScale;
  final double lineHeight;
  final ReaderPaletteMode paletteMode;
  final ReaderFontFamily fontFamily;
  final ReaderTextWidth textWidth;
  final bool immersiveMode;
  final bool continuousReading;
  final bool autoScrollEnabled;
  final double autoScrollSpeed;
  final bool pinchZoomEnabled;
  final bool highlightReplacedTerms;
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
    final fontFamilyName = json['font_family']?.toString();
    final fontFamily = ReaderFontFamily.values.firstWhere(
      (family) => family.name == fontFamilyName,
      orElse: () => ReaderFontFamily.system,
    );
    final brightnessModeName = json['brightness_mode']?.toString();
    final brightnessMode = ReaderBrightnessMode.values.firstWhere(
      (mode) => mode.name == brightnessModeName,
      orElse: () => ReaderBrightnessMode.system,
    );

    return ReaderPreferences(
      fontScale: _clamp(
        _asDouble(json['font_scale']) ?? defaults.fontScale,
        minFontScale,
        maxFontScale,
      ),
      lineHeight: _clamp(
        _asDouble(json['line_height']) ?? defaults.lineHeight,
        _minLineHeight,
        _maxLineHeight,
      ),
      paletteMode: paletteMode,
      fontFamily: fontFamily,
      textWidth: textWidth,
      immersiveMode: json['immersive_mode'] == true,
      continuousReading: json['continuous_reading'] == true,
      autoScrollEnabled: json['auto_scroll_enabled'] == true,
      autoScrollSpeed: _clamp(
        _asDouble(json['auto_scroll_speed']) ?? defaults.autoScrollSpeed,
        minAutoScrollSpeed,
        maxAutoScrollSpeed,
      ),
      pinchZoomEnabled: json['pinch_zoom_enabled'] != false,
      highlightReplacedTerms: json['highlight_replaced_terms'] != false,
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
      'font_family': fontFamily.name,
      'text_width': textWidth.name,
      'immersive_mode': immersiveMode,
      'continuous_reading': continuousReading,
      'auto_scroll_enabled': autoScrollEnabled,
      'auto_scroll_speed': autoScrollSpeed,
      'pinch_zoom_enabled': pinchZoomEnabled,
      'highlight_replaced_terms': highlightReplacedTerms,
      'brightness_mode': brightnessMode.name,
      'screen_brightness': screenBrightness,
    };
  }

  ReaderPreferences copyWith({
    double? fontScale,
    double? lineHeight,
    ReaderPaletteMode? paletteMode,
    ReaderFontFamily? fontFamily,
    ReaderTextWidth? textWidth,
    bool? immersiveMode,
    bool? continuousReading,
    bool? autoScrollEnabled,
    double? autoScrollSpeed,
    bool? pinchZoomEnabled,
    bool? highlightReplacedTerms,
    ReaderBrightnessMode? brightnessMode,
    double? screenBrightness,
  }) {
    return ReaderPreferences(
      fontScale: fontScale ?? this.fontScale,
      lineHeight: lineHeight ?? this.lineHeight,
      paletteMode: paletteMode ?? this.paletteMode,
      fontFamily: fontFamily ?? this.fontFamily,
      textWidth: textWidth ?? this.textWidth,
      immersiveMode: immersiveMode ?? this.immersiveMode,
      continuousReading: continuousReading ?? this.continuousReading,
      autoScrollEnabled: autoScrollEnabled ?? this.autoScrollEnabled,
      autoScrollSpeed: autoScrollSpeed == null
          ? this.autoScrollSpeed
          : _clamp(autoScrollSpeed, minAutoScrollSpeed, maxAutoScrollSpeed),
      pinchZoomEnabled: pinchZoomEnabled ?? this.pinchZoomEnabled,
      highlightReplacedTerms:
          highlightReplacedTerms ?? this.highlightReplacedTerms,
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
      fontScale: _clamp(fontScale + _fontStep, minFontScale, maxFontScale),
    );
  }

  ReaderPreferences decreaseFont() {
    return copyWith(
      fontScale: _clamp(fontScale - _fontStep, minFontScale, maxFontScale),
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
        other.fontFamily == fontFamily &&
        other.textWidth == textWidth &&
        other.immersiveMode == immersiveMode &&
        other.continuousReading == continuousReading &&
        other.autoScrollEnabled == autoScrollEnabled &&
        other.autoScrollSpeed == autoScrollSpeed &&
        other.pinchZoomEnabled == pinchZoomEnabled &&
        other.highlightReplacedTerms == highlightReplacedTerms &&
        other.brightnessMode == brightnessMode &&
        other.screenBrightness == screenBrightness;
  }

  @override
  int get hashCode => Object.hash(
    fontScale,
    lineHeight,
    paletteMode,
    fontFamily,
    textWidth,
    immersiveMode,
    continuousReading,
    autoScrollEnabled,
    autoScrollSpeed,
    pinchZoomEnabled,
    highlightReplacedTerms,
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
