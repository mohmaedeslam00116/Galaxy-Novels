import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/app/app_dependencies.dart';
import 'package:galaxy_novels_app/core/config/app_config.dart';
import 'package:galaxy_novels_app/core/platform/app_system_settings.dart';
import 'package:galaxy_novels_app/data/models/reader_content_data.dart';
import 'package:galaxy_novels_app/data/models/reading_progress.dart';
import 'package:galaxy_novels_app/data/repositories/fake_catalog_repository.dart';
import 'package:galaxy_novels_app/data/repositories/fake_home_repository.dart';
import 'package:galaxy_novels_app/data/repositories/fake_novel_repository.dart';
import 'package:galaxy_novels_app/data/repositories/fake_rankings_repository.dart';
import 'package:galaxy_novels_app/data/repositories/fake_search_repository.dart';
import 'package:galaxy_novels_app/data/repositories/reader_repository.dart';
import 'package:galaxy_novels_app/data/repositories/reading_history_repository.dart';
import 'package:galaxy_novels_app/features/comments/application/comments_repository.dart';
import 'package:galaxy_novels_app/features/comments/domain/comment_target.dart';
import 'package:galaxy_novels_app/features/comments/domain/comments_page.dart';
import 'package:galaxy_novels_app/features/comments/domain/public_comment.dart';
import 'package:galaxy_novels_app/features/account/presentation/account_screen.dart';
import 'package:galaxy_novels_app/features/downloads/application/download_repository.dart';
import 'package:galaxy_novels_app/features/ads/application/full_screen_ad_repository.dart';
import 'package:galaxy_novels_app/features/reading_activity/application/reading_activity_recorder.dart';
import 'package:galaxy_novels_app/features/reader/domain/reader_preferences.dart';
import 'package:galaxy_novels_app/features/reader/application/reader_speech_controller.dart';
import 'package:galaxy_novels_app/features/reader/application/reader_term_replacement_repository.dart';
import 'package:galaxy_novels_app/features/reader/domain/reader_speech_models.dart';
import 'package:galaxy_novels_app/features/reader/domain/reader_term_replacement.dart';
import 'package:galaxy_novels_app/features/reader/presentation/reader_screen.dart';

import '../../helpers/fake_reader_preferences_repository.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_comments_repository.dart';
import '../../helpers/fake_favorites_repository.dart';
import '../../helpers/fake_novel_engagement_repository.dart';
import '../../helpers/fake_vip_repository.dart';

void main() {
  testWidgets(
    'speaker prepares the visible chapter and opens speech controls',
    (tester) async {
      final speechController = _TestSpeechController();
      await tester.pumpWidget(
        _ReaderTestApp(
          readerSpeechController: speechController,
          child: const ReaderScreen(
            contentApi: '/chapters/10',
            novelTitle: 'رواية الاختبار',
            systemSettings: _AllowedSystemSettings(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('reader-content-tap-area')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('reader-speech-button')));
      await tester.pumpAndSettle();

      expect(speechController.preparedChapter?.chapterId, 10);
      expect(
        speechController.preparedChapter?.blocks.single.text,
        'نص الفصل الأول',
      );
      expect(find.text('القراءة الصوتية'), findsOneWidget);
    },
  );

  testWidgets('shows a specific lock message for an offline VIP chapter', (
    tester,
  ) async {
    await tester.pumpWidget(
      _ReaderTestApp(
        readerRepository: const _VipLockedReaderRepository(),
        child: const ReaderScreen(
          contentApi: 'galaxy-download://chapter/vip%3A71',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('فصل VIP مقفل'), findsOneWidget);
    expect(find.textContaining('حدّث حسابك'), findsOneWidget);
    expect(find.text('فتح حسابي'), findsOneWidget);
  });

  testWidgets(
    'loaded reader chrome starts hidden and tap reveals both surfaces',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        const _ReaderTestApp(child: ReaderScreen(contentApi: '/chapters/10')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppBar).hitTestable(), findsNothing);
      expect(find.byTooltip('الفصل التالي').hitTestable(), findsNothing);
      expect(find.bySemanticsLabel('إعدادات القراءة'), findsNothing);
      expect(find.bySemanticsLabel('الفصل التالي'), findsNothing);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('reader-app-bar')),
          matching: find.bySemanticsLabel('عنوان الفصل'),
        ),
        findsNothing,
      );
      expect(
        tester
            .widget<ExcludeSemantics>(
              find.byKey(const ValueKey('reader-controls-exclude-semantics')),
            )
            .excluding,
        isTrue,
      );
      expect(
        tester
            .widget<IgnorePointer>(
              find.byKey(const ValueKey('reader-app-bar-ignore-pointer')),
            )
            .ignoring,
        isTrue,
      );

      await tester.tap(find.byKey(const ValueKey('reader-content-tap-area')));
      await tester.pumpAndSettle();

      expect(find.byType(AppBar).hitTestable(), findsOneWidget);
      expect(find.byTooltip('الفصل التالي').hitTestable(), findsOneWidget);
      final appBar = find.byKey(const ValueKey('reader-app-bar'));
      expect(
        find.descendant(
          of: appBar,
          matching: find.byKey(const ValueKey('reader-settings-button')),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('reader-docked-controls')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('reader-progress-indicator')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('reader-chapters-button')),
        findsNothing,
      );
      final settingsSemantics = find.bySemanticsLabel('إعدادات القراءة');
      final nextSemantics = find.bySemanticsLabel('الفصل التالي');
      expect(settingsSemantics, findsOneWidget);
      expect(nextSemantics, findsOneWidget);
      expect(
        tester
            .getSemantics(settingsSemantics)
            .getSemanticsData()
            .hasAction(ui.SemanticsAction.tap),
        isTrue,
      );
      expect(
        tester
            .getSemantics(nextSemantics)
            .getSemanticsData()
            .hasAction(ui.SemanticsAction.tap),
        isTrue,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('reader-app-bar')),
          matching: find.bySemanticsLabel('عنوان الفصل'),
        ),
        findsOneWidget,
      );
      expect(
        tester
            .widget<ExcludeSemantics>(
              find.byKey(const ValueKey('reader-controls-exclude-semantics')),
            )
            .excluding,
        isFalse,
      );
      expect(
        tester
            .widget<IgnorePointer>(
              find.byKey(const ValueKey('reader-app-bar-ignore-pointer')),
            )
            .ignoring,
        isFalse,
      );
      semantics.dispose();
    },
  );

  testWidgets('chapter transition resets app bar and controls to hidden', (
    tester,
  ) async {
    await tester.pumpWidget(
      const _ReaderTestApp(child: ReaderScreen(contentApi: '/chapters/10')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('reader-content-tap-area')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('الفصل التالي'));
    await tester.pumpAndSettle();

    expect(find.text('نص الفصل التالي'), findsOneWidget);
    expect(find.byType(AppBar).hitTestable(), findsNothing);
    expect(find.byTooltip('الفصل السابق').hitTestable(), findsNothing);
  });

  testWidgets(
    'next chapter waits for a due reader interstitial and opens only once',
    (tester) async {
      final ads = _BlockingFullScreenAdRepository();
      final reader = _CountingReaderRepository();
      await tester.pumpWidget(
        _ReaderTestApp(
          readerRepository: reader,
          fullScreenAdRepository: ads,
          child: const ReaderScreen(contentApi: '/chapters/10'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('reader-content-tap-area')));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('الفصل التالي'));
      await tester.pump();

      expect(ads.readerCalls, 1);
      expect(find.text('نص الفصل الأول'), findsOneWidget);
      expect(reader.requestedApis, ['/chapters/10']);

      ads.completeReaderAd(shown: true);
      await tester.pumpAndSettle();

      expect(find.text('نص الفصل التالي'), findsOneWidget);
      expect(reader.requestedApis, [
        '/chapters/10',
        '/wp-json/wor-reader-app/v1/chapters/11',
      ]);
    },
  );

  testWidgets('previous chapter transition does not consult reader ads', (
    tester,
  ) async {
    final ads = _BlockingFullScreenAdRepository();
    await tester.pumpWidget(
      _ReaderTestApp(
        readerRepository: const _PreviousChapterReaderRepository(),
        fullScreenAdRepository: ads,
        child: const ReaderScreen(contentApi: '/chapters/11'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('reader-content-tap-area')));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('الفصل السابق'));
    await tester.pumpAndSettle();

    expect(ads.readerCalls, 0);
    expect(find.text('نص الفصل الأول'), findsOneWidget);
  });

  testWidgets('disabled animations reveal both chrome surfaces immediately', (
    tester,
  ) async {
    await tester.pumpWidget(
      const _ReaderTestApp(
        disableAnimations: true,
        child: ReaderScreen(contentApi: '/chapters/10'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('reader-content-tap-area')));
    await tester.pump();

    expect(tester.binding.transientCallbackCount, 0);
    expect(find.byType(AnimatedSlide), findsNothing);
    expect(find.byType(AppBar).hitTestable(), findsOneWidget);
    expect(find.byTooltip('الفصل التالي').hitTestable(), findsOneWidget);
  });

  testWidgets('reader toolbar is the only top surface and remains ad free', (
    tester,
  ) async {
    await tester.pumpWidget(
      const _ReaderTestApp(
        mediaQueryPadding: EdgeInsets.only(top: 32),
        child: ReaderScreen(contentApi: '/chapters/10'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('إعلان القارئ'), findsNothing);
    expect(find.byKey(const ValueKey('reader-ad-close-button')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('reader-content-tap-area')));
    await tester.pumpAndSettle();

    final appBar = find.byKey(const ValueKey('reader-app-bar'));
    expect(tester.getRect(appBar).top, closeTo(32, 0.1));
    expect(appBar.hitTestable(), findsOneWidget);
    expect(
      find.descendant(
        of: appBar,
        matching: find.bySemanticsLabel('عنوان الفصل'),
      ),
      findsOneWidget,
    );
    final appBarRect = tester.getRect(appBar);
    final readerRect = tester.getRect(
      find.byKey(const ValueKey('reader-background')),
    );
    final listRect = tester.getRect(find.byType(ListView));
    expect(readerRect.top, closeTo(appBarRect.bottom, 0.1));
    expect(listRect.top, closeTo(readerRect.top, 0.1));
    final contentTitle = find.descendant(
      of: find.byType(ListView),
      matching: find.text('عنوان الفصل'),
    );
    expect(tester.getRect(contentTitle).top, closeTo(listRect.top + 18, 0.1));
  });

  testWidgets('chapter navigation opens the next chapter directly', (
    tester,
  ) async {
    await tester.pumpWidget(
      const _ReaderTestApp(child: ReaderScreen(contentApi: '/chapters/10')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('reader-content-tap-area')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('الفصل التالي'));
    await tester.pumpAndSettle();

    expect(find.text('نص الفصل التالي'), findsOneWidget);
    expect(find.text('إعلان القارئ'), findsNothing);
  });

  testWidgets('reader app bar has no banner offset when no ad exists', (
    tester,
  ) async {
    await tester.pumpWidget(
      const _ReaderTestApp(
        mediaQueryPadding: EdgeInsets.only(top: 32),
        child: ReaderScreen(contentApi: '/chapters/10'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('reader-content-tap-area')));
    await tester.pumpAndSettle();

    expect(
      tester.getRect(find.byKey(const ValueKey('reader-app-bar'))).top,
      closeTo(32, 0.1),
    );
  });

  testWidgets('loads chapter content and renders it natively', (tester) async {
    await tester.pumpWidget(
      _ReaderTestApp(
        readerRepository: const _TestReaderRepository(),
        child: const ReaderScreen(
          contentApi: '/wp-json/wor-reader-app/v1/chapters/10',
          chapterTitle: 'الفصل 1',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('عنوان الفصل'), findsWidgets);
    expect(find.text('نص الفصل الأول'), findsOneWidget);
    expect(find.byTooltip('الفصل التالي').hitTestable(), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await tester.tap(find.byKey(const ValueKey('reader-content-tap-area')));
    await tester.pumpAndSettle();

    expect(find.byTooltip('الفصل التالي'), findsOneWidget);

    await tester.tap(find.byTooltip('الفصل التالي'));
    await tester.pumpAndSettle();

    expect(find.text('عنوان الفصل التالي'), findsWidgets);
    expect(find.text('نص الفصل التالي'), findsOneWidget);
  });

  testWidgets('applies shared terminology rules to loaded chapters', (
    tester,
  ) async {
    final terms = _TestTermRepository(const [
      ReaderTermReplacement(
        source: 'الأول',
        replacement: 'الافتتاحي',
        scope: ReaderTermScope.allNovels,
        novelId: 0,
      ),
    ]);
    await tester.pumpWidget(
      _ReaderTestApp(
        readerTermReplacementRepository: terms,
        child: const ReaderScreen(contentApi: '/chapters/10'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('نص الفصل الافتتاحي'), findsOneWidget);
    expect(find.text('نص الفصل الأول'), findsNothing);
  });

  testWidgets('reader app bar follows the loaded chapter title', (
    tester,
  ) async {
    await tester.pumpWidget(
      _ReaderTestApp(
        readerRepository: const _TestReaderRepository(),
        child: const ReaderScreen(
          contentApi: '/wp-json/wor-reader-app/v1/chapters/10',
          chapterTitle: 'الفصل 1',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text('عنوان الفصل'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('reader-content-tap-area')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('الفصل التالي'));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text('عنوان الفصل التالي'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text('الفصل التالي'),
      ),
      findsNothing,
    );
  });

  testWidgets('toggles floating controls when tapping reader content', (
    tester,
  ) async {
    await tester.pumpWidget(
      _ReaderTestApp(
        readerRepository: const _TestReaderRepository(),
        child: const ReaderScreen(
          contentApi: '/wp-json/wor-reader-app/v1/chapters/10',
          chapterTitle: 'الفصل 1',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('الفصل التالي').hitTestable(), findsNothing);

    await tester.tap(find.byKey(const ValueKey('reader-content-tap-area')));
    await tester.pumpAndSettle();

    expect(find.byTooltip('الفصل التالي'), findsOneWidget);

    await tester.tap(find.text('نص الفصل الأول'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('الفصل التالي').hitTestable(), findsNothing);
  });

  testWidgets('floating controls expose labelled chapter navigation', (
    tester,
  ) async {
    await tester.pumpWidget(
      _ReaderTestApp(
        readerRepository: const _TestReaderRepository(),
        child: const ReaderScreen(
          contentApi: '/wp-json/wor-reader-app/v1/chapters/10',
          chapterTitle: 'الفصل 1',
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('reader-content-tap-area')));
    await tester.pumpAndSettle();

    expect(find.text('التالي'), findsOneWidget);
    expect(find.text('السابق'), findsOneWidget);
    expect(find.byTooltip('الفصل التالي'), findsOneWidget);
    expect(find.byTooltip('الفصل السابق'), findsOneWidget);
  });

  testWidgets(
    'floating controls place next on the right and previous on left',
    (tester) async {
      await tester.pumpWidget(
        _ReaderTestApp(
          readerRepository: const _TestReaderRepository(),
          child: const ReaderScreen(
            contentApi: '/wp-json/wor-reader-app/v1/chapters/10',
            chapterTitle: 'الفصل 1',
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('reader-content-tap-area')));
      await tester.pumpAndSettle();

      final nextCenter = tester.getCenter(find.text('التالي'));
      final previousCenter = tester.getCenter(find.text('السابق'));
      expect(nextCenter.dx, greaterThan(previousCenter.dx));
      expect(
        find.descendant(
          of: find.ancestor(
            of: find.text('التالي'),
            matching: find.byType(FilledButton),
          ),
          matching: find.byIcon(Icons.chevron_left_rounded),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.ancestor(
            of: find.text('السابق'),
            matching: find.byType(OutlinedButton),
          ),
          matching: find.byIcon(Icons.chevron_right_rounded),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('opens reader settings and updates paragraph text size', (
    tester,
  ) async {
    await tester.pumpWidget(
      _ReaderTestApp(
        readerRepository: const _TestReaderRepository(),
        child: const ReaderScreen(
          contentApi: '/wp-json/wor-reader-app/v1/chapters/10',
          chapterTitle: 'الفصل 1',
        ),
      ),
    );
    await tester.pumpAndSettle();

    final beforeStyle = tester
        .widget<EditableText>(find.text('نص الفصل الأول'))
        .style;

    await tester.tap(find.byKey(const ValueKey('reader-content-tap-area')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('reader-settings-button')));
    await tester.pumpAndSettle();

    expect(find.text('إعدادات القراءة'), findsOneWidget);
    final increaseFont = find.byKey(const ValueKey('reader-font-increase'));
    await tester.scrollUntilVisible(
      increaseFont,
      160,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    expect(increaseFont.hitTestable(), findsOneWidget);
    await tester.tap(increaseFont);
    await tester.pumpAndSettle();

    final afterStyle = tester
        .widget<EditableText>(find.text('نص الفصل الأول'))
        .style;

    expect(afterStyle.fontSize, greaterThan(beforeStyle.fontSize ?? 0));
  });

  testWidgets('top bar toggles auto scroll without opening settings', (
    tester,
  ) async {
    final preferencesRepository = FakeReaderPreferencesRepository();
    await tester.pumpWidget(
      _ReaderTestApp(
        readerPreferencesRepository: preferencesRepository,
        disableAnimations: true,
        child: const ReaderScreen(
          contentApi: '/wp-json/wor-reader-app/v1/chapters/10',
          chapterTitle: 'الفصل 1',
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('reader-content-tap-area')));
    await tester.pump();
    final toggle = find.byKey(
      const ValueKey('reader-auto-scroll-toolbar-toggle'),
    );
    expect(find.byTooltip('تشغيل النزول التلقائي'), findsOneWidget);

    await tester.tap(toggle);
    await tester.pump();
    expect(preferencesRepository.value.autoScrollEnabled, isTrue);
    expect(find.byKey(const ValueKey('reader-settings-sheet')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('reader-content-tap-area')));
    await tester.pump();
    expect(find.byTooltip('إيقاف النزول التلقائي'), findsOneWidget);
    await tester.tap(toggle);
    await tester.pump();

    expect(preferencesRepository.value.autoScrollEnabled, isFalse);
  });

  testWidgets('reader settings applies the selected Arabic font family', (
    tester,
  ) async {
    final preferencesRepository = FakeReaderPreferencesRepository();

    await tester.pumpWidget(
      _ReaderTestApp(
        readerRepository: const _TestReaderRepository(),
        readerPreferencesRepository: preferencesRepository,
        child: const ReaderScreen(
          contentApi: '/wp-json/wor-reader-app/v1/chapters/10',
          chapterTitle: 'الفصل 1',
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('reader-content-tap-area')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('reader-settings-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('reader-font-preview')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('reader-font-amiri')));
    await tester.pumpAndSettle();

    final paragraph = tester.widget<EditableText>(find.text('نص الفصل الأول'));
    expect(preferencesRepository.value.fontFamily, ReaderFontFamily.amiri);
    expect(paragraph.style.fontFamily, 'Amiri');
  });

  testWidgets('pinch zoom persists once and follows the next chapter', (
    tester,
  ) async {
    final preferencesRepository = FakeReaderPreferencesRepository();
    await tester.pumpWidget(
      _ReaderTestApp(
        readerRepository: const _TestReaderRepository(),
        readerPreferencesRepository: preferencesRepository,
        child: const ReaderScreen(contentApi: '/chapters/10'),
      ),
    );
    await tester.pumpAndSettle();

    final originalSize = tester
        .widget<EditableText>(find.text('نص الفصل الأول'))
        .style
        .fontSize!;
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
    await first.moveTo(center + const Offset(-100, 0));
    await second.moveTo(center + const Offset(100, 0));
    await tester.pump();

    expect(preferencesRepository.updateCount, 0);
    expect(
      tester.widget<EditableText>(find.text('نص الفصل الأول')).style.fontSize,
      greaterThan(originalSize),
    );

    await first.up();
    await second.up();
    await tester.pumpAndSettle();

    expect(preferencesRepository.updateCount, 1);
    expect(preferencesRepository.value.fontScale, closeTo(2, 0.01));
    final committedSize = tester
        .widget<EditableText>(find.text('نص الفصل الأول'))
        .style
        .fontSize!;

    await tester.tap(find.byKey(const ValueKey('reader-content-tap-area')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('الفصل التالي'));
    await tester.pumpAndSettle();

    expect(
      tester.widget<EditableText>(find.text('نص الفصل التالي')).style.fontSize,
      closeTo(committedSize, 0.01),
    );
    expect(preferencesRepository.updateCount, 1);
  });

  testWidgets('reader settings can switch to a light reading palette', (
    tester,
  ) async {
    await tester.pumpWidget(
      _ReaderTestApp(
        readerRepository: const _TestReaderRepository(),
        child: const ReaderScreen(
          contentApi: '/wp-json/wor-reader-app/v1/chapters/10',
          chapterTitle: 'الفصل 1',
        ),
      ),
    );
    await tester.pumpAndSettle();

    final seedColor = Theme.of(
      tester.element(find.byType(ReaderScreen)),
    ).colorScheme.primary;

    await tester.tap(find.byKey(const ValueKey('reader-content-tap-area')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('reader-settings-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('reader-settings-tab-colors')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('reader-palette-light')));
    await tester.pumpAndSettle();

    final background = tester.widget<ColoredBox>(
      find.byKey(const ValueKey('reader-background')),
    );

    expect(
      ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.light,
      ).surface,
      background.color,
    );
  });

  testWidgets(
    'reader settings exposes richer palettes and text width controls',
    (tester) async {
      final preferencesRepository = FakeReaderPreferencesRepository();

      await tester.pumpWidget(
        _ReaderTestApp(
          readerRepository: const _TestReaderRepository(),
          readerPreferencesRepository: preferencesRepository,
          child: const ReaderScreen(
            contentApi: '/wp-json/wor-reader-app/v1/chapters/10',
            chapterTitle: 'الفصل 1',
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('reader-content-tap-area')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('reader-settings-button')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('reader-settings-tab-colors')),
      );
      await tester.pumpAndSettle();

      expect(find.text('ألوان القراءة'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('reader-palette-paper')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('reader-palette-sepia')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('reader-palette-nightBlue')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('reader-palette-amoled')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('reader-palette-nightBlue')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('reader-settings-tab-text')));
      await tester.pumpAndSettle();
      expect(find.text('عرض النص'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('reader-width-compact')),
        120,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('reader-width-compact')));
      await tester.pumpAndSettle();

      expect(
        preferencesRepository.value.paletteMode,
        ReaderPaletteMode.nightBlue,
      );
      expect(preferencesRepository.value.textWidth, ReaderTextWidth.compact);

      final background = tester.widget<ColoredBox>(
        find.byKey(const ValueKey('reader-background')),
      );
      expect(background.color, const Color(0xFF07111F));

      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('reader-settings-reset')),
        160,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('reader-settings-reset')));
      await tester.pumpAndSettle();

      expect(preferencesRepository.value, ReaderPreferences.defaults);
    },
  );

  testWidgets('reader settings controls immersive mode and screen brightness', (
    tester,
  ) async {
    final preferencesRepository = FakeReaderPreferencesRepository();

    await tester.pumpWidget(
      _ReaderTestApp(
        readerRepository: const _TestReaderRepository(),
        readerPreferencesRepository: preferencesRepository,
        child: const ReaderScreen(
          contentApi: '/wp-json/wor-reader-app/v1/chapters/10',
          chapterTitle: 'الفصل 1',
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('reader-content-tap-area')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('reader-settings-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('reader-settings-tab-screen')));
    await tester.pumpAndSettle();

    expect(find.text('الوضع الغامر'), findsOneWidget);
    expect(find.text('سطوع الشاشة'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('reader-immersive-toggle')),
      160,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('reader-immersive-toggle')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('reader-brightness-manual')),
      160,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('reader-brightness-manual')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('reader-brightness-slider')),
      160,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const ValueKey('reader-brightness-slider')),
      const Offset(90, 0),
    );
    await tester.pumpAndSettle();

    expect(preferencesRepository.value.immersiveMode, isTrue);
    expect(
      preferencesRepository.value.brightnessMode,
      ReaderBrightnessMode.manual,
    );
    expect(preferencesRepository.value.screenBrightness, greaterThan(0.65));
  });

  testWidgets('records reading progress when chapter content loads', (
    tester,
  ) async {
    final historyRepository = _TestReadingHistoryRepository();

    await tester.pumpWidget(
      _ReaderTestApp(
        readerRepository: const _TestReaderRepository(),
        readingHistoryRepository: historyRepository,
        child: const ReaderScreen(
          contentApi: '/wp-json/wor-reader-app/v1/chapters/10',
          chapterTitle: 'الفصل 1',
          novelTitle: 'رواية الاختبار',
          coverUrl: '/wp-content/uploads/covers/novel.jpg',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(historyRepository.records, hasLength(1));
    expect(historyRepository.records.single.novelId, 1);
    expect(historyRepository.records.single.novelTitle, 'رواية الاختبار');
    expect(historyRepository.records.single.chapterId, 10);
    expect(historyRepository.records.single.chapterTitle, 'عنوان الفصل');
    expect(
      historyRepository.records.single.coverUrl,
      '/wp-content/uploads/covers/novel.jpg',
    );
    expect(historyRepository.records.single.chapterPosition, 1);
    expect(historyRepository.records.single.chaptersTotal, 2);
  });

  testWidgets('scrolling reports chapter progress to the account session', (
    tester,
  ) async {
    final recorder = _TestReadingActivityRecorder();
    await tester.pumpWidget(
      _ReaderTestApp(
        readingActivityRecorder: recorder,
        readerRepository: const _LongChapterReaderRepository(),
        child: const ReaderScreen(contentApi: '/chapters/10'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pump();

    expect(recorder.sessions, hasLength(1));
    expect(recorder.sessions.single.progress, greaterThan(0));
  });

  testWidgets('scrolling reader content does not reveal navigation controls', (
    tester,
  ) async {
    await tester.pumpWidget(
      const _ReaderTestApp(
        readerRepository: _LongChapterReaderRepository(),
        child: ReaderScreen(contentApi: '/chapters/10'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('الفصل التالي').hitTestable(), findsNothing);

    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();

    expect(find.byTooltip('الفصل التالي').hitTestable(), findsNothing);
    expect(
      tester
          .widget<ExcludeSemantics>(
            find.byKey(const ValueKey('reader-controls-exclude-semantics')),
          )
          .excluding,
      isTrue,
    );
  });

  testWidgets('opening the next chapter finishes the previous session', (
    tester,
  ) async {
    final recorder = _TestReadingActivityRecorder();
    await tester.pumpWidget(
      _ReaderTestApp(
        readingActivityRecorder: recorder,
        child: const ReaderScreen(contentApi: '/chapters/10'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('reader-content-tap-area')));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('الفصل التالي'));
    await tester.pumpAndSettle();

    expect(recorder.sessions, hasLength(2));
    expect(recorder.sessions.first.finishCount, 1);
  });

  testWidgets('reader lifecycle pauses and resumes the account session', (
    tester,
  ) async {
    final recorder = _TestReadingActivityRecorder();
    await tester.pumpWidget(
      _ReaderTestApp(
        readingActivityRecorder: recorder,
        child: const ReaderScreen(contentApi: '/chapters/10'),
      ),
    );
    await tester.pumpAndSettle();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(recorder.sessions.single.pauseCount, 1);
    expect(recorder.sessions.single.resumeCount, 1);
  });

  testWidgets('shows an error when chapter content fails', (tester) async {
    await tester.pumpWidget(
      _ReaderTestApp(
        readerRepository: const _FailingReaderRepository(),
        child: const ReaderScreen(
          contentApi: '/wp-json/wor-reader-app/v1/chapters/10',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('تعذر تحميل الفصل'), findsOneWidget);
    expect(find.text('إعادة المحاولة'), findsOneWidget);
  });

  testWidgets('reader failure hides raw state errors and retry can recover', (
    tester,
  ) async {
    final readerRepository = _RetryingReaderRepository();
    await tester.pumpWidget(
      _ReaderTestApp(
        readerRepository: readerRepository,
        child: const ReaderScreen(contentApi: '/chapters/10'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('secret-path'), findsNothing);
    expect(find.text('تعذر تحميل الفصل'), findsOneWidget);

    await tester.tap(find.text('إعادة المحاولة'));
    await tester.pumpAndSettle();

    expect(readerRepository.loadCalls, 2);
    expect(find.text('نص الفصل الأول'), findsOneWidget);
  });

  testWidgets('opens chapter comments and keeps the reader mounted', (
    tester,
  ) async {
    final commentsRepository = FakeCommentsRepository(
      handler: (target, sort, page) async => CommentsPage(
        version: 2,
        target: target,
        sort: sort,
        page: page,
        perPage: 20,
        totalComments: 1,
        totalRoots: 1,
        totalPages: 1,
        generated: 1,
        reactions: const {},
        comments: [_readerComment()],
      ),
    );
    await tester.pumpWidget(
      _ReaderTestApp(
        commentsRepository: commentsRepository,
        child: const ReaderScreen(contentApi: '/chapters/10'),
      ),
    );
    await tester.pumpAndSettle();

    expect(commentsRepository.calls, isEmpty);
    await tester.tap(find.byKey(const ValueKey('reader-content-tap-area')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('reader-comments-button')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('chapter-comments-sheet')),
      findsOneWidget,
    );
    expect(find.text('تعليق الفصل'), findsOneWidget);
    expect(commentsRepository.calls.single.target, CommentTarget.chapter(10));

    await tester.tap(find.byTooltip('إغلاق تعليقات الفصل'));
    await tester.pumpAndSettle();

    expect(find.text('نص الفصل الأول'), findsOneWidget);
  });

  testWidgets('chapter guest CTA opens account and returns to reader', (
    tester,
  ) async {
    await tester.pumpWidget(
      const _ReaderTestApp(child: ReaderScreen(contentApi: '/chapters/10')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('reader-content-tap-area')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('reader-comments-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('comments-open-account')));
    await tester.pumpAndSettle();

    expect(find.byType(AccountScreen), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('chapter-comments-sheet')),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('إغلاق تعليقات الفصل'));
    await tester.pumpAndSettle();
    expect(find.text('نص الفصل الأول'), findsOneWidget);
  });

  testWidgets('comments controls fit a narrow single chapter reader', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      _ReaderTestApp(
        readerRepository: const _SingleChapterReaderRepository(),
        child: const ReaderScreen(contentApi: '/chapters/12'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('reader-content-tap-area')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('reader-comments-button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('reader-settings-button')),
      findsOneWidget,
    );
    final previousY = tester.getCenter(find.text('السابق')).dy;
    final commentsY = tester
        .getCenter(find.byKey(const ValueKey('reader-comments-button')))
        .dy;
    final nextY = tester.getCenter(find.text('التالي')).dy;
    expect(previousY, closeTo(commentsY, 1));
    expect(nextY, closeTo(commentsY, 1));
    expect(tester.takeException(), isNull);
  });
}

class _ReaderTestApp extends StatelessWidget {
  const _ReaderTestApp({
    required this.child,
    this.readerRepository = const _TestReaderRepository(),
    this.readingHistoryRepository,
    this.commentsRepository,
    this.readerPreferencesRepository,
    this.readerSpeechController,
    this.readerTermReplacementRepository,
    this.readingActivityRecorder = const NoopReadingActivityRecorder(),
    this.fullScreenAdRepository = const NoopFullScreenAdRepository(),
    this.disableAnimations = false,
    this.mediaQueryPadding = EdgeInsets.zero,
  });

  final Widget child;
  final ReaderRepository readerRepository;
  final ReadingHistoryRepository? readingHistoryRepository;
  final CommentsRepository? commentsRepository;
  final FakeReaderPreferencesRepository? readerPreferencesRepository;
  final ReaderSpeechController? readerSpeechController;
  final ReaderTermReplacementRepository? readerTermReplacementRepository;
  final ReadingActivityRecorder readingActivityRecorder;
  final FullScreenAdRepository fullScreenAdRepository;
  final bool disableAnimations;
  final EdgeInsets mediaQueryPadding;

  @override
  Widget build(BuildContext context) {
    return AppDependencies(
      config: const AppConfig(),
      homeRepository: const FakeHomeRepository(),
      catalogRepository: const FakeCatalogRepository(),
      novelRepository: const FakeNovelRepository(result: null),
      readerRepository: readerRepository,
      rankingsRepository: const FakeRankingsRepository(),
      searchRepository: const FakeSearchRepository(),
      readingHistoryRepository:
          readingHistoryRepository ?? _TestReadingHistoryRepository(),
      readerPreferencesRepository:
          readerPreferencesRepository ?? FakeReaderPreferencesRepository(),
      readerSpeechController: readerSpeechController,
      readerTermReplacementRepository: readerTermReplacementRepository,
      authRepository: FakeAuthRepository(),
      commentsRepository: commentsRepository ?? FakeCommentsRepository.empty(),
      favoritesRepository: FakeFavoritesRepository(),
      novelEngagementRepository: FakeNovelEngagementRepository(),
      vipRepository: const FakeVipRepository(),
      fullScreenAdRepository: fullScreenAdRepository,
      readingActivityRecorder: readingActivityRecorder,
      child: MaterialApp(
        locale: const Locale('ar'),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: disableAnimations,
            padding: mediaQueryPadding,
          ),
          child: child!,
        ),
        home: Directionality(textDirection: TextDirection.rtl, child: child),
      ),
    );
  }
}

class _TestSpeechController extends ChangeNotifier
    implements ReaderSpeechController {
  ReaderSpeechState _value = ReaderSpeechState.idle;
  ReaderSpeechChapter? preparedChapter;

  @override
  ReaderSpeechState get value => _value;

  @override
  ReaderSpeechPreferences get preferences => ReaderSpeechPreferences.defaults;

  @override
  List<ReaderSpeechVoice> get availableVoices => const [];

  @override
  ReaderSpeechSleepTimer get sleepTimer => ReaderSpeechSleepTimer.off;

  @override
  DateTime? get sleepTimerEndsAt => null;

  @override
  void bindChapterSource(ReaderSpeechChapterSource source) {}

  @override
  Future<void> prepareChapter(
    ReaderSpeechChapter chapter, {
    int? visibleBlockIndex,
  }) async {
    preparedChapter = chapter;
    _value = ReaderSpeechState(
      status: ReaderSpeechStatus.paused,
      chapter: chapter,
      blockIndex: visibleBlockIndex ?? 0,
      characterStart: 0,
      characterEnd: 0,
      errorMessage: null,
    );
    notifyListeners();
  }

  @override
  Future<void> pause() async {}

  @override
  Future<void> play() async {}

  @override
  Future<void> previewVoice(ReaderSpeechVoice voice) async {}

  @override
  Future<void> setSleepTimer(ReaderSpeechSleepTimer timer) async {}

  @override
  Future<void> skipNextBlock() async {}

  @override
  Future<void> skipPreviousBlock() async {}

  @override
  Future<void> startFromBlock(int blockIndex) async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> updatePreferences(ReaderSpeechPreferences preferences) async {}
}

class _AllowedSystemSettings extends AppSystemSettings {
  const _AllowedSystemSettings();

  @override
  Future<bool> requestNotificationPermission() async => true;
}

class _TestTermRepository extends ChangeNotifier
    implements ReaderTermReplacementRepository {
  _TestTermRepository(List<ReaderTermReplacement> initial)
    : _value = List.unmodifiable(initial);

  List<ReaderTermReplacement> _value;

  @override
  List<ReaderTermReplacement> get value => _value;

  @override
  Future<void> load() async {}

  @override
  Future<void> remove(ReaderTermReplacement replacement) async {
    _value = List.unmodifiable(_value.where((rule) => rule != replacement));
    notifyListeners();
  }

  @override
  Future<void> save(
    ReaderTermReplacement replacement, {
    ReaderTermReplacement? replacing,
  }) async {
    final updated = [..._value];
    if (replacing != null) updated.remove(replacing);
    updated.add(replacement);
    _value = List.unmodifiable(updated);
    notifyListeners();
  }
}

class _TestReaderRepository implements ReaderRepository {
  const _TestReaderRepository();

  @override
  Future<ReaderChapterContent> loadChapter(String contentApi) async {
    if (contentApi.endsWith('/11')) {
      return const ReaderChapterContent(
        id: 11,
        novelId: 1,
        label: 'الفصل 2',
        title: '',
        displayTitle: 'عنوان الفصل التالي',
        position: 2,
        total: 2,
        contentHtml: '<p>نص الفصل التالي</p>',
        navigation: ReaderChapterNavigation(
          previousApi: '/wp-json/wor-reader-app/v1/chapters/10',
          nextApi: '',
          previousId: 10,
          nextId: 0,
        ),
      );
    }

    return const ReaderChapterContent(
      id: 10,
      novelId: 1,
      label: 'الفصل 1',
      title: '',
      displayTitle: 'عنوان الفصل',
      position: 1,
      total: 2,
      contentHtml: '<p>نص الفصل الأول</p>',
      navigation: ReaderChapterNavigation(
        previousApi: '',
        nextApi: '/wp-json/wor-reader-app/v1/chapters/11',
        previousId: 0,
        nextId: 11,
      ),
    );
  }
}

class _CountingReaderRepository implements ReaderRepository {
  final requestedApis = <String>[];

  @override
  Future<ReaderChapterContent> loadChapter(String contentApi) {
    requestedApis.add(contentApi);
    return const _TestReaderRepository().loadChapter(contentApi);
  }
}

class _PreviousChapterReaderRepository implements ReaderRepository {
  const _PreviousChapterReaderRepository();

  @override
  Future<ReaderChapterContent> loadChapter(String contentApi) {
    if (contentApi.endsWith('/11')) {
      return Future.value(
        const ReaderChapterContent(
          id: 11,
          novelId: 1,
          label: 'الفصل 2',
          title: '',
          displayTitle: 'عنوان الفصل التالي',
          position: 2,
          total: 2,
          contentHtml: '<p>نص الفصل التالي</p>',
          navigation: ReaderChapterNavigation(
            previousApi: '/chapters/10',
            nextApi: '',
            previousId: 10,
            nextId: 0,
          ),
        ),
      );
    }
    return const _TestReaderRepository().loadChapter(contentApi);
  }
}

class _BlockingFullScreenAdRepository implements FullScreenAdRepository {
  Completer<bool>? _readerCompleter;
  int readerCalls = 0;

  @override
  bool get isSupported => true;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> showAppOpenOnColdStart({required bool canShow}) async => false;

  @override
  Future<bool> showAppOpenOnForeground({required bool canShow}) async => false;

  @override
  Future<bool> showBrowseInterstitial({required bool canShow}) async => false;

  @override
  Future<bool> showReaderInterstitialIfDue({required bool canShow}) {
    readerCalls += 1;
    return (_readerCompleter ??= Completer<bool>()).future;
  }

  void completeReaderAd({required bool shown}) {
    _readerCompleter?.complete(shown);
    _readerCompleter = null;
  }

  @override
  void dispose() {}
}

class _FailingReaderRepository implements ReaderRepository {
  const _FailingReaderRepository();

  @override
  Future<ReaderChapterContent> loadChapter(String contentApi) async {
    throw Exception('reader failed');
  }
}

class _VipLockedReaderRepository implements ReaderRepository {
  const _VipLockedReaderRepository();

  @override
  Future<ReaderChapterContent> loadChapter(String contentApi) {
    throw const DownloadVipLockedException(
      DownloadVipLockReason.verificationRequired,
    );
  }
}

class _RetryingReaderRepository implements ReaderRepository {
  int loadCalls = 0;

  @override
  Future<ReaderChapterContent> loadChapter(String contentApi) async {
    loadCalls += 1;
    if (loadCalls == 1) {
      throw StateError('secret-path');
    }
    return const _TestReaderRepository().loadChapter(contentApi);
  }
}

class _SingleChapterReaderRepository implements ReaderRepository {
  const _SingleChapterReaderRepository();

  @override
  Future<ReaderChapterContent> loadChapter(String contentApi) async {
    return const ReaderChapterContent(
      id: 12,
      novelId: 1,
      label: 'الفصل الوحيد',
      title: '',
      displayTitle: 'الفصل الوحيد',
      position: 1,
      total: 1,
      contentHtml: '<p>نص فصل واحد</p>',
      navigation: ReaderChapterNavigation(
        previousApi: '',
        nextApi: '',
        previousId: 0,
        nextId: 0,
      ),
    );
  }
}

class _LongChapterReaderRepository implements ReaderRepository {
  const _LongChapterReaderRepository();

  @override
  Future<ReaderChapterContent> loadChapter(String contentApi) async {
    return ReaderChapterContent(
      id: 10,
      novelId: 1,
      label: 'الفصل 1',
      title: '',
      displayTitle: 'فصل طويل',
      position: 1,
      total: 2,
      contentHtml: List.filled(80, '<p>سطر قراءة طويل للاختبار</p>').join(),
      navigation: const ReaderChapterNavigation(
        previousApi: '',
        nextApi: '/wp-json/wor-reader-app/v1/chapters/11',
        previousId: 0,
        nextId: 11,
      ),
    );
  }
}

class _TestReadingActivitySession implements ReadingActivitySession {
  int progress = 0;
  int finishCount = 0;
  int pauseCount = 0;
  int resumeCount = 0;

  @override
  void recordInteraction(int nextProgress) => progress = nextProgress;

  @override
  Future<void> checkpoint() async {}

  @override
  Future<void> pause() async => pauseCount++;

  @override
  void resume() => resumeCount++;

  @override
  Future<void> finish() async => finishCount++;
}

class _TestReadingActivityRecorder implements ReadingActivityRecorder {
  final sessions = <_TestReadingActivitySession>[];

  @override
  ReadingActivitySession startChapter({
    required int novelId,
    required int chapterId,
  }) {
    final session = _TestReadingActivitySession();
    sessions.add(session);
    return session;
  }

  @override
  Future<void> syncPending() async {}

  @override
  void dispose() {}
}

class _TestReadingHistoryRepository implements ReadingHistoryRepository {
  final records = <ReadingProgress>[];

  @override
  void addListener(VoidCallback listener) {}

  @override
  Future<List<ReadingProgress>> load() async => records;

  @override
  Future<void> record(ReadingProgress progress) async {
    records.add(progress);
  }

  @override
  void removeListener(VoidCallback listener) {}
}

PublicComment _readerComment() {
  return PublicComment(
    id: 90,
    parentId: 0,
    rootId: 0,
    depth: 0,
    authorName: 'قارئ الفصل',
    authorRank: '',
    avatarUrl: '',
    replyToName: '',
    content: 'تعليق الفصل',
    isSpoiler: false,
    likeCount: 0,
    dislikeCount: 0,
    repliesCount: 0,
    score: 0,
    isPinned: false,
    createdLabel: 'الآن',
    createdAt: null,
    replies: const [],
  );
}
