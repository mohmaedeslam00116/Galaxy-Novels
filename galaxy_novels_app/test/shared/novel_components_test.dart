import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/app/app_theme.dart';
import 'package:galaxy_novels_app/design_system/novel/galaxy_novel_cover.dart';
import 'package:galaxy_novels_app/shared/widgets/novel_cover.dart';
import 'package:galaxy_novels_app/shared/widgets/status_badge.dart';

void main() {
  testWidgets('NovelCover compatibility adapter keeps poster dimensions', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: NovelCover.poster(title: 'رواية اختبار', imageUrl: ''),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byType(NovelCover)), const Size(112, 160));
    expect(find.byType(GalaxyNovelCover), findsOneWidget);
  });

  testWidgets('StatusBadge uses compact fixed visual language', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: StatusBadge(label: 'VIP')),
        ),
      ),
    );

    expect(find.text('VIP'), findsOneWidget);
    expect(
      tester.getSize(find.byType(StatusBadge)).height,
      greaterThanOrEqualTo(24),
    );
  });

  testWidgets('status badges use accessible semantic theme color pairs', (
    tester,
  ) async {
    for (final theme in [AppTheme.dark(), AppTheme.light()]) {
      final tokens = theme.extension<AppThemeTokens>()!;
      await tester.pumpWidget(
        MaterialApp(
          key: ValueKey(theme.brightness),
          theme: theme,
          home: const Scaffold(
            body: Column(
              children: [
                StatusBadge(label: 'مستمرة'),
                StatusBadge(label: 'مكتملة'),
                StatusBadge(label: 'متوقفة'),
              ],
            ),
          ),
        ),
      );

      _expectBadgePair(
        tester,
        'مستمرة',
        tokens.brandContainer,
        tokens.onBrandContainer,
      );
      _expectBadgePair(
        tester,
        'مكتملة',
        tokens.successContainer,
        tokens.onSuccessContainer,
      );
      _expectBadgePair(
        tester,
        'متوقفة',
        tokens.warningContainer,
        tokens.onWarningContainer,
      );
    }
  });

  testWidgets('status badges preserve Arabic and English aliases', (
    tester,
  ) async {
    final theme = AppTheme.dark();
    final tokens = theme.extension<AppThemeTokens>()!;
    const aliases = [
      'مستمر',
      'ONGOING',
      'مكتمل',
      'finished',
      'متوقف',
      'on-hold',
    ];
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: Column(
            children: [for (final alias in aliases) StatusBadge(label: alias)],
          ),
        ),
      ),
    );

    for (final alias in ['مستمر', 'ONGOING']) {
      _expectBadgePair(
        tester,
        alias,
        tokens.brandContainer,
        tokens.onBrandContainer,
      );
    }
    for (final alias in ['مكتمل', 'finished']) {
      _expectBadgePair(
        tester,
        alias,
        tokens.successContainer,
        tokens.onSuccessContainer,
      );
    }
    for (final alias in ['متوقف', 'on-hold']) {
      _expectBadgePair(
        tester,
        alias,
        tokens.warningContainer,
        tokens.onWarningContainer,
      );
    }
  });
}

void _expectBadgePair(
  WidgetTester tester,
  String label,
  Color background,
  Color foreground,
) {
  final text = find.text(label);
  final decoration = tester.widget<DecoratedBox>(
    find.ancestor(of: text, matching: find.byType(DecoratedBox)).first,
  );
  final boxDecoration = decoration.decoration as BoxDecoration;

  expect(tester.widget<Text>(text).style?.color, foreground);
  expect(boxDecoration.color, background);
  expect(_contrastRatio(foreground, background), greaterThanOrEqualTo(4.5));
}

double _contrastRatio(Color foreground, Color background) {
  final lighter = foreground.computeLuminance() > background.computeLuminance()
      ? foreground
      : background;
  final darker = identical(lighter, foreground) ? background : foreground;
  return (lighter.computeLuminance() + 0.05) /
      (darker.computeLuminance() + 0.05);
}
