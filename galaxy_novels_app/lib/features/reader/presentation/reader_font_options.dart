import 'package:flutter/material.dart';

import '../domain/reader_preferences.dart';

TextStyle readerFontTextStyle(
  TextStyle? baseStyle, {
  required ReaderFontFamily fontFamily,
}) {
  final base = baseStyle ?? const TextStyle();
  if (fontFamily != ReaderFontFamily.system) {
    return base.copyWith(fontFamily: fontFamily.fontFamily);
  }

  return TextStyle(
    inherit: false,
    color: base.color,
    backgroundColor: base.backgroundColor,
    fontSize: base.fontSize,
    fontWeight: base.fontWeight,
    fontStyle: base.fontStyle,
    letterSpacing: base.letterSpacing,
    wordSpacing: base.wordSpacing,
    textBaseline: base.textBaseline,
    height: base.height,
    leadingDistribution: base.leadingDistribution,
    locale: base.locale,
    shadows: base.shadows,
    fontFeatures: base.fontFeatures,
    fontVariations: base.fontVariations,
    decoration: base.decoration,
    decorationColor: base.decorationColor,
    decorationStyle: base.decorationStyle,
    decorationThickness: base.decorationThickness,
    overflow: base.overflow,
  );
}

extension ReaderFontFamilyUi on ReaderFontFamily {
  String get label {
    return switch (this) {
      ReaderFontFamily.system => 'خط الجهاز',
      ReaderFontFamily.amiri => 'أميري',
      ReaderFontFamily.cairo => 'كايرو',
      ReaderFontFamily.tajawal => 'تجوال',
      ReaderFontFamily.readexPro => 'ريدكس برو',
      ReaderFontFamily.ibmPlexSansArabic => 'IBM Plex',
      ReaderFontFamily.almarai => 'المراعي',
      ReaderFontFamily.arefRuqaa => 'عارف رقعة',
      ReaderFontFamily.elMessiri => 'المسيري',
      ReaderFontFamily.changa => 'شانغا',
    };
  }

  String? get fontFamily {
    return switch (this) {
      ReaderFontFamily.system => null,
      ReaderFontFamily.amiri => 'Amiri',
      ReaderFontFamily.cairo => 'Cairo',
      ReaderFontFamily.tajawal => 'Tajawal',
      ReaderFontFamily.readexPro => 'Readex Pro',
      ReaderFontFamily.ibmPlexSansArabic => 'IBM Plex Sans Arabic',
      ReaderFontFamily.almarai => 'Almarai',
      ReaderFontFamily.arefRuqaa => 'Aref Ruqaa',
      ReaderFontFamily.elMessiri => 'El Messiri',
      ReaderFontFamily.changa => 'Changa',
    };
  }

  String get preview {
    return switch (this) {
      ReaderFontFamily.arefRuqaa => 'سطور من حكاية قديمة',
      ReaderFontFamily.amiri => 'رواية عربية بنَفَس كلاسيكي',
      _ => 'رحلة قارئ بين النجوم',
    };
  }
}
