import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/app/app_theme_controller.dart';
import 'package:galaxy_novels_app/app/galaxy_novels_app.dart';
import 'package:galaxy_novels_app/data/models/chapter_summary.dart';
import 'package:galaxy_novels_app/data/models/home_data.dart';
import 'package:galaxy_novels_app/data/models/novel_details_data.dart';
import 'package:galaxy_novels_app/data/models/reader_content_data.dart';
import 'package:galaxy_novels_app/data/models/reading_progress.dart'
    as local_progress;
import 'package:galaxy_novels_app/data/repositories/fake_catalog_repository.dart';
import 'package:galaxy_novels_app/data/repositories/fake_novel_repository.dart';
import 'package:galaxy_novels_app/data/repositories/fake_rankings_repository.dart';
import 'package:galaxy_novels_app/data/repositories/fake_search_repository.dart';
import 'package:galaxy_novels_app/data/repositories/home_repository.dart';
import 'package:galaxy_novels_app/data/repositories/novel_repository.dart';
import 'package:galaxy_novels_app/data/repositories/reader_repository.dart';
import 'package:galaxy_novels_app/data/repositories/reading_history_repository.dart';
import 'package:galaxy_novels_app/features/comments/presentation/chapter_comments_sheet.dart';
import 'package:galaxy_novels_app/features/novel_details/presentation/novel_details_screen.dart';
import 'package:galaxy_novels_app/features/reader/presentation/reader_screen.dart';
import 'package:galaxy_novels_app/features/vip/presentation/vip_access_notice.dart';

import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_comments_repository.dart';
import '../../helpers/fake_favorites_repository.dart';
import '../../helpers/fake_novel_engagement_repository.dart';
import '../../helpers/fake_reader_preferences_repository.dart';
import '../../helpers/fake_vip_repository.dart';

void main() {
  final variants = <({String name, AppThemeChoice theme, Size size})>[
    for (final theme in const [
      AppThemeChoice.galaxyNoir,
      AppThemeChoice.starlightPaper,
    ])
      for (final size in const [
        Size(320, 900),
        Size(600, 900),
        Size(840, 1000),
      ])
        (name: '${theme.name}-${size.width.toInt()}', theme: theme, size: size),
  ];

  for (final variant in variants) {
    testWidgets('guest reading journey is responsive in ${variant.name}', (
      tester,
    ) async {
      final harness = await _pumpApp(
        tester,
        size: variant.size,
        theme: variant.theme,
        textScaleFactor: variant.size.width == 320 ? 2 : 1,
      );

      await _openLatestDetails(tester);
      expect(find.byType(NovelDetailsScreen), findsOneWidget);
      expect(find.byKey(const ValueKey('login-submit')), findsNothing);
      final readAction = find.byKey(
        const ValueKey('novel-details-read-action'),
      );
      await tester.scrollUntilVisible(
        readAction,
        320,
        scrollable: _detailsScrollable(),
      );
      await tester.pumpAndSettle();
      _expectMinimumTarget(tester, readAction);
      expect(
        find.byKey(const ValueKey('novel-details-download-action')),
        findsNothing,
      );

      await tester.scrollUntilVisible(
        find.byType(VipAccessNotice),
        320,
        scrollable: _detailsScrollable(),
      );
      await tester.pumpAndSettle();
      expect(find.byType(VipAccessNotice), findsOneWidget);
      expect(find.text('فصول VIP مقفلة'), findsOneWidget);
      expect(find.byKey(const ValueKey('login-submit')), findsNothing);

      await tester.scrollUntilVisible(
        readAction,
        -320,
        scrollable: _detailsScrollable(),
      );
      await tester.pumpAndSettle();
      await tester.tap(readAction);
      await tester.pumpAndSettle();
      expect(find.byType(ReaderScreen), findsOneWidget);
      expect(find.text('نص رحلة القراءة'), findsOneWidget);

      final readerState = tester.state(
        find.byType(ReaderScreen, skipOffstage: false),
      );
      await tester.tap(find.byKey(const ValueKey('reader-content-tap-area')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('reader-floating-pill')),
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
      final commentsButton = find.byKey(
        const ValueKey('reader-comments-button'),
      );
      _expectMinimumTarget(tester, commentsButton);
      await tester.tap(commentsButton);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('chapter-comments-sheet')),
        findsOneWidget,
      );
      expect(find.byType(ChapterCommentsSheet), findsOneWidget);
      expect(harness.commentsRepository.calls, hasLength(1));
      expect(
        identical(
          tester.state(find.byType(ReaderScreen, skipOffstage: false)),
          readerState,
        ),
        isTrue,
      );
      expect(find.byKey(const ValueKey('login-submit')), findsNothing);
      _expectMinimumTarget(tester, find.byTooltip('إغلاق تعليقات الفصل'));

      await tester.tap(find.byTooltip('إغلاق تعليقات الفصل'));
      await tester.pumpAndSettle();
      expect(find.byType(ReaderScreen), findsOneWidget);
      _expectHealthySurface(tester);
    });
  }

  testWidgets('reader remains usable in landscape without an auth gate', (
    tester,
  ) async {
    await _pumpApp(
      tester,
      size: const Size(840, 360),
      theme: AppThemeChoice.galaxyNoir,
    );

    await _openLatestDetails(tester);
    final readAction = find.byKey(const ValueKey('novel-details-read-action'));
    await tester.scrollUntilVisible(
      readAction,
      240,
      scrollable: _detailsScrollable(),
    );
    await tester.pumpAndSettle();
    await tester.tap(readAction);
    await tester.pumpAndSettle();

    expect(find.byType(ReaderScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('login-submit')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('reader-content-tap-area')));
    await tester.pumpAndSettle();
    _expectMinimumTarget(
      tester,
      find.byKey(const ValueKey('reader-comments-button')),
    );
    _expectHealthySurface(tester);
  });
}

Future<_Phase3Harness> _pumpApp(
  WidgetTester tester, {
  required Size size,
  required AppThemeChoice theme,
  double textScaleFactor = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScaleFactor;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    tester.platformDispatcher.clearTextScaleFactorTestValue();
  });

  final authRepository = FakeAuthRepository();
  final commentsRepository = FakeCommentsRepository.empty();
  final historyRepository = _MemoryReadingHistoryRepository();
  final preferencesRepository = FakeReaderPreferencesRepository();
  final themeController = _FixedThemeController(theme);
  addTearDown(authRepository.dispose);
  addTearDown(historyRepository.dispose);
  addTearDown(preferencesRepository.dispose);
  addTearDown(themeController.dispose);

  await tester.pumpWidget(
    GalaxyNovelsApp(
      homeRepository: const _Phase3HomeRepository(),
      catalogRepository: const FakeCatalogRepository(),
      novelRepository: const FakeNovelRepository(result: _novelResult),
      readerRepository: const _Phase3ReaderRepository(),
      rankingsRepository: const FakeRankingsRepository(),
      searchRepository: const FakeSearchRepository(),
      readingHistoryRepository: historyRepository,
      readerPreferencesRepository: preferencesRepository,
      authRepository: authRepository,
      commentsRepository: commentsRepository,
      favoritesRepository: FakeFavoritesRepository(),
      novelEngagementRepository: FakeNovelEngagementRepository(),
      vipRepository: const FakeVipRepository(),
      appThemeController: themeController,
    ),
  );
  await tester.pumpAndSettle();

  expect(find.byKey(const ValueKey('login-submit')), findsNothing);
  _expectHealthySurface(tester);
  return _Phase3Harness(commentsRepository: commentsRepository);
}

Future<void> _openLatestDetails(WidgetTester tester) async {
  final latest = find.byKey(const ValueKey('latest-update-10'));
  final homeScroll = find.descendant(
    of: find.byKey(const ValueKey('home-scroll-view')),
    matching: find.byType(Scrollable),
  );
  await tester.scrollUntilVisible(latest, 360, scrollable: homeScroll.first);
  await tester.ensureVisible(latest);
  _expectMinimumTarget(tester, latest);
  await tester.tap(latest);
  await tester.pumpAndSettle();
}

Finder _detailsScrollable() {
  return find
      .descendant(
        of: find.byKey(const ValueKey('novel-details-content-column')),
        matching: find.byType(Scrollable),
      )
      .first;
}

void _expectMinimumTarget(WidgetTester tester, Finder finder) {
  expect(finder.hitTestable(), findsOneWidget);
  final size = tester.getSize(finder.hitTestable());
  expect(size.width, greaterThanOrEqualTo(44));
  expect(size.height, greaterThanOrEqualTo(44));
}

void _expectHealthySurface(WidgetTester tester) {
  expect(find.textContaining('Exception', findRichText: true), findsNothing);
  expect(find.textContaining('StateError', findRichText: true), findsNothing);
  expect(tester.takeException(), isNull);
}

class _Phase3Harness {
  const _Phase3Harness({required this.commentsRepository});

  final FakeCommentsRepository commentsRepository;
}

class _FixedThemeController extends ChangeNotifier
    implements AppThemeController {
  _FixedThemeController(this._value);

  AppThemeChoice _value;

  @override
  AppThemeChoice get value => _value;

  @override
  Future<void> load() async {}

  @override
  Future<void> update(AppThemeChoice choice) async {
    if (_value == choice) {
      return;
    }
    _value = choice;
    notifyListeners();
  }
}

class _MemoryReadingHistoryRepository extends ChangeNotifier
    implements ReadingHistoryRepository {
  final List<local_progress.ReadingProgress> _items = [];

  @override
  Future<List<local_progress.ReadingProgress>> load() async =>
      List.unmodifiable(_items);

  @override
  Future<void> record(local_progress.ReadingProgress progress) async {
    _items
      ..removeWhere((item) => item.novelId == progress.novelId)
      ..insert(0, progress);
    notifyListeners();
  }
}

class _Phase3HomeRepository implements HomeRepository {
  const _Phase3HomeRepository();

  @override
  Future<HomeData> loadHome() async => _homeData;
}

class _Phase3ReaderRepository implements ReaderRepository {
  const _Phase3ReaderRepository();

  @override
  Future<ReaderChapterContent> loadChapter(String contentApi) async {
    return const ReaderChapterContent(
      id: 10,
      novelId: 7,
      label: 'الفصل 10',
      title: 'البداية الهادئة',
      displayTitle: 'الفصل 10: البداية الهادئة',
      position: 10,
      total: 40,
      contentHtml:
          '<p>نص رحلة القراءة</p><p>تستمر الرحلة بين النجوم بهدوء.</p>',
      navigation: ReaderChapterNavigation(
        previousApi: '',
        nextApi: '',
        previousId: 0,
        nextId: 0,
      ),
    );
  }
}

const _homeData = HomeData(
  continueReading: null,
  latestChapters: [
    ChapterSummary(
      id: 10,
      novelId: 7,
      novelTitle: 'رواية رحلة المرحلة الثالثة',
      label: 'الفصل 10',
      title: 'البداية الهادئة',
      dateLabel: 'الآن',
      url: '/novels/phase-3/chapter-10',
      contentApi: '/api/chapters/10',
      manifest: '/manifest/novel-7.json',
    ),
  ],
  recentNovels: [],
);

const _novelResult = NovelDetailsLoadResult(
  details: NovelDetails(
    id: 7,
    title: 'رواية رحلة المرحلة الثالثة',
    originalTitle: 'Phase Three Journey',
    url: '/novels/phase-3',
    coverThumbnail: '',
    coverMedium: '',
    coverLarge: '',
    statusKey: 'ongoing',
    statusLabel: 'مستمرة',
    country: 'cn',
    author: 'كاتب الاختبار',
    translator: '',
    genres: [NovelGenre(id: 1, name: 'خيال', slug: 'fantasy')],
    chaptersCount: 40,
    firstChapterId: 10,
    firstChapterUrl: '/novels/phase-3/chapter-10',
    ratingAverage: 4.7,
    ratingCount: 120,
    views: 4000,
    updatedAt: null,
    summary: 'رحلة اختبار متكاملة لأسطح القراءة.',
    chaptersManifest: '/manifest/novel-7-chapters.json',
    vipScheduleManifest: '/manifest/novel-7-vip.json',
    manifest: '/manifest/novel-7.json',
  ),
  chapters: [
    NovelChapter(
      id: 10,
      position: 10,
      number: '10',
      label: 'الفصل 10',
      title: 'البداية الهادئة',
      url: '/novels/phase-3/chapter-10',
      contentApi: '/api/chapters/10',
      dateLabel: 'اليوم',
      dateIso: null,
      views: 10,
      comments: 0,
      search: 'الفصل 10 البداية الهادئة',
    ),
  ],
);
