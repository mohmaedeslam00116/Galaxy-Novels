import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/data/models/reader_content_data.dart';
import 'package:galaxy_novels_app/features/reader/data/chapter_html_parser.dart';
import 'package:galaxy_novels_app/features/reader/domain/reader_advanced_terminology.dart';
import 'package:galaxy_novels_app/features/reader/domain/reader_speech_models.dart';
import 'package:galaxy_novels_app/features/reader/domain/reader_term_replacement.dart';
import 'package:galaxy_novels_app/features/reader/presentation/native_reader_content.dart';
import 'package:galaxy_novels_app/features/reader/presentation/reader_preferences.dart';

void main() {
  testWidgets('active speech highlights its paragraph and word range', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(htmlParser: parseChapterHtml, speechState: _activeSpeechState),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('reader-speech-highlight-0')),
      findsOneWidget,
    );
  });

  testWidgets('manual scrolling reveals return-to-speech action', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(htmlParser: parseChapterHtml, speechState: _activeSpeechState),
    );

    _dispatchUserScroll(tester, ScrollDirection.reverse);
    await tester.pump();

    expect(
      find.byKey(const ValueKey('reader-return-to-speech')),
      findsOneWidget,
    );
  });

  testWidgets('system reader font does not inherit the application font', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(
        htmlParser: parseChapterHtml,
        theme: ThemeData(fontFamily: 'Readex Pro'),
      ),
    );
    await tester.pumpAndSettle();

    final paragraph = tester.widget<EditableText>(find.text('نص الفصل'));

    expect(paragraph.style.fontFamily, isNull);
    expect(paragraph.style.inherit, isFalse);
  });

  testWidgets('visible controls describe chapter progress in Arabic', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp(htmlParser: parseChapterHtml));

    await tester.tap(find.byKey(const ValueKey('reader-content-tap-area')));
    await tester.pumpAndSettle();

    expect(find.text('الفصل 2 من 10'), findsOneWidget);
    expect(find.text('2 / 10'), findsNothing);
  });

  testWidgets(
    'scrolling preserves controls visibility until reader content is tapped',
    (tester) async {
      await tester.pumpWidget(_testApp(htmlParser: parseChapterHtml));

      _dispatchUserScroll(tester, ScrollDirection.forward);
      await tester.pumpAndSettle();
      expect(find.byTooltip('الفصل التالي').hitTestable(), findsNothing);

      _dispatchUserScroll(tester, ScrollDirection.reverse);
      await tester.pumpAndSettle();
      expect(find.byTooltip('الفصل التالي').hitTestable(), findsNothing);

      await tester.tap(find.byKey(const ValueKey('reader-content-tap-area')));
      await tester.pumpAndSettle();
      expect(find.byTooltip('الفصل التالي').hitTestable(), findsOneWidget);

      _dispatchUserScroll(tester, ScrollDirection.forward);
      await tester.pumpAndSettle();
      expect(find.byTooltip('الفصل التالي').hitTestable(), findsOneWidget);

      _dispatchUserScroll(tester, ScrollDirection.reverse);
      await tester.pumpAndSettle();
      expect(find.byTooltip('الفصل التالي').hitTestable(), findsOneWidget);
    },
  );

  testWidgets('empty parsed chapter offers a safe retry action', (
    tester,
  ) async {
    var retryCalls = 0;
    await tester.pumpWidget(
      _testApp(htmlParser: (_) => const [], onRetry: () => retryCalls += 1),
    );

    expect(find.text('هذا الفصل فارغ الآن'), findsOneWidget);
    expect(find.text('إعادة المحاولة'), findsOneWidget);

    await tester.tap(find.text('إعادة المحاولة'));
    expect(retryCalls, 1);
  });

  testWidgets('disabled animations do not slide reader controls', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(htmlParser: parseChapterHtml, disableAnimations: true),
    );

    await tester.tap(find.byKey(const ValueKey('reader-content-tap-area')));
    await tester.pump();

    expect(tester.binding.transientCallbackCount, 0);
    expect(find.byType(AnimatedSlide), findsNothing);
  });

  testWidgets('reader respects safe padding and keyboard in landscape', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(720, 320);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      _testApp(
        htmlParser: parseChapterHtml,
        mediaQueryData: const MediaQueryData(
          size: Size(720, 320),
          padding: EdgeInsets.fromLTRB(12, 24, 16, 20),
          viewInsets: EdgeInsets.only(bottom: 60),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final listView = tester.widget<ListView>(find.byType(ListView));
    final padding = listView.padding!.resolve(TextDirection.rtl);
    expect(padding.top, greaterThanOrEqualTo(24));
    expect(padding.bottom, greaterThanOrEqualTo(80));
    expect(
      tester.getRect(find.byKey(const ValueKey('reader-background'))).width,
      720,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('tablet landscape scrolls from both side gutters', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final blocks = List<ChapterTextBlock>.generate(
      120,
      (index) => ChapterTextBlock(
        type: ChapterTextBlockType.paragraph,
        text: 'فقرة جانبية ${index + 1}',
      ),
    );
    await tester.pumpWidget(
      _testApp(
        htmlParser: (_) => blocks,
        mediaQueryData: const MediaQueryData(size: Size(1280, 800)),
      ),
    );
    await tester.pumpAndSettle();

    final scrollable = tester.state<ScrollableState>(
      find.byType(Scrollable).first,
    );
    expect(
      tester.getRect(find.byKey(const ValueKey('reader-scrollable'))).width,
      1280,
    );
    await tester.dragFrom(const Offset(24, 400), const Offset(0, -320));
    await tester.pumpAndSettle();
    expect(scrollable.position.pixels, greaterThan(0));

    scrollable.position.jumpTo(0);
    await tester.pump();
    await tester.dragFrom(const Offset(1256, 400), const Offset(0, -320));
    await tester.pumpAndSettle();
    expect(scrollable.position.pixels, greaterThan(0));
  });

  testWidgets('tablet landscape comfortable text uses the wider viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      _testApp(
        htmlParser: (_) => const [
          ChapterTextBlock(
            type: ChapterTextBlockType.paragraph,
            text: 'نص لوحي طويل لاختبار عرض منطقة القراءة المتكيفة',
          ),
        ],
        mediaQueryData: const MediaQueryData(size: Size(1280, 800)),
      ),
    );
    await tester.pumpAndSettle();

    final paragraph = find.text(
      'نص لوحي طويل لاختبار عرض منطقة القراءة المتكيفة',
    );
    expect(tester.getSize(paragraph).width, greaterThan(850));
  });

  testWidgets('tablet landscape docks controls outside the reading viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      _testApp(
        htmlParser: parseChapterHtml,
        mediaQueryData: const MediaQueryData(
          size: Size(1280, 800),
          padding: EdgeInsets.only(bottom: 24),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('reader-content-tap-area')));
    await tester.pumpAndSettle();

    final dock = find.byKey(const ValueKey('reader-docked-controls'));
    final scrollable = find.byKey(const ValueKey('reader-scrollable'));
    expect(dock, findsOneWidget);
    expect(scrollable, findsOneWidget);
    expect(
      tester.getRect(scrollable).bottom,
      lessThanOrEqualTo(tester.getRect(dock).top),
    );
  });

  testWidgets('tablet rotation preserves the current reading offset', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final blocks = List<ChapterTextBlock>.generate(
      160,
      (index) => ChapterTextBlock(
        type: ChapterTextBlockType.paragraph,
        text: 'فقرة دوران ${index + 1}',
      ),
    );
    await tester.pumpWidget(_responsiveTestApp(htmlParser: (_) => blocks));
    await tester.pumpAndSettle();

    final scrollable = tester.state<ScrollableState>(
      find.byType(Scrollable).first,
    );
    scrollable.position.jumpTo(500);
    await tester.pump();

    tester.view.physicalSize = const Size(800, 1280);
    await tester.pumpAndSettle();

    expect(scrollable.position.pixels, closeTo(500, 0.1));
  });

  testWidgets('showing the dock keeps progress stable near chapter end', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    String? openedApi;
    final blocks = List<ChapterTextBlock>.generate(
      120,
      (index) => ChapterTextBlock(
        type: ChapterTextBlockType.paragraph,
        text: 'فقرة قرب النهاية ${index + 1}',
      ),
    );
    await tester.pumpWidget(
      _testApp(
        htmlParser: (_) => blocks,
        mediaQueryData: const MediaQueryData(size: Size(1280, 800)),
        preferences: ReaderPreferences.defaults.copyWith(
          continuousReading: true,
        ),
        onOpenNextChapter: (api, _) async => openedApi = api,
      ),
    );
    await tester.pumpAndSettle();

    final scrollable = tester.state<ScrollableState>(
      find.byType(Scrollable).first,
    );
    final target = scrollable.position.maxScrollExtent - 100;
    scrollable.position.jumpTo(target);
    await tester.pump();
    await tester.tapAt(const Offset(24, 300));
    await tester.pumpAndSettle();

    expect(openedApi, isNull);
    expect(scrollable.position.pixels, closeTo(target, 0.1));
  });

  testWidgets('tablet dock fits at 200 percent text scaling', (tester) async {
    tester.view.physicalSize = const Size(1024, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      _testApp(
        htmlParser: parseChapterHtml,
        mediaQueryData: const MediaQueryData(
          size: Size(1024, 600),
          textScaler: TextScaler.linear(2),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('reader-content-tap-area')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('reader-docked-controls')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  for (final fontScale in const [1.35, 2.0]) {
    testWidgets('tablet reader fits at ${fontScale}x app font size', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1024, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(
        _testApp(
          htmlParser: (_) => const [
            ChapterTextBlock(
              type: ChapterTextBlockType.paragraph,
              text: 'نص تكبير الخط على الجهاز اللوحي',
            ),
          ],
          mediaQueryData: const MediaQueryData(size: Size(1024, 600)),
          preferences: ReaderPreferences.defaults.copyWith(
            fontScale: fontScale,
            textWidth: ReaderTextWidth.wide,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final paragraph = find.text('نص تكبير الخط على الجهاز اللوحي');
      expect(tester.getSize(paragraph).width, lessThanOrEqualTo(976));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('reader content fits 320 logical pixels at 200 percent', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      _testApp(
        htmlParser: parseChapterHtml,
        mediaQueryData: const MediaQueryData(
          size: Size(320, 720),
          textScaler: TextScaler.linear(2),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      tester
          .getRect(find.byKey(const ValueKey('reader-content-tap-area')))
          .width,
      320,
    );
  });

  testWidgets('does not parse chapter HTML again when controls toggle', (
    tester,
  ) async {
    var parseCalls = 0;
    List<ChapterTextBlock> parser(String html) {
      parseCalls += 1;
      return const [
        ChapterTextBlock(
          type: ChapterTextBlockType.paragraph,
          text: 'نص الفصل',
        ),
      ];
    }

    await tester.pumpWidget(_testApp(htmlParser: parser));

    expect(parseCalls, 1);
    await tester.tap(find.byKey(const ValueKey('reader-content-tap-area')));
    await tester.pump(const Duration(milliseconds: 200));
    expect(parseCalls, 1);
  });

  testWidgets('builds chapter blocks lazily', (tester) async {
    final blocks = List<ChapterTextBlock>.generate(
      200,
      (index) => ChapterTextBlock(
        type: ChapterTextBlockType.paragraph,
        text: 'فقرة ${index + 1}',
      ),
    );

    await tester.pumpWidget(_testApp(htmlParser: (_) => blocks));

    expect(find.text('فقرة 200'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('فقرة 200'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('فقرة 200'), findsOneWidget);
  });

  testWidgets('continuous reading opens the next chapter at the end', (
    tester,
  ) async {
    String? openedApi;
    final blocks = List<ChapterTextBlock>.generate(
      80,
      (index) => ChapterTextBlock(
        type: ChapterTextBlockType.paragraph,
        text: 'فقرة متصلة ${index + 1}',
      ),
    );
    await tester.pumpWidget(
      _testApp(
        htmlParser: (_) => blocks,
        preferences: ReaderPreferences.defaults.copyWith(
          continuousReading: true,
        ),
        onOpenNextChapter: (api, _) async => openedApi = api,
      ),
    );

    final scrollable = tester.state<ScrollableState>(
      find.byType(Scrollable).first,
    );
    scrollable.position.jumpTo(scrollable.position.maxScrollExtent);
    await tester.pump();

    expect(openedApi, '/chapters/11');
  });

  testWidgets('auto scroll advances reader content', (tester) async {
    final blocks = List<ChapterTextBlock>.generate(
      80,
      (index) => ChapterTextBlock(
        type: ChapterTextBlockType.paragraph,
        text: 'فقرة تلقائية ${index + 1}',
      ),
    );
    await tester.pumpWidget(
      _testApp(
        htmlParser: (_) => blocks,
        preferences: ReaderPreferences.defaults.copyWith(
          autoScrollEnabled: true,
          autoScrollSpeed: ReaderPreferences.maxAutoScrollSpeed,
        ),
      ),
    );
    final scrollable = tester.state<ScrollableState>(
      find.byType(Scrollable).first,
    );

    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 600));

    expect(scrollable.position.pixels, greaterThan(0));
  });

  testWidgets('one pointer scrolls without changing the font scale', (
    tester,
  ) async {
    final committedScales = <double>[];
    final blocks = List<ChapterTextBlock>.generate(
      80,
      (index) => ChapterTextBlock(
        type: ChapterTextBlockType.paragraph,
        text: 'فقرة أحادية ${index + 1}',
      ),
    );
    await tester.pumpWidget(
      _testApp(
        htmlParser: (_) => blocks,
        onFontScaleCommitted: committedScales.add,
      ),
    );
    await tester.pump();
    final scrollable = tester.state<ScrollableState>(
      find.byType(Scrollable).first,
    );
    final originalSize = _visibleParagraphFontSize(tester, 'فقرة أحادية');

    await tester.drag(
      find.byKey(const ValueKey('reader-content-tap-area')),
      const Offset(0, -180),
    );
    await tester.pumpAndSettle();

    expect(scrollable.position.pixels, greaterThan(0));
    expect(_visibleParagraphFontSize(tester, 'فقرة أحادية'), originalSize);
    expect(committedScales, isEmpty);
  });

  testWidgets('pinch pauses auto scroll until the existing resume delay', (
    tester,
  ) async {
    final blocks = List<ChapterTextBlock>.generate(
      80,
      (index) => ChapterTextBlock(
        type: ChapterTextBlockType.paragraph,
        text: 'فقرة توقف ${index + 1}',
      ),
    );
    await tester.pumpWidget(
      _testApp(
        htmlParser: (_) => blocks,
        preferences: ReaderPreferences.defaults.copyWith(
          autoScrollEnabled: true,
          autoScrollSpeed: ReaderPreferences.maxAutoScrollSpeed,
        ),
      ),
    );
    final scrollable = tester.state<ScrollableState>(
      find.byType(Scrollable).first,
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 500));
    expect(scrollable.position.pixels, greaterThan(0));

    final gestures = await _startPinch(tester);
    await _expandPinch(tester, gestures);
    final heldOffset = scrollable.position.pixels;
    await tester.pump(const Duration(milliseconds: 500));
    expect(scrollable.position.pixels, closeTo(heldOffset, 0.01));

    await gestures.first.up();
    await tester.pump(const Duration(milliseconds: 1100));
    expect(scrollable.position.pixels, closeTo(heldOffset, 0.01));

    await gestures.second.up();
    await tester.pump(const Duration(milliseconds: 899));
    expect(scrollable.position.pixels, closeTo(heldOffset, 0.01));

    await tester.pump(const Duration(milliseconds: 2));
    await tester.pump(const Duration(milliseconds: 300));
    expect(scrollable.position.pixels, greaterThan(heldOffset));
  });

  testWidgets('two pointers resize text and commit the final scale once', (
    tester,
  ) async {
    final committedScales = <double>[];
    await tester.pumpWidget(
      _testApp(
        htmlParser: parseChapterHtml,
        onFontScaleCommitted: committedScales.add,
      ),
    );
    await tester.pump();
    final originalSize = _paragraphFontSize(tester);

    final gestures = await _startPinch(tester);
    await _expandPinch(tester, gestures);

    expect(_paragraphFontSize(tester), greaterThan(originalSize));
    expect(committedScales, isEmpty);

    await gestures.first.up();
    await gestures.second.up();
    await tester.pump();

    expect(committedScales, hasLength(1));
    expect(committedScales.single, closeTo(2, 0.01));
  });

  testWidgets('disabled pinch zoom leaves the text scale unchanged', (
    tester,
  ) async {
    final committedScales = <double>[];
    await tester.pumpWidget(
      _testApp(
        htmlParser: parseChapterHtml,
        preferences: ReaderPreferences.defaults.copyWith(
          pinchZoomEnabled: false,
        ),
        onFontScaleCommitted: committedScales.add,
      ),
    );
    await tester.pump();
    final originalSize = _paragraphFontSize(tester);

    final gestures = await _startPinch(tester);
    await _expandPinch(tester, gestures);
    await gestures.first.up();
    await gestures.second.up();
    await tester.pump();

    expect(_paragraphFontSize(tester), originalSize);
    expect(committedScales, isEmpty);
  });

  testWidgets('a cancelled pinch restores text without saving', (tester) async {
    final committedScales = <double>[];
    await tester.pumpWidget(
      _testApp(
        htmlParser: parseChapterHtml,
        onFontScaleCommitted: committedScales.add,
      ),
    );
    await tester.pump();
    final originalSize = _paragraphFontSize(tester);

    final gestures = await _startPinch(tester);
    await _expandPinch(tester, gestures);
    expect(_paragraphFontSize(tester), greaterThan(originalSize));

    await gestures.first.cancel();
    await gestures.second.cancel();
    await tester.pump();

    expect(_paragraphFontSize(tester), originalSize);
    expect(committedScales, isEmpty);
  });

  testWidgets('disposing during an active pinch releases its scroll hold', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp(htmlParser: parseChapterHtml));
    final gestures = await _startPinch(tester);
    await _expandPinch(tester, gestures);

    await tester.pumpWidget(const SizedBox.shrink());
    await gestures.first.cancel();
    await gestures.second.cancel();
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('pending auto-scroll resume is safe after reader unmount', (
    tester,
  ) async {
    final blocks = List<ChapterTextBlock>.generate(
      80,
      (index) => ChapterTextBlock(
        type: ChapterTextBlockType.paragraph,
        text: 'فقرة مؤجلة ${index + 1}',
      ),
    );
    await tester.pumpWidget(
      _testApp(
        htmlParser: (_) => blocks,
        preferences: ReaderPreferences.defaults.copyWith(
          autoScrollEnabled: true,
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('reader-content-tap-area')));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);
  });

  testWidgets('applies saved terminology to the current novel', (tester) async {
    await tester.pumpWidget(
      _testApp(
        htmlParser: parseChapterHtml,
        termReplacements: const [
          ReaderTermReplacement(
            source: 'الفصل',
            replacement: 'الباب',
            scope: ReaderTermScope.currentNovel,
            novelId: 1,
          ),
        ],
      ),
    );

    expect(find.text('نص الباب'), findsOneWidget);
    expect(find.text('نص الفصل'), findsNothing);
  });

  testWidgets(
    'applies an enabled advanced pack without changing source blocks',
    (tester) async {
      const sourceBlocks = [
        ChapterTextBlock(
          type: ChapterTextBlockType.paragraph,
          text: 'ظهر إله قديم.',
        ),
        ChapterTextBlock(
          type: ChapterTextBlockType.paragraph,
          text: 'رسالة حماية',
        ),
      ];
      const pack = ReaderTerminologyPack(
        schemaVersion: 1,
        type: 'wor_reader_publish_commands',
        themeVersion: '1',
        siteUrl: '',
        guardEvery: 1,
        footerEvery: 1,
        replacements: [
          ReaderPackReplacement(source: 'إله', replacement: 'حاكم'),
        ],
        guardSentences: ['رسالة حماية'],
        exceptions: [],
        footerText: '',
      );
      await tester.pumpWidget(
        _testApp(
          htmlParser: (_) => sourceBlocks,
          advancedTerminologyState: ReaderAdvancedTerminologyState.defaults
              .copyWith(accessUnlocked: true, packEnabled: true, pack: pack),
        ),
      );

      expect(find.text('ظهر حاكم قديم.'), findsOneWidget);
      expect(find.text('رسالة حماية'), findsNothing);
      expect(sourceBlocks.last.text, 'رسالة حماية');
    },
  );

  testWidgets('highlights only replaced terms and allows disabling it', (
    tester,
  ) async {
    const replacements = [
      ReaderTermReplacement(
        source: 'الفصل',
        replacement: 'الباب',
        scope: ReaderTermScope.currentNovel,
        novelId: 1,
      ),
    ];
    await tester.pumpWidget(
      _testApp(htmlParser: parseChapterHtml, termReplacements: replacements),
    );

    expect(
      _replacementSpan(tester, 'نص الباب').style?.backgroundColor,
      isNotNull,
    );

    await tester.pumpWidget(
      _testApp(
        htmlParser: parseChapterHtml,
        termReplacements: replacements,
        preferences: ReaderPreferences.defaults.copyWith(
          highlightReplacedTerms: false,
        ),
      ),
    );

    expect(_replacementSpan(tester, 'نص الباب').style?.backgroundColor, isNull);
  });

  testWidgets('long press offers replacement for the selected reader term', (
    tester,
  ) async {
    String? selectedTerm;
    await tester.pumpWidget(
      _testApp(
        htmlParser: parseChapterHtml,
        onTermLongPressed: (term) async => selectedTerm = term,
      ),
    );

    await tester.longPress(find.text('نص الفصل'));
    await tester.pumpAndSettle();

    expect(find.text('استبدال'), findsOneWidget);
    expect(find.text('إخفاء'), findsNothing);
    await tester.tap(find.text('استبدال'));
    await tester.pumpAndSettle();

    expect(selectedTerm, isNotNull);
    expect(selectedTerm, isNotEmpty);
  });

  testWidgets('unlocked advanced tools offer removal for selected text', (
    tester,
  ) async {
    String? removedTerm;
    await tester.pumpWidget(
      _testApp(
        htmlParser: parseChapterHtml,
        onTermLongPressed: (_) async {},
        onTermRemovalRequested: (term) async => removedTerm = term,
      ),
    );

    await tester.longPress(find.text('نص الفصل'));
    await tester.pumpAndSettle();
    expect(find.text('إخفاء'), findsOneWidget);
    await tester.tap(find.text('إخفاء'));
    await tester.pumpAndSettle();

    expect(removedTerm, isNotNull);
    expect(removedTerm, isNotEmpty);
  });
}

TextSpan _replacementSpan(WidgetTester tester, String text) {
  final selectable = tester.widget<SelectableText>(
    find.byWidgetPredicate(
      (widget) =>
          widget is SelectableText && widget.textSpan?.toPlainText() == text,
    ),
  );
  return selectable.textSpan!.children!.firstWhere(
        (span) => span is TextSpan && span.text == 'الباب',
      )
      as TextSpan;
}

Widget _testApp({
  required List<ChapterTextBlock> Function(String html) htmlParser,
  VoidCallback? onRetry,
  bool disableAnimations = false,
  MediaQueryData? mediaQueryData,
  ReaderPreferences preferences = ReaderPreferences.defaults,
  void Function(String contentApi, String title)? onOpenChapter,
  Future<void> Function(String contentApi, String title)? onOpenNextChapter,
  List<ReaderTermReplacement> termReplacements = const [],
  ReaderAdvancedTerminologyState advancedTerminologyState =
      ReaderAdvancedTerminologyState.defaults,
  Future<void> Function(String source)? onTermLongPressed,
  Future<void> Function(String source)? onTermRemovalRequested,
  ValueChanged<double>? onFontScaleCommitted,
  ThemeData? theme,
  ReaderSpeechState speechState = ReaderSpeechState.idle,
}) {
  return MaterialApp(
    theme: theme,
    home: MediaQuery(
      data: (mediaQueryData ?? const MediaQueryData()).copyWith(
        disableAnimations: disableAnimations,
      ),
      child: SizedBox(
        height: mediaQueryData?.size.height ?? 360,
        child: _NativeReaderHarness(
          htmlParser: htmlParser,
          onRetry: onRetry ?? () {},
          preferences: preferences,
          onOpenChapter: onOpenChapter,
          onOpenNextChapter: onOpenNextChapter,
          termReplacements: termReplacements,
          advancedTerminologyState: advancedTerminologyState,
          onTermLongPressed: onTermLongPressed,
          onTermRemovalRequested: onTermRemovalRequested,
          onFontScaleCommitted: onFontScaleCommitted,
          speechState: speechState,
        ),
      ),
    ),
  );
}

Widget _responsiveTestApp({
  required List<ChapterTextBlock> Function(String html) htmlParser,
}) {
  return MaterialApp(
    home: Scaffold(
      body: _NativeReaderHarness(
        htmlParser: htmlParser,
        onRetry: () {},
        preferences: ReaderPreferences.defaults,
      ),
    ),
  );
}

class _NativeReaderHarness extends StatefulWidget {
  const _NativeReaderHarness({
    required this.htmlParser,
    required this.onRetry,
    required this.preferences,
    this.onOpenChapter,
    this.onOpenNextChapter,
    this.termReplacements = const [],
    this.advancedTerminologyState = ReaderAdvancedTerminologyState.defaults,
    this.onTermLongPressed,
    this.onTermRemovalRequested,
    this.onFontScaleCommitted,
    this.speechState = ReaderSpeechState.idle,
  });

  final ChapterHtmlParser htmlParser;
  final VoidCallback onRetry;
  final ReaderPreferences preferences;
  final void Function(String contentApi, String title)? onOpenChapter;
  final Future<void> Function(String contentApi, String title)?
  onOpenNextChapter;
  final List<ReaderTermReplacement> termReplacements;
  final ReaderAdvancedTerminologyState advancedTerminologyState;
  final Future<void> Function(String source)? onTermLongPressed;
  final Future<void> Function(String source)? onTermRemovalRequested;
  final ValueChanged<double>? onFontScaleCommitted;
  final ReaderSpeechState speechState;

  @override
  State<_NativeReaderHarness> createState() => _NativeReaderHarnessState();
}

class _NativeReaderHarnessState extends State<_NativeReaderHarness> {
  bool controlsVisible = false;
  bool speechFollowEnabled = true;

  @override
  Widget build(BuildContext context) {
    return NativeReaderContent(
      content: _content,
      preferences: widget.preferences,
      controlsVisible: controlsVisible,
      onRetry: widget.onRetry,
      onControlsVisibilityChanged: (visible) {
        setState(() => controlsVisible = visible);
      },
      htmlParser: widget.htmlParser,
      onOpenChapter: widget.onOpenChapter ?? (_, _) {},
      onOpenNextChapter: widget.onOpenNextChapter,
      onOpenComments: () {},
      onReadingActivity: (_) {},
      termReplacements: widget.termReplacements,
      advancedTerminologyState: widget.advancedTerminologyState,
      onTermLongPressed: widget.onTermLongPressed,
      onTermRemovalRequested: widget.onTermRemovalRequested,
      onFontScaleCommitted: widget.onFontScaleCommitted ?? (_) {},
      speechState: widget.speechState,
      speechFollowEnabled: speechFollowEnabled,
      onSpeechFollowChanged: (enabled) {
        setState(() => speechFollowEnabled = enabled);
      },
    );
  }
}

double _paragraphFontSize(WidgetTester tester) {
  return tester.widget<EditableText>(find.text('نص الفصل')).style.fontSize!;
}

double _visibleParagraphFontSize(WidgetTester tester, String prefix) {
  return tester
      .widgetList<EditableText>(find.byType(EditableText))
      .firstWhere((widget) => widget.controller.text.startsWith(prefix))
      .style
      .fontSize!;
}

Future<({TestGesture first, TestGesture second})> _startPinch(
  WidgetTester tester,
) async {
  final center = tester
      .getRect(find.byKey(const ValueKey('reader-content-tap-area')))
      .center;
  final first = await tester.startGesture(
    center + const Offset(-50, 0),
    pointer: 1,
  );
  final second = await tester.startGesture(
    center + const Offset(50, 0),
    pointer: 2,
  );
  await tester.pump();
  return (first: first, second: second);
}

Future<void> _expandPinch(
  WidgetTester tester,
  ({TestGesture first, TestGesture second}) gestures,
) async {
  final center = tester
      .getRect(find.byKey(const ValueKey('reader-content-tap-area')))
      .center;
  await gestures.first.moveTo(center + const Offset(-100, 0));
  await gestures.second.moveTo(center + const Offset(100, 0));
  await tester.pump();
}

void _dispatchUserScroll(WidgetTester tester, ScrollDirection direction) {
  final scrollable = tester.element(find.byType(Scrollable).first);
  UserScrollNotification(
    metrics: FixedScrollMetrics(
      minScrollExtent: 0,
      maxScrollExtent: 100,
      pixels: 20,
      viewportDimension: 360,
      axisDirection: AxisDirection.down,
      devicePixelRatio: 1,
    ),
    context: scrollable,
    direction: direction,
  ).dispatch(scrollable);
}

const _activeSpeechState = ReaderSpeechState(
  status: ReaderSpeechStatus.playing,
  chapter: ReaderSpeechChapter(
    chapterId: 10,
    novelId: 1,
    contentApi: '/chapters/10',
    novelTitle: 'رواية الاختبار',
    chapterTitle: 'عنوان الفصل',
    coverUrl: '',
    previousContentApi: '',
    nextContentApi: '/chapters/11',
    blocks: [
      ReaderSpeechBlock(
        sourceIndex: 0,
        kind: ReaderSpeechBlockKind.paragraph,
        text: 'نص الفصل',
      ),
    ],
    contentFingerprint: 'fingerprint',
  ),
  blockIndex: 0,
  characterStart: 0,
  characterEnd: 2,
  errorMessage: null,
);

const _content = ReaderChapterContent(
  id: 10,
  novelId: 1,
  label: 'الفصل 2',
  title: '',
  displayTitle: 'عنوان الفصل',
  position: 2,
  total: 10,
  contentHtml: '<p>نص الفصل</p>',
  navigation: ReaderChapterNavigation(
    previousApi: '',
    nextApi: '/chapters/11',
    previousId: 0,
    nextId: 11,
  ),
);
