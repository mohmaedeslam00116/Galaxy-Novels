String normalizeArabicSearch(String value) {
  return value
      .toLowerCase()
      .replaceAll(RegExp('[أإآٱ]'), 'ا')
      .replaceAll(RegExp('[ىئ]'), 'ي')
      .replaceAll('ؤ', 'و')
      .replaceAll('ة', 'ه')
      .replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '')
      .replaceAll('ـ', '')
      .replaceAll(RegExp(r'[^0-9A-Za-z\u0621-\u064A\u0660-\u0669]+'), ' ')
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ');
}
