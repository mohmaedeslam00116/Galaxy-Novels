import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/app/app_dependencies.dart';
import 'package:galaxy_novels_app/core/config/app_config.dart';
import 'package:galaxy_novels_app/data/models/downloaded_chapter.dart';
import 'package:galaxy_novels_app/data/models/reader_content_data.dart';
import 'package:galaxy_novels_app/data/models/reading_progress.dart';
import 'package:galaxy_novels_app/data/repositories/downloads_repository.dart';
import 'package:galaxy_novels_app/data/repositories/fake_catalog_repository.dart';
import 'package:galaxy_novels_app/data/repositories/fake_downloads_repository.dart';
import 'package:galaxy_novels_app/data/repositories/fake_home_repository.dart';
import 'package:galaxy_novels_app/data/repositories/fake_novel_repository.dart';
import 'package:galaxy_novels_app/data/repositories/fake_rankings_repository.dart';
import 'package:galaxy_novels_app/data/repositories/fake_search_repository.dart';
import 'package:galaxy_novels_app/data/repositories/reader_repository.dart';
import 'package:galaxy_novels_app/data/repositories/reading_history_repository.dart';
import 'package:galaxy_novels_app/features/downloads/application/download_manager.dart';
import 'package:galaxy_novels_app/features/comments/application/comments_repository.dart';
import 'package:galaxy_novels_app/features/comments/domain/comment_target.dart';
import 'package:galaxy_novels_app/features/comments/domain/comments_page.dart';
import 'package:galaxy_novels_app/features/comments/domain/public_comment.dart';
import 'package:galaxy_novels_app/features/ads/application/reader_ad_repository.dart';
import 'package:galaxy_novels_app/features/reading_activity/application/reading_activity_recorder.dart';
import 'package:galaxy_novels_app/features/reader/presentation/reader_screen.dart';

import '../../helpers/fake_reader_preferences_repository.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_comments_repository.dart';
import '../../helpers/fake_favorites_repository.dart';
import '../../helpers/fake_novel_engagement_repository.dart';
import '../../helpers/fake_vip_repository.dart';

void main() {
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
    expect(find.byTooltip('الفصل التالي'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await tester.tap(find.byKey(const ValueKey('reader-content-tap-area')));
    await tester.pumpAndSettle();

    expect(find.byTooltip('الفصل التالي'), findsOneWidget);

    await tester.tap(find.byTooltip('الفصل التالي'));
    await tester.pumpAndSettle();

    expect(find.text('عنوان الفصل التالي'), findsWidgets);
    expect(find.text('نص الفصل التالي'), findsOneWidget);
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

    expect(find.byTooltip('الفصل التالي'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('reader-content-tap-area')));
    await tester.pumpAndSettle();

    expect(find.byTooltip('الفصل التالي'), findsOneWidget);

    await tester.tap(find.text('نص الفصل الأول'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('الفصل التالي'), findsNothing);
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

    final beforeStyle = tester.widget<Text>(find.text('نص الفصل الأول')).style;

    await tester.tap(find.byKey(const ValueKey('reader-content-tap-area')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('reader-settings-button')));
    await tester.pumpAndSettle();

    expect(find.text('إعدادات القراءة'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('reader-font-increase')));
    await tester.pumpAndSettle();

    final afterStyle = tester.widget<Text>(find.text('نص الفصل الأول')).style;

    expect(afterStyle?.fontSize, greaterThan(beforeStyle?.fontSize ?? 0));
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

  testWidgets('opens a downloaded chapter without using the network', (
    tester,
  ) async {
    final downloadsRepository = FakeDownloadsRepository(
      chapters: [
        DownloadedChapter(
          novelId: 7,
          novelTitle: 'رواية محلية',
          novelCover: '',
          chapterId: 70,
          chapterTitle: 'عنوان الفصل المحلي',
          chapterLabel: 'الفصل 7',
          chapterPosition: 7,
          chaptersTotal: 120,
          contentApi: '/chapters/70',
          contentHtml: '<p>هذا النص متاح دون إنترنت</p>',
          plainTextPreview: 'هذا النص متاح دون إنترنت',
          downloadedAt: DateTime.utc(2026, 6, 20),
          lastOpenedAt: null,
        ),
      ],
    );

    await tester.pumpWidget(
      _ReaderTestApp(
        readerRepository: const _FailingReaderRepository(),
        downloadsRepository: downloadsRepository,
        child: const ReaderScreen(
          contentApi: '/chapters/70',
          novelTitle: 'رواية محلية',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('هذا النص متاح دون إنترنت'), findsOneWidget);
    expect(find.text('تعذر تحميل الفصل'), findsNothing);
    expect(
      downloadsRepository.state.value.chapters.single.lastOpenedAt,
      isNotNull,
    );
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
    expect(tester.takeException(), isNull);
  });

  testWidgets('reader banner can be hidden for the current chapter only', (
    tester,
  ) async {
    await tester.pumpWidget(
      _ReaderTestApp(
        readerAdRepository: const _TestReaderAdRepository(),
        child: const ReaderScreen(contentApi: '/chapters/10'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('إعلان القارئ'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('reader-ad-close-button')));
    await tester.pumpAndSettle();

    expect(find.text('إعلان القارئ'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('reader-content-tap-area')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('الفصل التالي'));
    await tester.pumpAndSettle();

    expect(find.text('إعلان القارئ'), findsOneWidget);
  });
}

class _ReaderTestApp extends StatelessWidget {
  const _ReaderTestApp({
    required this.child,
    this.readerRepository = const _TestReaderRepository(),
    this.readingHistoryRepository,
    this.downloadsRepository,
    this.commentsRepository,
    this.readerAdRepository = const NoopReaderAdRepository(),
    this.readingActivityRecorder = const NoopReadingActivityRecorder(),
  });

  final Widget child;
  final ReaderRepository readerRepository;
  final ReadingHistoryRepository? readingHistoryRepository;
  final DownloadsRepository? downloadsRepository;
  final CommentsRepository? commentsRepository;
  final ReaderAdRepository readerAdRepository;
  final ReadingActivityRecorder readingActivityRecorder;

  @override
  Widget build(BuildContext context) {
    final effectiveDownloadsRepository =
        downloadsRepository ?? FakeDownloadsRepository();
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
      downloadsRepository: effectiveDownloadsRepository,
      downloadManager: DownloadManager(
        repository: effectiveDownloadsRepository,
      ),
      readerPreferencesRepository: FakeReaderPreferencesRepository(),
      authRepository: FakeAuthRepository(),
      commentsRepository: commentsRepository ?? FakeCommentsRepository.empty(),
      favoritesRepository: FakeFavoritesRepository(),
      novelEngagementRepository: FakeNovelEngagementRepository(),
      vipRepository: const FakeVipRepository(),
      readerAdRepository: readerAdRepository,
      readingActivityRecorder: readingActivityRecorder,
      child: MaterialApp(
        locale: const Locale('ar'),
        home: Directionality(textDirection: TextDirection.rtl, child: child),
      ),
    );
  }
}

class _TestReaderAdRepository implements ReaderAdRepository {
  const _TestReaderAdRepository();

  @override
  Future<void> initialize() async {}

  @override
  Widget? buildReaderBanner(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      color: Colors.white,
      child: const Text('إعلان القارئ'),
    );
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

class _FailingReaderRepository implements ReaderRepository {
  const _FailingReaderRepository();

  @override
  Future<ReaderChapterContent> loadChapter(String contentApi) async {
    throw Exception('reader failed');
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
