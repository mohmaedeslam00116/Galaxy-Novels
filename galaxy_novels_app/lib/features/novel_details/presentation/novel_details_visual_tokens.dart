import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';

@immutable
class NovelDetailsVisualTokens {
  const NovelDetailsVisualTokens({
    required this.background,
    required this.surface,
    required this.surfaceHigh,
    required this.primary,
    required this.onPrimary,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
  });

  final Color background;
  final Color surface;
  final Color surfaceHigh;
  final Color primary;
  final Color onPrimary;
  final Color textPrimary;
  final Color textSecondary;
  final Color border;

  static NovelDetailsVisualTokens of(BuildContext context) {
    final appTokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;
    return resolve(
      brightness: Theme.of(context).brightness,
      appTokens: appTokens,
    );
  }

  static NovelDetailsVisualTokens resolve({
    required Brightness brightness,
    required AppThemeTokens appTokens,
  }) {
    if (brightness == Brightness.dark) {
      return const NovelDetailsVisualTokens(
        background: Color(0xFF131313),
        surface: Color(0xFF201F1F),
        surfaceHigh: Color(0xFF2A2A2A),
        primary: Color(0xFF9D4EDD),
        onPrimary: Color(0xFFFFFDFF),
        textPrimary: Color(0xFFECE9E8),
        textSecondary: Color(0xFFD9CEDC),
        border: Color(0xFF4D4353),
      );
    }

    return NovelDetailsVisualTokens(
      background: appTokens.canvas,
      surface: appTokens.surface,
      surfaceHigh: appTokens.surfaceRaised,
      primary: const Color(0xFF7226A5),
      onPrimary: Colors.white,
      textPrimary: appTokens.contentPrimary,
      textSecondary: appTokens.contentSecondary,
      border: appTokens.outline,
    );
  }
}
