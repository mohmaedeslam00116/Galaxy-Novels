import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/app/app_dependencies.dart';
import 'package:galaxy_novels_app/app/app_theme.dart';
import 'package:galaxy_novels_app/core/config/app_config.dart';
import 'package:galaxy_novels_app/data/models/novel_details_data.dart';
import 'package:galaxy_novels_app/data/models/reader_content_data.dart';
import 'package:galaxy_novels_app/data/models/reading_progress.dart';
import 'package:galaxy_novels_app/data/repositories/fake_catalog_repository.dart';
import 'package:galaxy_novels_app/data/repositories/fake_home_repository.dart';
import 'package:galaxy_novels_app/data/repositories/fake_novel_repository.dart';
import 'package:galaxy_novels_app/data/repositories/fake_rankings_repository.dart';
import 'package:galaxy_novels_app/data/repositories/fake_search_repository.dart';
import 'package:galaxy_novels_app/data/repositories/novel_repository.dart';
import 'package:galaxy_novels_app/data/repositories/reader_repository.dart';
import 'package:galaxy_novels_app/data/repositories/reading_history_repository.dart';
import 'package:galaxy_novels_app/features/novel_details/presentation/widgets/novel_details_content.dart';
import 'package:galaxy_novels_app/features/novel_engagement/application/novel_engagement_controller.dart';
import 'package:galaxy_novels_app/features/vip/application/vip_chapters_controller.dart';
import 'package:galaxy_novels_app/shared/widgets/novel_cover.dart';

import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_comments_repository.dart';
import '../../helpers/fake_favorites_repository.dart';
import '../../helpers/fake_novel_engagement_repository.dart';
import '../../helpers/fake_reader_preferences_repository.dart';
import '../../helpers/fake_vip_repository.dart';

void main() {
  for (final size in const [Size(320, 720), Size(600, 900), Size(840, 1000)]) {
    testWidgets('renders the scrollable Stitch structure at $size', (
      tester,
    ) async {
      await _pumpDetails(tester, size: size);

      final header = find.byKey(const ValueKey('novel-details-hero'));
      final coverSize = tester.getSize(
        find.descendant(of: header, matching: find.byType(NovelCover)),
      );
      expect(coverSize.width, inInclusiveRange(176, 224));
      expect(
        find.byKey(const ValueKey('novel-details-collapsing-bar')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('novel-details-metadata-table')),
        findsOneWidget,
      );
      expect(
        find.byKey(
          ValueKey(
            size.width >= 840
                ? 'galaxy-details-expanded-header'
                : 'galaxy-details-centered-header',
          ),
        ),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('novel-details-read-action')),
        240,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();
      _expectAccessibleAction(
        tester,
        const ValueKey('novel-details-read-action'),
        size.height,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('keeps Stitch details usable at 200 percent text', (
    tester,
  ) async {
    const size = Size(320, 720);
    await _pumpDetails(
      tester,
      size: size,
      textScaler: const TextScaler.linear(2),
    );

    expect(
      find.byKey(const ValueKey('novel-details-metadata-table')),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('novel-details-read-action')),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    _expectAccessibleAction(
      tester,
      const ValueKey('novel-details-read-action'),
      size.height,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('uses the wider two-column details canvas on expanded screens', (
    tester,
  ) async {
    await _pumpDetails(tester, size: const Size(840, 1000));

    final width = tester
        .getSize(find.byKey(const ValueKey('novel-details-content-column')))
        .width;
    expect(width, greaterThan(768));
    expect(width, lessThanOrEqualTo(1120));
    expect(
      find.byKey(const ValueKey('galaxy-details-expanded-header')),
      findsOneWidget,
    );
  });

  testWidgets('shows summary and two detail tabs with chapters selected', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await _pumpDetails(tester, size: const Size(320, 720));
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('novel-section-chapters')),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('novel-section-overview')), findsNothing);
    expect(
      find.byKey(const ValueKey('novel-details-summary-card')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('novel-section-chapters')),
        matching: find.text('الفصول'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('novel-section-comments')),
        matching: find.text('التعليقات'),
      ),
      findsOneWidget,
    );

    final chapters = find.byKey(const ValueKey('novel-section-chapters'));
    expect(chapters, findsOneWidget);
    expect(
      tester.getSemantics(chapters).flagsCollection.isSelected,
      ui.Tristate.isTrue,
    );
    semantics.dispose();
  });

  testWidgets('selected semantics follows the active details tab', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pumpDetails(tester, size: const Size(600, 900));

    final chaptersTab = find.byKey(const ValueKey('novel-section-chapters'));
    final commentsTab = find.byKey(const ValueKey('novel-section-comments'));
    await tester.scrollUntilVisible(
      chaptersTab,
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();

    final tabs = [chaptersTab, commentsTab];
    _expectTabActions(tester, tabs);
    expect(
      tester.getSemantics(chaptersTab).flagsCollection.isSelected,
      ui.Tristate.isTrue,
    );

    await tester.tap(commentsTab);
    await tester.pumpAndSettle();
    expect(
      tester.getSemantics(commentsTab).flagsCollection.isSelected,
      ui.Tristate.isTrue,
    );
    _expectTabActions(tester, tabs);
    semantics.dispose();
  });

  testWidgets('comments stay lazy until the comments tab is selected', (
    tester,
  ) async {
    final commentsRepository = FakeCommentsRepository.empty();
    await _pumpDetails(
      tester,
      size: const Size(600, 900),
      commentsRepository: commentsRepository,
    );

    expect(commentsRepository.calls, isEmpty);
    final comments = find.bySemanticsLabel('التعليقات');
    await tester.scrollUntilVisible(
      comments,
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    await tester.tap(comments);
    await tester.pumpAndSettle();

    expect(commentsRepository.calls, hasLength(1));
  });

  testWidgets('legacy download action stays absent without chapters', (
    tester,
  ) async {
    await _pumpDetails(
      tester,
      size: const Size(320, 720),
      loadResult: _emptyChaptersLoadResult,
    );

    expect(
      find.byKey(const ValueKey('novel-details-download-action')),
      findsNothing,
    );
  });

  testWidgets('chapter failures hide raw errors behind fixed Arabic copy', (
    tester,
  ) async {
    await _pumpDetails(
      tester,
      size: const Size(600, 900),
      loadResult: _chaptersErrorLoadResult,
    );

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('novel-section-chapters')),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();

    expect(
      find.text('تعذر تحميل الفصول الآن. أعد المحاولة بعد قليل.'),
      findsOneWidget,
    );
    expect(find.text(_rawChaptersError), findsNothing);
  });

  for (final themeCase in [
    (name: 'galaxy noir', theme: AppTheme.dark()),
    (name: 'neutral dark', theme: AppTheme.neutralDarkTheme()),
    (name: 'cosmic night', theme: AppTheme.cosmicNightTheme()),
    (name: 'starlight paper', theme: AppTheme.light()),
    (name: 'light nature', theme: AppTheme.lightNatureTheme()),
  ]) {
    testWidgets('renders the new hierarchy in ${themeCase.name}', (
      tester,
    ) async {
      await _pumpDetails(
        tester,
        size: const Size(600, 900),
        theme: themeCase.theme,
      );

      expect(find.byKey(const ValueKey('novel-details-hero')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('novel-details-rating-action')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }
}

void _expectAccessibleAction(
  WidgetTester tester,
  Key key,
  double viewportHeight,
) {
  final finder = find.byKey(key);
  expect(finder, findsOneWidget);
  final size = tester.getSize(finder);
  expect(size.width, greaterThanOrEqualTo(44));
  expect(size.height, greaterThanOrEqualTo(44));
  expect(finder.hitTestable(), findsOneWidget);
  expect(tester.getRect(finder).bottom, lessThanOrEqualTo(viewportHeight));
}

void _expectTabActions(WidgetTester tester, List<Finder> tabs) {
  for (final tab in tabs) {
    final tabSemantics = tester.getSemantics(tab);
    expect(tabSemantics.flagsCollection.isButton, isTrue);
    expect(
      tabSemantics.getSemanticsData().hasAction(ui.SemanticsAction.tap),
      isTrue,
    );
  }
}

Future<void> _pumpDetails(
  WidgetTester tester, {
  required Size size,
  TextScaler textScaler = TextScaler.noScaling,
  NovelDetailsLoadResult loadResult = _loadResult,
  FakeCommentsRepository? commentsRepository,
  ThemeData? theme,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  final authRepository = FakeAuthRepository();
  final resolvedCommentsRepository =
      commentsRepository ?? FakeCommentsRepository.empty();
  final vipRepository = const FakeVipRepository();
  final vipController = VipChaptersController(
    repository: vipRepository,
    novelId: loadResult.details.id,
  );
  addTearDown(vipController.dispose);

  await tester.pumpWidget(
    AppDependencies(
      config: const AppConfig(),
      homeRepository: const FakeHomeRepository(),
      catalogRepository: const FakeCatalogRepository(),
      novelRepository: FakeNovelRepository(result: loadResult),
      readerRepository: const _UnusedReaderRepository(),
      rankingsRepository: const FakeRankingsRepository(),
      searchRepository: const FakeSearchRepository(),
      readingHistoryRepository: const _UnusedReadingHistoryRepository(),
      readerPreferencesRepository: FakeReaderPreferencesRepository(),
      authRepository: authRepository,
      commentsRepository: resolvedCommentsRepository,
      favoritesRepository: FakeFavoritesRepository(),
      novelEngagementRepository: FakeNovelEngagementRepository(),
      vipRepository: vipRepository,
      child: MaterialApp(
        locale: const Locale('ar'),
        theme: theme,
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: textScaler),
            child: child!,
          );
        },
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: NovelDetailsContent(
              loadResult: loadResult,
              engagementState: const NovelEngagementState(
                status: NovelEngagementStatus.guest,
                novelId: 42,
              ),
              commentsRepository: resolvedCommentsRepository,
              authRepository: authRepository,
              vipController: vipController,
              isVipNativeReaderAvailable: true,
              onRead: (_, _) {},
              onOpenVipChapter: (_, _) {},
              onRate: () {},
              onSignIn: () {},
              onRetryEngagement: () {},
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

const _loadResult = NovelDetailsLoadResult(
  details: NovelDetails(
    id: 42,
    title: 'رواية الاختبار',
    originalTitle: '',
    url: '/novels/test',
    coverThumbnail: '',
    coverMedium: '',
    coverLarge: '',
    statusKey: 'ongoing',
    statusLabel: 'مستمرة',
    country: '',
    author: 'كاتب الاختبار',
    translator: '',
    genres: [NovelGenre(id: 1, name: 'خيال', slug: 'fantasy')],
    chaptersCount: 2,
    firstChapterId: 1,
    firstChapterUrl: '/chapters/1',
    ratingAverage: 4.5,
    ratingCount: 10,
    views: 100,
    updatedAt: null,
    summary: 'نبذة قصيرة عن رواية الاختبار.',
    chaptersManifest: '/novels/test/chapters.json',
    vipScheduleManifest: '',
    manifest: '/novels/test.json',
  ),
  chapters: [
    NovelChapter(
      id: 1,
      position: 1,
      number: '1',
      label: 'الفصل 1',
      title: 'البداية',
      url: '/chapters/1',
      contentApi: '/api/chapters/1',
      dateLabel: 'اليوم',
      dateIso: null,
      views: 10,
      comments: 0,
      search: 'الفصل 1 البداية',
    ),
    NovelChapter(
      id: 2,
      position: 2,
      number: '2',
      label: 'الفصل 2',
      title: 'المتابعة',
      url: '/chapters/2',
      contentApi: '/api/chapters/2',
      dateLabel: 'اليوم',
      dateIso: null,
      views: 8,
      comments: 0,
      search: 'الفصل 2 المتابعة',
    ),
  ],
);

const _rawChaptersError = 'SocketException: private upstream host';

final _chaptersErrorLoadResult = NovelDetailsLoadResult(
  details: _loadResult.details,
  chapters: const [],
  chaptersError: _rawChaptersError,
);

final _emptyChaptersLoadResult = NovelDetailsLoadResult(
  details: _loadResult.details,
  chapters: const [],
);

class _UnusedReaderRepository implements ReaderRepository {
  const _UnusedReaderRepository();

  @override
  Future<ReaderChapterContent> loadChapter(String contentApi) {
    throw UnimplementedError();
  }
}

class _UnusedReadingHistoryRepository implements ReadingHistoryRepository {
  const _UnusedReadingHistoryRepository();

  @override
  void addListener(VoidCallback listener) {}

  @override
  Future<List<ReadingProgress>> load() async => const [];

  @override
  Future<void> record(ReadingProgress progress) async {}

  @override
  void removeListener(VoidCallback listener) {}
}
