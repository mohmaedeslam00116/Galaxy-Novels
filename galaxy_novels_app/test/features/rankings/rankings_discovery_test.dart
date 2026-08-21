import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/app/app_dependencies.dart';
import 'package:galaxy_novels_app/app/app_theme.dart';
import 'package:galaxy_novels_app/core/config/app_config.dart';
import 'package:galaxy_novels_app/data/models/catalog_data.dart';
import 'package:galaxy_novels_app/data/models/novel_details_data.dart';
import 'package:galaxy_novels_app/data/models/rankings_data.dart';
import 'package:galaxy_novels_app/data/models/reader_content_data.dart';
import 'package:galaxy_novels_app/data/models/reading_progress.dart';
import 'package:galaxy_novels_app/data/repositories/fake_catalog_repository.dart';
import 'package:galaxy_novels_app/data/repositories/fake_home_repository.dart';
import 'package:galaxy_novels_app/data/repositories/fake_novel_repository.dart';
import 'package:galaxy_novels_app/data/repositories/fake_search_repository.dart';
import 'package:galaxy_novels_app/data/repositories/novel_repository.dart';
import 'package:galaxy_novels_app/data/repositories/rankings_repository.dart';
import 'package:galaxy_novels_app/data/repositories/reader_repository.dart';
import 'package:galaxy_novels_app/data/repositories/reading_history_repository.dart';
import 'package:galaxy_novels_app/features/novel_details/presentation/novel_details_screen.dart';
import 'package:galaxy_novels_app/features/rankings/presentation/rankings_screen.dart';
import 'package:galaxy_novels_app/features/rankings/presentation/widgets/ranking_formatters.dart';
import 'package:galaxy_novels_app/shared/widgets/app_async_state.dart';
import 'package:galaxy_novels_app/shared/widgets/app_empty_state.dart';
import 'package:galaxy_novels_app/shared/widgets/app_skeleton.dart';

import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_comments_repository.dart';
import '../../helpers/fake_favorites_repository.dart';
import '../../helpers/fake_novel_engagement_repository.dart';
import '../../helpers/fake_reader_preferences_repository.dart';
import '../../helpers/fake_vip_repository.dart';

void main() {
  test('ranking semantic label contains only approved metrics', () {
    final label = rankingSemanticLabel(_rankings.items.first, 1);

    expect(label, 'الأولى، الترتيب 1، 1.5K مشاهدة، التقييم 4.8 من 5');
    expect(label, isNot(contains('فصل')));
  });

  testWidgets('rankings loading mirrors the compact content structure', (
    tester,
  ) async {
    final pending = Completer<RankingsData>();
    addTearDown(() {
      if (!pending.isCompleted) {
        pending.complete(const RankingsData(period: 'month', items: []));
      }
    });
    await _pumpRankings(
      tester,
      repository: _CallbackRankingsRepository((_) => pending.future),
    );

    expect(
      find.byKey(const ValueKey('rankings-loading-state')),
      findsOneWidget,
    );
    expect(find.byType(AppSkeleton), findsNWidgets(5));
    expect(find.text('جار تحميل الترتيب...'), findsNothing);
  });

  testWidgets('rankings empty response uses the shared empty state', (
    tester,
  ) async {
    await _pumpRankings(
      tester,
      repository: _CallbackRankingsRepository(
        (_) async => const RankingsData(period: 'month', items: []),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AppEmptyState), findsOneWidget);
    expect(find.text('لا توجد روايات في الترتيب الآن'), findsOneWidget);
  });

  testWidgets('rankings retry is safe, accessible, and recovers', (
    tester,
  ) async {
    final repository = _CallbackRankingsRepository((call) async {
      if (call == 1) {
        throw const FormatException('raw rankings payload');
      }
      return _rankings;
    });
    await _pumpRankings(tester, repository: repository);
    await tester.pumpAndSettle();

    expect(find.byType(AppAsyncState), findsOneWidget);
    expect(find.text('تعذر تحميل الترتيب الآن'), findsOneWidget);
    expect(find.textContaining('raw rankings payload'), findsNothing);
    final retry = find.byKey(const ValueKey('app-async-retry'));
    expect(tester.getSize(retry).height, greaterThanOrEqualTo(44));

    await tester.tap(retry);
    await tester.pumpAndSettle();

    expect(repository.callCount, 2);
    expect(find.text('تعذر تحميل الترتيب الآن'), findsNothing);
    expect(find.byKey(const ValueKey('ranking-top-pick-1')), findsOneWidget);
  });

  testWidgets('rankings show compact header and source-order podium', (
    tester,
  ) async {
    await _pumpLoadedRankings(tester, size: const Size(960, 1000));

    expect(find.text('ترتيب الروايات'), findsOneWidget);
    expect(find.text('هذا الشهر'), findsOneWidget);
    expect(find.text('الأعلى مشاهدة داخل المجرة'), findsOneWidget);
    expect(find.text('إحصاء الروايات'), findsNothing);
    expect(
      find.byKey(const ValueKey('rankings-podium-horizontal')),
      findsOneWidget,
    );
    for (var rank = 1; rank <= 3; rank += 1) {
      expect(find.byKey(ValueKey('ranking-top-pick-$rank')), findsOneWidget);
    }
    expect(find.byKey(const ValueKey('ranking-list-row-4')), findsOneWidget);
  });

  testWidgets('horizontal podium places first between second and third', (
    tester,
  ) async {
    await _pumpLoadedRankings(tester, size: const Size(390, 1000));

    final secondX = tester
        .getCenter(find.byKey(const ValueKey('ranking-top-pick-2')))
        .dx;
    final firstX = tester
        .getCenter(find.byKey(const ValueKey('ranking-top-pick-1')))
        .dx;
    final thirdX = tester
        .getCenter(find.byKey(const ValueKey('ranking-top-pick-3')))
        .dx;

    expect(secondX, greaterThan(firstX));
    expect(firstX, greaterThan(thirdX));
    expect(
      tester.getSize(find.byKey(const ValueKey('ranking-top-pick-1'))).height,
      greaterThan(
        tester.getSize(find.byKey(const ValueKey('ranking-top-pick-2'))).height,
      ),
    );
  });

  testWidgets('podium renders only available novels without empty places', (
    tester,
  ) async {
    await _pumpLoadedRankings(
      tester,
      rankings: RankingsData(
        period: _rankings.period,
        items: _rankings.items.take(2).toList(growable: false),
      ),
    );

    expect(find.byKey(const ValueKey('ranking-top-pick-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('ranking-top-pick-2')), findsOneWidget);
    expect(find.byKey(const ValueKey('ranking-top-pick-3')), findsNothing);
    expect(find.byKey(const ValueKey('rankings-table')), findsNothing);
  });

  testWidgets('ranking with an empty manifest stays disabled', (tester) async {
    await _pumpLoadedRankings(tester);
    await _revealTopRanking(tester, 2);

    await tester.tap(find.byKey(const ValueKey('ranking-top-pick-2')));
    await tester.pumpAndSettle();
    expect(find.byType(NovelDetailsScreen), findsNothing);
  });

  testWidgets(
    'top rankings expose complete metrics and interaction semantics',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await _pumpLoadedRankings(tester);

      final first = tester.getSemantics(
        find.bySemanticsLabel(
          'الأولى، الترتيب 1، 1.5K مشاهدة، التقييم 4.8 من 5',
        ),
      );
      expect(first.flagsCollection.isButton, isTrue);
      expect(first.flagsCollection.isEnabled, ui.Tristate.isTrue);
      expect(
        first.getSemanticsData().hasAction(ui.SemanticsAction.tap),
        isTrue,
      );

      await _revealTopRanking(tester, 2);
      final second = tester.getSemantics(
        find.bySemanticsLabel('الثانية، الترتيب 2، 1.2K مشاهدة'),
      );
      expect(second.flagsCollection.isButton, isTrue);
      expect(second.flagsCollection.isEnabled, ui.Tristate.isFalse);
      expect(
        second.getSemanticsData().hasAction(ui.SemanticsAction.tap),
        isFalse,
      );
      semantics.dispose();
    },
  );

  testWidgets('ranking with a manifest opens novel details', (tester) async {
    await _pumpLoadedRankings(tester);

    await tester.tap(find.byKey(const ValueKey('ranking-top-pick-1')));
    await tester.pumpAndSettle();
    expect(find.byType(NovelDetailsScreen), findsOneWidget);
  });

  testWidgets('rank four opens novel details from the lazy list', (
    tester,
  ) async {
    await _pumpLoadedRankings(tester);
    final row = find.byKey(const ValueKey('ranking-list-row-4'));
    await _revealRanking(tester, row);

    await tester.tap(row);
    await tester.pumpAndSettle();

    expect(find.byType(NovelDetailsScreen), findsOneWidget);
  });

  testWidgets('ranking list row exposes rank and all available metrics', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pumpLoadedRankings(tester);
    final row = find.byKey(const ValueKey('ranking-list-row-4'));
    await _revealRanking(tester, row);

    final rowSemantics = tester.getSemantics(
      find.bySemanticsLabel('الرابعة، الترتيب 4، 900 مشاهدة، التقييم 4.1 من 5'),
    );
    expect(rowSemantics.flagsCollection.isButton, isTrue);
    expect(rowSemantics.flagsCollection.isEnabled, ui.Tristate.isTrue);
    expect(
      rowSemantics.getSemanticsData().hasAction(ui.SemanticsAction.tap),
      isTrue,
    );
    semantics.dispose();
  });

  testWidgets('remaining ranks form one continuous bordered table', (
    tester,
  ) async {
    await _pumpLoadedRankings(tester, rankings: _rankingsWithEmptyListItem);
    final lastRow = find.byKey(const ValueKey('ranking-list-row-5'));
    await _revealRanking(tester, lastRow);

    expect(find.byKey(const ValueKey('rankings-table')), findsOneWidget);
    expect(find.byKey(const ValueKey('ranking-list-row-4')), findsOneWidget);
    expect(lastRow, findsOneWidget);
    expect(find.textContaining('44 فصل'), findsNothing);
    expect(find.textContaining('51 فصل'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('rankings remain overflow free in short landscape', (
    tester,
  ) async {
    await _pumpLoadedRankings(
      tester,
      rankings: _rankingsWithEmptyListItem,
      size: const Size(840, 420),
    );
    await _revealRanking(
      tester,
      find.byKey(const ValueKey('ranking-list-row-4')),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('list ranking with an empty manifest stays disabled', (
    tester,
  ) async {
    await _pumpLoadedRankings(tester, rankings: _rankingsWithEmptyListItem);
    final row = find.byKey(const ValueKey('ranking-list-row-5'));
    await _revealRanking(tester, row);
    await tester.tap(row);
    await tester.pumpAndSettle();
    expect(find.byType(NovelDetailsScreen), findsNothing);
  });

  testWidgets('normal narrow rankings keep the horizontal podium', (
    tester,
  ) async {
    await _pumpLoadedRankings(tester, size: const Size(320, 1000));

    final screenContext = tester.element(find.byType(RankingsScreen));
    expect(Directionality.of(screenContext), TextDirection.rtl);
    expect(
      find.byKey(const ValueKey('rankings-podium-horizontal')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('podium switches to vertical medals at 200 percent text', (
    tester,
  ) async {
    await _pumpLoadedRankings(
      tester,
      size: const Size(320, 1200),
      textScaler: const TextScaler.linear(2),
    );

    expect(
      find.byKey(const ValueKey('rankings-podium-vertical')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('rankings-podium-horizontal')),
      findsNothing,
    );
    final clippedTexts = <String?>[];
    for (final textElement in find.byType(Text).evaluate()) {
      final renderObject = textElement.renderObject;
      final label = (textElement.widget as Text).data;
      if (label != 'غلاف' &&
          renderObject is RenderParagraph &&
          renderObject.didExceedMaxLines) {
        clippedTexts.add(label);
      }
    }
    expect(clippedTexts, isEmpty, reason: 'clipped texts: $clippedTexts');
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpLoadedRankings(
  WidgetTester tester, {
  Size size = const Size(390, 1000),
  TextScaler textScaler = TextScaler.noScaling,
  RankingsData rankings = _rankings,
}) async {
  await _pumpRankings(
    tester,
    repository: _CallbackRankingsRepository((_) async => rankings),
    size: size,
    textScaler: textScaler,
  );
  await tester.pumpAndSettle();
}

Future<void> _revealRanking(WidgetTester tester, Finder target) async {
  await tester.scrollUntilVisible(
    target,
    300,
    scrollable: find
        .descendant(
          of: find.byKey(const ValueKey('rankings-scroll-view')),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tester.pumpAndSettle();
}

Future<void> _revealTopRanking(WidgetTester tester, int rank) async {
  final target = find.byKey(ValueKey('ranking-top-pick-$rank'));
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  expect(target, findsOneWidget);
}

Future<void> _pumpRankings(
  WidgetTester tester, {
  required RankingsRepository repository,
  Size size = const Size(390, 1000),
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    _RankingsTestApp(
      repository: repository,
      size: size,
      textScaler: textScaler,
    ),
  );
}

class _RankingsTestApp extends StatelessWidget {
  const _RankingsTestApp({
    required this.repository,
    required this.size,
    required this.textScaler,
  });

  final RankingsRepository repository;
  final Size size;
  final TextScaler textScaler;

  @override
  Widget build(BuildContext context) {
    return AppDependencies(
      config: const AppConfig(),
      homeRepository: const FakeHomeRepository(),
      catalogRepository: const FakeCatalogRepository(),
      novelRepository: const FakeNovelRepository(result: _novelDetails),
      readerRepository: const _TestReaderRepository(),
      rankingsRepository: repository,
      searchRepository: const FakeSearchRepository(),
      readingHistoryRepository: const _TestReadingHistoryRepository(),
      readerPreferencesRepository: FakeReaderPreferencesRepository(),
      authRepository: FakeAuthRepository(),
      commentsRepository: FakeCommentsRepository.empty(),
      favoritesRepository: FakeFavoritesRepository(),
      novelEngagementRepository: FakeNovelEngagementRepository(),
      vipRepository: const FakeVipRepository(),
      child: MaterialApp(
        locale: const Locale('ar'),
        theme: AppTheme.dark(),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: MediaQuery(
            data: MediaQueryData(size: size, textScaler: textScaler),
            child: const Scaffold(body: RankingsScreen()),
          ),
        ),
      ),
    );
  }
}

class _CallbackRankingsRepository implements RankingsRepository {
  _CallbackRankingsRepository(this._load);

  final Future<RankingsData> Function(int call) _load;
  int callCount = 0;

  @override
  Future<RankingsData> loadRankings() {
    callCount += 1;
    return _load(callCount);
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

const _rankings = RankingsData(
  period: 'month',
  items: [
    CatalogNovel(
      id: 1,
      title: 'الأولى',
      originalTitle: '',
      url: '/first/',
      coverThumbnail: '',
      coverMedium: '',
      statusKey: 'ongoing',
      statusLabel: 'مستمرة',
      genres: [CatalogGenre(id: 1, name: 'خيال', slug: 'fantasy')],
      chaptersCount: 12,
      ratingAverage: 4.8,
      ratingCount: 12,
      views: 1500,
      updatedAt: null,
      manifest: '/manifest/first.json',
    ),
    CatalogNovel(
      id: 2,
      title: 'الثانية',
      originalTitle: '',
      url: '/second/',
      coverThumbnail: '',
      coverMedium: '',
      statusKey: 'ongoing',
      statusLabel: 'مستمرة',
      genres: [CatalogGenre(id: 2, name: 'أكشن', slug: 'action')],
      chaptersCount: 23,
      ratingAverage: 0,
      ratingCount: 0,
      views: 1200,
      updatedAt: null,
      manifest: '',
    ),
    CatalogNovel(
      id: 3,
      title: 'الثالثة',
      originalTitle: '',
      url: '/third/',
      coverThumbnail: '',
      coverMedium: '',
      statusKey: 'completed',
      statusLabel: 'مكتملة',
      genres: [CatalogGenre(id: 3, name: 'دراما', slug: 'drama')],
      chaptersCount: 31,
      ratingAverage: 4.4,
      ratingCount: 8,
      views: 1000,
      updatedAt: null,
      manifest: '/manifest/third.json',
    ),
    CatalogNovel(
      id: 4,
      title: 'الرابعة',
      originalTitle: '',
      url: '/fourth/',
      coverThumbnail: '',
      coverMedium: '',
      statusKey: 'ongoing',
      statusLabel: 'مستمرة',
      genres: [CatalogGenre(id: 4, name: 'مغامرة', slug: 'adventure')],
      chaptersCount: 44,
      ratingAverage: 4.1,
      ratingCount: 4,
      views: 900,
      updatedAt: null,
      manifest: '/manifest/fourth.json',
    ),
  ],
);

final _rankingsWithEmptyListItem = RankingsData(
  period: 'month',
  items: List.unmodifiable([
    ..._rankings.items,
    const CatalogNovel(
      id: 5,
      title: 'الخامسة',
      originalTitle: '',
      url: '/fifth/',
      coverThumbnail: '',
      coverMedium: '',
      statusKey: 'ongoing',
      statusLabel: 'مستمرة',
      genres: [CatalogGenre(id: 5, name: 'غموض', slug: 'mystery')],
      chaptersCount: 51,
      ratingAverage: 4.0,
      ratingCount: 2,
      views: 800,
      updatedAt: null,
      manifest: '',
    ),
  ]),
);

const _novelDetails = NovelDetailsLoadResult(
  details: NovelDetails(
    id: 1,
    title: 'تفاصيل الأولى',
    originalTitle: '',
    url: '/first/',
    coverThumbnail: '',
    coverMedium: '',
    coverLarge: '',
    statusKey: 'ongoing',
    statusLabel: 'مستمرة',
    country: '',
    author: '',
    translator: '',
    genres: [],
    chaptersCount: 0,
    firstChapterId: 0,
    firstChapterUrl: '',
    ratingAverage: 4.8,
    ratingCount: 12,
    views: 1500,
    updatedAt: null,
    summary: '',
    chaptersManifest: '',
    vipScheduleManifest: '',
    manifest: '/manifest/first.json',
  ),
  chapters: [],
);
