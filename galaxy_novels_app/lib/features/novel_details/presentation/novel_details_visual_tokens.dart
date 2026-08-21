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
    required this.warning,
    required this.warningContainer,
    required this.onWarningContainer,
  });

  final Color background;
  final Color surface;
  final Color surfaceHigh;
  final Color primary;
  final Color onPrimary;
  final Color textPrimary;
  final Color textSecondary;
  final Color border;
  final Color warning;
  final Color warningContainer;
  final Color onWarningContainer;

  static NovelDetailsVisualTokens of(BuildContext context) {
    final appTokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;
    return resolve(appTokens: appTokens);
  }

  static NovelDetailsVisualTokens resolve({required AppThemeTokens appTokens}) {
    return NovelDetailsVisualTokens(
      background: appTokens.canvas,
      surface: appTokens.surface,
      surfaceHigh: appTokens.surfaceRaised,
      primary: appTokens.brand,
      onPrimary: appTokens.onBrand,
      textPrimary: appTokens.contentPrimary,
      textSecondary: appTokens.contentSecondary,
      border: appTokens.outline,
      warning: appTokens.warning,
      warningContainer: appTokens.warningContainer,
      onWarningContainer: appTokens.onWarningContainer,
    );
  }
}
