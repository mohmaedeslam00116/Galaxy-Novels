import 'package:flutter/material.dart';

Color readerTermHighlightColor(Brightness brightness) {
  return brightness == Brightness.dark
      ? const Color(0xFF72DCE9).withValues(alpha: 0.24)
      : const Color(0xFF74D5E2).withValues(alpha: 0.38);
}
