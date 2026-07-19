import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/app/app_theme.dart';
import 'package:galaxy_novels_app/features/novel_details/presentation/novel_details_visual_tokens.dart';

void main() {
  test('dark novel details tokens match the approved Stitch palette', () {
    final tokens = NovelDetailsVisualTokens.resolve(
      brightness: Brightness.dark,
      appTokens: AppTheme.galaxyNoir,
    );

    expect(tokens.background, const Color(0xFF131313));
    expect(tokens.surface, const Color(0xFF201F1F));
    expect(tokens.surfaceHigh, const Color(0xFF2A2A2A));
    expect(tokens.primary, const Color(0xFF9D4EDD));
    expect(tokens.onPrimary, const Color(0xFFFFFDFF));
    expect(tokens.textPrimary, const Color(0xFFECE9E8));
    expect(tokens.textSecondary, const Color(0xFFD9CEDC));
    expect(tokens.border, const Color(0xFF4D4353));
  });

  test('light novel details tokens retain app surfaces and purple action', () {
    final tokens = NovelDetailsVisualTokens.resolve(
      brightness: Brightness.light,
      appTokens: AppTheme.starlightPaper,
    );

    expect(tokens.background, AppTheme.starlightPaper.canvas);
    expect(tokens.surface, AppTheme.starlightPaper.surface);
    expect(tokens.surfaceHigh, AppTheme.starlightPaper.surfaceRaised);
    expect(tokens.primary, const Color(0xFF7226A5));
    expect(tokens.onPrimary, Colors.white);
    expect(tokens.textPrimary, AppTheme.starlightPaper.contentPrimary);
    expect(tokens.textSecondary, AppTheme.starlightPaper.contentSecondary);
    expect(tokens.border, AppTheme.starlightPaper.outline);
  });
}
