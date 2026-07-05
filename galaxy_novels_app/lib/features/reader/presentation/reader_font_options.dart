import '../domain/reader_preferences.dart';

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
