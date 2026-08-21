import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/app/app_theme.dart';
import 'package:galaxy_novels_app/features/reader/domain/reader_preferences.dart';
import 'package:galaxy_novels_app/features/reader/domain/reader_term_replacement.dart';
import 'package:galaxy_novels_app/features/reader/presentation/reader_settings_sheet.dart';

void main() {
  testWidgets(
    'reader sheet keeps navigation and reset outside panel scrolling',
    (tester) async {
      await _pumpSheet(tester, const Size(320, 720));

      expect(
        find.byKey(const ValueKey('reader-settings-shell')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('reader-settings-header')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('reader-settings-tabs')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('reader-settings-panel-scroll')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('reader-settings-reset')),
        findsOneWidget,
      );
    },
  );

  testWidgets('text tab groups typography controls without changing behavior', (
    tester,
  ) async {
    final harness = await _pumpSheet(tester, const Size(320, 720));

    expect(find.byKey(const ValueKey('reader-font-grid')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('reader-text-stepper-table')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('reader-text-width-selector')),
      findsOneWidget,
    );

    final increase = find.byKey(const ValueKey('reader-font-increase'));
    await tester.ensureVisible(increase);
    await tester.pumpAndSettle();
    await tester.tap(increase);
    await tester.pump();

    expect(harness.preferences.fontScale, 1.1);
  });

  testWidgets('color and screen tabs use compact grouped surfaces', (
    tester,
  ) async {
    await _pumpSheet(tester, const Size(320, 720));

    await tester.tap(find.byKey(const ValueKey('reader-settings-tab-colors')));
    await tester.pump();
    expect(find.byKey(const ValueKey('reader-palette-grid')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('reader-settings-tab-screen')));
    await tester.pump();
    expect(
      find.byKey(const ValueKey('reader-screen-settings-surface')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('reader-brightness-mode-selector')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('reader-continuous-reading-toggle')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('reader-auto-scroll-toggle')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('reader-pinch-zoom-toggle')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('reader-settings-tab-terms')));
    await tester.pump();
    expect(
      find.byKey(const ValueKey('reader-terms-settings-panel')),
      findsOneWidget,
    );
  });

  testWidgets('screen tab saves reading flow and pinch zoom settings', (
    tester,
  ) async {
    final harness = await _pumpSheet(tester, const Size(320, 720));

    await tester.tap(find.byKey(const ValueKey('reader-settings-tab-screen')));
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('reader-continuous-reading-toggle')),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('reader-auto-scroll-toggle')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('reader-pinch-zoom-toggle')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('reader-pinch-zoom-toggle')));
    await tester.pump();

    expect(harness.preferences.continuousReading, isTrue);
    expect(harness.preferences.autoScrollEnabled, isTrue);
    expect(harness.preferences.pinchZoomEnabled, isFalse);
    expect(
      find.byKey(const ValueKey('reader-auto-scroll-speed')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('reader-settings-reset')));
    await tester.pumpAndSettle();

    expect(harness.preferences.pinchZoomEnabled, isTrue);
  });

  testWidgets('system font previews do not inherit the app font family', (
    tester,
  ) async {
    await _pumpSheet(tester, const Size(320, 720));

    final mainPreview = tester.widget<Text>(
      find.descendant(
        of: find.byKey(const ValueKey('reader-font-preview')),
        matching: find.byType(Text),
      ),
    );
    final systemTileTexts = tester.widgetList<Text>(
      find.descendant(
        of: find.byKey(const ValueKey('reader-font-system')),
        matching: find.byType(Text),
      ),
    );

    expect(mainPreview.style?.fontFamily, isNull);
    expect(mainPreview.style?.inherit, isFalse);
    expect(systemTileTexts.last.style?.fontFamily, isNull);
    expect(systemTileTexts.last.style?.inherit, isFalse);
  });

  testWidgets('tablet landscape uses a wide panel with side navigation', (
    tester,
  ) async {
    await _pumpSheet(tester, const Size(1280, 800), textScale: 2);

    final shell = find.byKey(const ValueKey('reader-settings-shell'));
    expect(tester.getSize(shell).width, lessThanOrEqualTo(1080));
    expect(
      find.byKey(const ValueKey('reader-settings-side-tabs')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('reader-settings-panel-scroll')),
      findsOneWidget,
    );
    expect(find.byType(Scrollbar), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('reader-settings-tab-screen')));
    await tester.pumpAndSettle();
    final autoScroll = find.byKey(const ValueKey('reader-auto-scroll-toggle'));
    await Scrollable.ensureVisible(
      tester.element(autoScroll),
      duration: Duration.zero,
    );
    await tester.pump();
    expect(autoScroll.hitTestable(), findsOneWidget);
    expect(
      find.byKey(const ValueKey('reader-settings-reset')).hitTestable(),
      findsOneWidget,
    );
  });

  testWidgets('phone landscape keeps every text option reachable', (
    tester,
  ) async {
    await _pumpSheet(tester, const Size(720, 360), textScale: 2);

    expect(
      find.byKey(const ValueKey('reader-settings-side-tabs')),
      findsNothing,
    );
    final widthSelector = find.byKey(
      const ValueKey('reader-text-width-selector'),
    );
    await Scrollable.ensureVisible(
      tester.element(widthSelector),
      duration: Duration.zero,
    );
    await tester.pump();
    expect(widthSelector.hitTestable(), findsOneWidget);
  });

  for (final viewport in const [
    _Viewport(Size(320, 720), 1),
    _Viewport(Size(600, 800), 1),
    _Viewport(Size(840, 900), 1),
    _Viewport(Size(840, 360), 1),
    _Viewport(Size(320, 1100), 2),
  ]) {
    testWidgets(
      'sheet adapts at ${viewport.size} and ${viewport.textScale}x text',
      (tester) async {
        await _pumpSheet(tester, viewport.size, textScale: viewport.textScale);

        for (final tab in const [
          'reader-settings-tab-text',
          'reader-settings-tab-colors',
          'reader-settings-tab-screen',
          'reader-settings-tab-terms',
        ]) {
          final tabFinder = find.byKey(ValueKey(tab));
          await Scrollable.ensureVisible(
            tester.element(tabFinder),
            alignment: 0.5,
            duration: Duration.zero,
          );
          await tester.pump();
          await tester.tap(tabFinder);
          await tester.pump();
          expect(tester.takeException(), isNull);
        }
      },
    );
  }

  testWidgets('sheet tabs and actions expose accessible targets', (
    tester,
  ) async {
    await _pumpSheet(tester, const Size(320, 720));

    final textTab = find.byKey(const ValueKey('reader-settings-tab-text'));
    final colorsTab = find.byKey(const ValueKey('reader-settings-tab-colors'));
    expect(
      tester.getSemantics(textTab).flagsCollection.isSelected,
      Tristate.isTrue,
    );
    expect(
      tester.getSemantics(colorsTab).flagsCollection.isSelected,
      Tristate.isFalse,
    );

    for (final action in [
      find.byKey(const ValueKey('reader-settings-close')),
      find.byKey(const ValueKey('reader-settings-reset')),
    ]) {
      final size = tester.getSize(action);
      expect(size.width, greaterThanOrEqualTo(44));
      expect(size.height, greaterThanOrEqualTo(44));
    }
  });

  testWidgets('terms tab lists rules for the active novel', (tester) async {
    await _pumpSheet(
      tester,
      const Size(320, 720),
      novelId: 4,
      termReplacements: const [
        ReaderTermReplacement(
          source: 'الساحر',
          replacement: 'العارف',
          scope: ReaderTermScope.currentNovel,
          novelId: 4,
        ),
        ReaderTermReplacement(
          source: 'المانا',
          replacement: 'الطاقة',
          scope: ReaderTermScope.allNovels,
          novelId: 0,
        ),
      ],
    );

    await tester.tap(find.byKey(const ValueKey('reader-settings-tab-terms')));
    await tester.pump();

    expect(find.text('الساحر ← العارف'), findsOneWidget);
    expect(find.text('المانا ← الطاقة'), findsOneWidget);
  });

  testWidgets('terms tab can disable replacement highlighting', (tester) async {
    final harness = await _pumpSheet(tester, const Size(320, 720));

    await tester.tap(find.byKey(const ValueKey('reader-settings-tab-terms')));
    await tester.pump();
    final toggle = find.byKey(const ValueKey('reader-term-highlight-toggle'));
    expect(toggle, findsOneWidget);
    expect(harness.preferences.highlightReplacedTerms, isTrue);

    await tester.tap(toggle);
    await tester.pump();

    expect(harness.preferences.highlightReplacedTerms, isFalse);
  });

  testWidgets('compact grouping stays scoped to the in-reader sheet', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: SingleChildScrollView(
              child: ReaderSettingsControls(
                preferences: ReaderPreferences.defaults,
                showHeading: false,
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('reader-text-stepper-table')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('reader-text-width-selector')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('reader-font-increase')), findsOneWidget);
  });
}

Future<_SheetHarness> _pumpSheet(
  WidgetTester tester,
  Size size, {
  double textScale = 1,
  ReaderPreferences preferences = ReaderPreferences.defaults,
  List<ReaderTermReplacement> termReplacements = const [],
  int novelId = 0,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final harness = _SheetHarness(preferences);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark(),
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
        ),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: ReaderSettingsSheet(
              preferences: preferences,
              termReplacements: termReplacements,
              novelId: novelId,
              onChanged: (next) => harness.preferences = next,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return harness;
}

class _SheetHarness {
  _SheetHarness(this.preferences);

  ReaderPreferences preferences;
}

class _Viewport {
  const _Viewport(this.size, this.textScale);

  final Size size;
  final double textScale;
}
