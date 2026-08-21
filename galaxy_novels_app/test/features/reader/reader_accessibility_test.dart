import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/features/reader/domain/reader_preferences.dart';
import 'package:galaxy_novels_app/features/reader/presentation/reader_reading_column.dart';
import 'package:galaxy_novels_app/features/reader/presentation/reader_settings_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await Future.wait([
      _loadFont('Tajawal', 'assets/fonts/Tajawal-Regular.ttf'),
      _loadFont('Amiri', 'assets/fonts/Amiri-Regular.ttf'),
      _loadFont('Cairo', 'assets/fonts/Cairo.ttf'),
    ]);
  });
  const viewports = [840.0, 1200.0];
  const fontFamilies = <({String label, String? family})>[
    (label: 'system', family: null),
    (label: 'Amiri', family: 'Amiri'),
    (label: 'Cairo', family: 'Cairo'),
  ];
  const targetCharacters = {
    ReaderTextWidth.compact: 65,
    ReaderTextWidth.comfortable: 70,
    ReaderTextWidth.wide: 75,
  };

  for (final viewportWidth in viewports) {
    for (final font in fontFamilies) {
      for (final textWidth in ReaderTextWidth.values) {
        testWidgets(
          '$textWidth uses its Arabic measure at $viewportWidth with ${font.label}',
          (tester) async {
            const textScaler = TextScaler.noScaling;
            final paragraphStyle = await _pumpThemedReadingColumn(
              tester,
              viewportWidth: viewportWidth,
              requestedFontFamily: font.family,
              textWidth: textWidth,
              textScaler: textScaler,
            );

            final renderedWidth = tester
                .getSize(find.byKey(const ValueKey('measured-paragraph')))
                .width;
            final painter = TextPainter(
              text: TextSpan(text: _measureParagraph, style: paragraphStyle),
              textDirection: TextDirection.rtl,
              textScaler: textScaler,
            )..layout(maxWidth: renderedWidth);
            final firstLine = painter.getLineBoundary(
              const TextPosition(offset: 0),
            );
            final target = targetCharacters[textWidth]!;

            expect(
              firstLine.end,
              closeTo(target, 2),
              reason: 'rendered text width: $renderedWidth',
            );
            expect(renderedWidth, lessThanOrEqualTo(780));
          },
        );
      }
    }
  }

  for (final font in fontFamilies) {
    testWidgets('${font.label} reading widths increase monotonically', (
      tester,
    ) async {
      final renderedWidths = <double>[];
      for (final textWidth in ReaderTextWidth.values) {
        await _pumpThemedReadingColumn(
          tester,
          viewportWidth: 1200,
          requestedFontFamily: font.family,
          textWidth: textWidth,
          textScaler: TextScaler.noScaling,
        );
        renderedWidths.add(
          tester
              .getSize(find.byKey(const ValueKey('measured-paragraph')))
              .width,
        );
      }

      expect(renderedWidths[0], lessThan(renderedWidths[1]));
      expect(renderedWidths[1], lessThan(renderedWidths[2]));
    });
  }

  test('tablet landscape presets expand against the safe viewport', () {
    const availableWidth = 1232.0;
    const paragraphStyle = TextStyle(fontSize: 16, fontFamily: 'Cairo');
    const expectedWidths = {
      ReaderTextWidth.compact: availableWidth * 0.60,
      ReaderTextWidth.comfortable: availableWidth * 0.76,
      ReaderTextWidth.wide: availableWidth * 0.92,
    };

    for (final entry in expectedWidths.entries) {
      final measuredWidth = readerMeasureWidth(
        paragraphStyle: paragraphStyle,
        textWidth: entry.key,
        textScaler: TextScaler.noScaling,
      );
      final width = readerContentWidth(
        measuredWidth: measuredWidth,
        textWidth: entry.key,
        availableWidth: availableWidth,
        tabletLandscape: true,
      );
      expect(width, closeTo(entry.value, 0.1));
    }
  });

  testWidgets('reading measure scales with the active text scaler', (
    tester,
  ) async {
    const paragraphStyle = TextStyle(fontSize: 14, fontFamily: 'Cairo');
    await _pumpReadingColumn(
      tester,
      viewportWidth: 1200,
      paragraphStyle: paragraphStyle,
      textWidth: ReaderTextWidth.compact,
      textScaler: TextScaler.noScaling,
    );
    final unscaledWidth = tester
        .getSize(find.byKey(const ValueKey('measured-paragraph')))
        .width;
    await _pumpReadingColumn(
      tester,
      viewportWidth: 1200,
      paragraphStyle: paragraphStyle,
      textWidth: ReaderTextWidth.compact,
      textScaler: TextScaler.linear(1.25),
    );
    final scaledWidth = tester
        .getSize(find.byKey(const ValueKey('measured-paragraph')))
        .width;

    expect(scaledWidth, closeTo(unscaledWidth * 1.25, 0.5));
    expect(scaledWidth, lessThan(780));
  });

  testWidgets('reading measure includes the paragraph font size', (
    tester,
  ) async {
    const paragraphStyle = TextStyle(fontSize: 14, fontFamily: 'Cairo');
    await _pumpReadingColumn(
      tester,
      viewportWidth: 1200,
      paragraphStyle: paragraphStyle,
      textWidth: ReaderTextWidth.compact,
      textScaler: TextScaler.noScaling,
    );
    final regularWidth = tester
        .getSize(find.byKey(const ValueKey('measured-paragraph')))
        .width;
    await _pumpReadingColumn(
      tester,
      viewportWidth: 1200,
      paragraphStyle: paragraphStyle.copyWith(fontSize: 16),
      textWidth: ReaderTextWidth.compact,
      textScaler: TextScaler.noScaling,
    );
    final largerFontWidth = tester
        .getSize(find.byKey(const ValueKey('measured-paragraph')))
        .width;

    expect(largerFontWidth, greaterThan(regularWidth));
  });

  testWidgets('reading measure ceiling yields to a narrower parent', (
    tester,
  ) async {
    const paragraphStyle = TextStyle(fontSize: 80);
    await _pumpReadingColumn(
      tester,
      viewportWidth: 520,
      paragraphStyle: paragraphStyle,
      textWidth: ReaderTextWidth.wide,
      textScaler: TextScaler.linear(2),
    );

    expect(
      tester.getSize(find.byKey(const ValueKey('measured-paragraph'))).width,
      lessThanOrEqualTo(520),
    );
  });

  testWidgets('reader settings remain scrollable at 320 and 200 percent', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    var preferences = ReaderPreferences.defaults;

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 720),
            textScaler: TextScaler.linear(2),
          ),
          child: Scaffold(
            body: ReaderSettingsSheet(
              preferences: preferences,
              onChanged: (nextPreferences) {
                preferences = nextPreferences;
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('reader-settings-sheet')), findsOneWidget);
    final amiriFont = find.byKey(const ValueKey('reader-font-amiri'));
    await Scrollable.ensureVisible(
      tester.element(amiriFont),
      alignment: 0.35,
      duration: Duration.zero,
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .getSize(find.byKey(const ValueKey('reader-settings-panel-scroll')))
          .height,
      greaterThan(100),
    );
    expect(amiriFont.hitTestable(), findsOneWidget);
    await tester.tap(amiriFont);
    await tester.pumpAndSettle();

    expect(preferences.fontFamily, ReaderFontFamily.amiri);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _loadFont(String family, String asset) async {
  final loader = FontLoader(family)..addFont(rootBundle.load(asset));
  await loader.load();
}

Future<TextStyle> _pumpThemedReadingColumn(
  WidgetTester tester, {
  required double viewportWidth,
  required String? requestedFontFamily,
  required ReaderTextWidth textWidth,
  required TextScaler textScaler,
}) async {
  _setTestViewport(tester, viewportWidth);
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(fontFamily: 'Tajawal'),
      home: Builder(
        builder: (context) {
          final paragraphStyle = Theme.of(context).textTheme.titleMedium!
              .copyWith(
                fontSize: 18,
                fontFamily: requestedFontFamily,
                height: 1.9,
              );
          return Directionality(
            textDirection: TextDirection.rtl,
            child: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: viewportWidth,
                child: ReaderReadingColumn(
                  paragraphStyle: paragraphStyle,
                  textWidth: textWidth,
                  textScaler: textScaler,
                  child: Text(
                    _measureParagraph,
                    key: const ValueKey('measured-paragraph'),
                    style: paragraphStyle,
                    textScaler: textScaler,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
  return tester
      .widget<Text>(find.byKey(const ValueKey('measured-paragraph')))
      .style!;
}

Future<void> _pumpReadingColumn(
  WidgetTester tester, {
  required double viewportWidth,
  required TextStyle paragraphStyle,
  required ReaderTextWidth textWidth,
  required TextScaler textScaler,
}) {
  _setTestViewport(tester, viewportWidth);
  return tester.pumpWidget(
    MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: viewportWidth,
            child: ReaderReadingColumn(
              paragraphStyle: paragraphStyle,
              textWidth: textWidth,
              textScaler: textScaler,
              child: Text(
                _measureParagraph,
                key: const ValueKey('measured-paragraph'),
                style: paragraphStyle,
                textScaler: textScaler,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

void _setTestViewport(WidgetTester tester, double viewportWidth) {
  tester.view.physicalSize = Size(viewportWidth, viewportWidth + 100);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

const _measureParagraph =
    'تعود الحكاية في هدوء الكلمات بين قارئها وتمتد النجوم إلى الليل، '
    'ثم تمر قصة في طريق جديد وتمنح الساهر معنى قريبًا من القلب، '
    'وتبقى الذكريات على ضوء القمر حتى تبدأ رحلة أخرى بين الصفحات.';
