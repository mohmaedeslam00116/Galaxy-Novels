import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/app/app_dependencies.dart';
import 'package:galaxy_novels_app/core/config/app_config.dart';
import 'package:galaxy_novels_app/data/models/novel_details_data.dart';
import 'package:galaxy_novels_app/data/models/reader_content_data.dart';
import 'package:galaxy_novels_app/data/models/reading_progress.dart';
import 'package:galaxy_novels_app/data/repositories/fake_catalog_repository.dart';
import 'package:galaxy_novels_app/data/repositories/fake_downloads_repository.dart';
import 'package:galaxy_novels_app/data/repositories/fake_home_repository.dart';
import 'package:galaxy_novels_app/data/repositories/fake_rankings_repository.dart';
import 'package:galaxy_novels_app/data/repositories/fake_search_repository.dart';
import 'package:galaxy_novels_app/data/repositories/novel_repository.dart';
import 'package:galaxy_novels_app/data/repositories/reader_repository.dart';
import 'package:galaxy_novels_app/data/repositories/reading_history_repository.dart';
import 'package:galaxy_novels_app/features/downloads/application/download_manager.dart';
import 'package:galaxy_novels_app/features/comments/application/comments_repository.dart';
import 'package:galaxy_novels_app/features/comments/domain/comments_page.dart';
import 'package:galaxy_novels_app/features/comments/domain/public_comment.dart';
import 'package:galaxy_novels_app/features/novel_details/presentation/novel_details_screen.dart';

import '../../helpers/fake_reader_preferences_repository.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_comments_repository.dart';
import '../../helpers/fake_favorites_repository.dart';
import '../../helpers/fake_novel_engagement_repository.dart';
import '../../helpers/fake_vip_repository.dart';

void main() {
  testWidgets('shows fifty chapters in details and opens paginated full list', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final repository = _LongNovelRepository();
    await tester.pumpWidget(_TestApp(repository: repository));
    await tester.pumpAndSettle();

    final showAllButton = find.byKey(const ValueKey('show-all-chapters'));
    await tester.scrollUntilVisible(
      showAllButton,
      400,
      scrollable: _verticalScrollable(),
    );
    await tester.pumpAndSettle();

    expect(find.text('الفصل 50'), findsOneWidget);
    expect(find.text('الفصل 51'), findsNothing);

    await tester.tap(showAllButton);
    await tester.pumpAndSettle();

    expect(find.text('كل الفصول'), findsOneWidget);
    expect(find.byKey(const ValueKey('chapter-page-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('chapter-page-6')), findsOneWidget);
    expect(find.byKey(const ValueKey('chapter-page-previous')), findsOneWidget);
    expect(find.byKey(const ValueKey('chapter-page-next')), findsOneWidget);
    expect(find.text('الفصل 51'), findsNothing);

    await tester.scrollUntilVisible(
      find.text('الفصل 50'),
      320,
      scrollable: _verticalScrollable(),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('chapter-page-next')));
    await tester.pumpAndSettle();

    expect(find.text('الفصل 51'), findsOneWidget);
    expect(find.text('الفصل 100'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('الفصل 100'),
      320,
      scrollable: _verticalScrollable(),
    );
    await tester.pumpAndSettle();

    expect(find.text('الفصل 100'), findsOneWidget);
    expect(find.text('الفصل 101'), findsNothing);
    expect(repository.loadCalls, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('loads novel comments only when their tab is opened', (
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
        comments: [_comment('تعليق الرواية')],
      ),
    );
    await tester.pumpWidget(
      _TestApp(
        repository: _LongNovelRepository(),
        commentsRepository: commentsRepository,
      ),
    );
    await tester.pumpAndSettle();

    expect(commentsRepository.calls, isEmpty);
    final commentsTab = find.byKey(const ValueKey('novel-section-comments'));
    await _revealAboveBottomBar(tester, commentsTab);
    await tester.tap(commentsTab);
    await tester.pumpAndSettle();

    expect(find.text('تعليق الرواية'), findsOneWidget);
    expect(commentsRepository.calls, hasLength(1));

    await tester.tap(find.byKey(const ValueKey('novel-section-chapters')));
    await tester.pump();
    await tester.tap(commentsTab);
    await tester.pump();

    expect(commentsRepository.calls, hasLength(1));
  });

  testWidgets('comment failure does not hide the read action', (tester) async {
    final commentsRepository = FakeCommentsRepository(
      handler: (_, _, _) => Future.error(Exception('offline')),
    );
    await tester.pumpWidget(
      _TestApp(
        repository: _LongNovelRepository(),
        commentsRepository: commentsRepository,
      ),
    );
    await tester.pumpAndSettle();

    final commentsTab = find.byKey(const ValueKey('novel-section-comments'));
    await _revealAboveBottomBar(tester, commentsTab);
    await tester.tap(commentsTab);
    await tester.pumpAndSettle();

    expect(find.text('تعذر تحميل التعليقات الآن.'), findsOneWidget);
    expect(find.text('ابدأ القراءة'), findsOneWidget);
  });

  testWidgets('keeps VIP chapters inside the chapters section, not a tab', (
    tester,
  ) async {
    await tester.pumpWidget(
      _TestApp(repository: _LongNovelRepository(hasVipSchedule: true)),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('novel-section-chapters')),
      300,
      scrollable: _verticalScrollable(),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('novel-section-vip')), findsNothing);
    expect(find.text('الفصول'), findsWidgets);
  });
}

Finder _verticalScrollable() {
  return find.byWidgetPredicate(
    (widget) =>
        widget is Scrollable && widget.axisDirection == AxisDirection.down,
  );
}

Future<void> _revealAboveBottomBar(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    300,
    scrollable: _verticalScrollable(),
  );
  await Scrollable.ensureVisible(
    tester.element(finder),
    alignment: 0.38,
    duration: Duration.zero,
  );
  await tester.pumpAndSettle();
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.repository, this.commentsRepository});

  final NovelRepository repository;
  final CommentsRepository? commentsRepository;

  @override
  Widget build(BuildContext context) {
    final downloadsRepository = FakeDownloadsRepository();
    return AppDependencies(
      config: const AppConfig(),
      homeRepository: const FakeHomeRepository(),
      catalogRepository: const FakeCatalogRepository(),
      novelRepository: repository,
      readerRepository: const _TestReaderRepository(),
      rankingsRepository: const FakeRankingsRepository(),
      searchRepository: const FakeSearchRepository(),
      readingHistoryRepository: const _TestReadingHistoryRepository(),
      downloadsRepository: downloadsRepository,
      downloadManager: DownloadManager(repository: downloadsRepository),
      readerPreferencesRepository: FakeReaderPreferencesRepository(),
      authRepository: FakeAuthRepository(),
      commentsRepository: commentsRepository ?? FakeCommentsRepository.empty(),
      favoritesRepository: FakeFavoritesRepository(),
      novelEngagementRepository: FakeNovelEngagementRepository(),
      vipRepository: const FakeVipRepository(),
      child: const MaterialApp(
        locale: Locale('ar'),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: NovelDetailsScreen(manifestPath: '/novel-long.json'),
        ),
      ),
    );
  }
}

PublicComment _comment(String content) {
  return PublicComment(
    id: 71,
    parentId: 0,
    rootId: 0,
    depth: 0,
    authorName: 'قارئ تجريبي',
    authorRank: '',
    avatarUrl: '',
    replyToName: '',
    content: content,
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

class _LongNovelRepository implements NovelRepository {
  _LongNovelRepository({this.hasVipSchedule = false});

  final bool hasVipSchedule;
  int loadCalls = 0;

  @override
  Future<NovelDetailsLoadResult> loadNovel(String manifestPath) async {
    loadCalls++;
    return NovelDetailsLoadResult(
      details: NovelDetails(
        id: 500,
        title: 'رواية طويلة',
        originalTitle: '',
        url: '/novel/long/',
        coverThumbnail: '',
        coverMedium: '',
        coverLarge: '',
        statusKey: 'ongoing',
        statusLabel: 'مستمرة',
        country: '',
        author: 'كاتب الاختبار',
        translator: '',
        genres: [],
        chaptersCount: 300,
        firstChapterId: 1,
        firstChapterUrl: '/chapter-1/',
        ratingAverage: 4.5,
        ratingCount: 10,
        views: 1000,
        updatedAt: null,
        summary: '',
        chaptersManifest: '/chapters.json',
        vipScheduleManifest: hasVipSchedule ? '/vip-schedule.json' : '',
        manifest: '/novel-long.json',
      ),
      chapters: List.generate(300, (index) {
        final number = index + 1;
        return NovelChapter(
          id: number,
          position: number,
          number: '$number',
          label: 'الفصل $number',
          title: 'عنوان الفصل $number',
          url: '/chapter-$number/',
          contentApi: '/chapters/$number',
          dateLabel: 'اليوم',
          dateIso: null,
          views: 0,
          comments: 0,
          search: 'الفصل $number عنوان الفصل $number',
        );
      }),
    );
  }
}

class _TestReaderRepository implements ReaderRepository {
  const _TestReaderRepository();

  @override
  Future<ReaderChapterContent> loadChapter(String contentApi) {
    throw UnimplementedError();
  }
}

class _TestReadingHistoryRepository implements ReadingHistoryRepository {
  const _TestReadingHistoryRepository();

  @override
  void addListener(VoidCallback listener) {}

  @override
  Future<List<ReadingProgress>> load() async => const [];

  @override
  Future<void> record(ReadingProgress progress) async {}

  @override
  void removeListener(VoidCallback listener) {}
}
