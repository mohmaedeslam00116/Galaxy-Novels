import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/app/app_theme.dart';
import 'package:galaxy_novels_app/features/novel_details/presentation/novel_details_visual_tokens.dart';

void main() {
  for (final appTokens in const [
    AppTheme.galaxyNoir,
    AppTheme.neutralDark,
    AppTheme.cosmicNight,
    AppTheme.starlightPaper,
    AppTheme.lightNature,
  ]) {
    test('novel details inherit the ${appTokens.preset.name} theme', () {
      final tokens = NovelDetailsVisualTokens.resolve(appTokens: appTokens);

      expect(tokens.background, appTokens.canvas);
      expect(tokens.surface, appTokens.surface);
      expect(tokens.surfaceHigh, appTokens.surfaceRaised);
      expect(tokens.primary, appTokens.brand);
      expect(tokens.onPrimary, appTokens.onBrand);
      expect(tokens.textPrimary, appTokens.contentPrimary);
      expect(tokens.textSecondary, appTokens.contentSecondary);
      expect(tokens.border, appTokens.outline);
      expect(tokens.warning, appTokens.warning);
      expect(tokens.warningContainer, appTokens.warningContainer);
      expect(tokens.onWarningContainer, appTokens.onWarningContainer);
    });
  }
}
