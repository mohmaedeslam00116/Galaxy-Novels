import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/app/galaxy_novels_app.dart';
import 'package:galaxy_novels_app/data/models/chapter_summary.dart';
import 'package:galaxy_novels_app/data/models/home_data.dart';
import 'package:galaxy_novels_app/data/models/novel_details_data.dart';
import 'package:galaxy_novels_app/data/models/novel_summary.dart';
import 'package:galaxy_novels_app/data/models/reading_progress.dart'
    as local_progress;
import 'package:galaxy_novels_app/data/repositories/home_repository.dart';
import 'package:galaxy_novels_app/data/repositories/novel_repository.dart';
import 'package:galaxy_novels_app/data/repositories/reading_history_repository.dart';
import 'package:galaxy_novels_app/features/account/application/auth_repository.dart';
import 'package:galaxy_novels_app/features/account/domain/auth_session.dart';
import 'package:galaxy_novels_app/features/ads/application/home_ad_repository.dart';
import 'package:galaxy_novels_app/features/home/application/home_customization_repository.dart';
import 'package:galaxy_novels_app/features/home/domain/home_customization.dart';
import 'package:galaxy_novels_app/features/home/presentation/home_novel_cover.dart';
import 'package:galaxy_novels_app/features/novel_details/presentation/novel_details_screen.dart';
import 'package:galaxy_novels_app/features/home/presentation/latest_updates_section.dart';

import '../../helpers/fake_auth_repository.dart';

void main() {
  testWidgets('home uses a pinned expandable brand bar', (tester) async {
    await _pumpHome(tester, size: const Size(390, 844));

    final bar = tester.widget<SliverAppBar>(
      find.byKey(const ValueKey('home-sliver-app-bar')),
    );
    expect(bar.pinned, isTrue);
    expect(bar.toolbarHeight, 56);
    expect(bar.expandedHeight, 92);
    expect(find.text('مجرة الروايات'), findsOneWidget);
    expect(find.text('اكتشف روايتك التالية'), findsOneWidget);
    expect(find.byKey(const ValueKey('home-drawer-button')), findsOneWidget);
  });

  testWidgets('home presents the approved Stitch sections in order', (
    tester,
  ) async {
    await _pumpHome(tester, size: const Size(840, 3000));

    final sectionTops = [
      'home-continue-reading-header',
      'home-recent-header',
      'home-latest-header',
    ].map((key) => tester.getTopLeft(find.byKey(ValueKey(key))).dy).toList();

    expect(sectionTops, orderedEquals([...sectionTops]..sort()));
    expect(find.byKey(const ValueKey('home-featured-header')), findsNothing);
    expect(find.byKey(const ValueKey('home-rankings-section')), findsNothing);
  });

  testWidgets('home native ad follows the first available content section', (
    tester,
  ) async {
    await _pumpHome(
      tester,
      size: const Size(840, 3000),
      authRepository: FakeAuthRepository(
        initialState: const AuthSessionState.authenticated(_regularUser),
      ),
      homeAdRepository: const _TestHomeAdRepository(),
    );

    final continueTop = tester
        .getTopLeft(find.byKey(const ValueKey('home-continue-reading-header')))
        .dy;
    final adTop = tester
        .getTopLeft(find.byKey(const ValueKey('home-native-ad-slot')))
        .dy;
    final latestTop = tester
        .getTopLeft(find.byKey(const ValueKey('home-latest-header')))
        .dy;

    final recentTop = tester
        .getTopLeft(find.byKey(const ValueKey('home-recent-header')))
        .dy;

    expect(adTop, greaterThan(continueTop));
    expect(adTop, lessThan(recentTop));
    expect(latestTop, greaterThan(recentTop));
  });

  testWidgets('home obeys saved section order and visibility', (tester) async {
    final repository = _MemoryHomeCustomizationRepository(
      HomeCustomization.defaults.copyWith(
        sectionOrder: const [
          HomeSectionId.latestUpdates,
          HomeSectionId.updatedNovels,
          HomeSectionId.continueReading,
        ],
        hiddenSections: const {HomeSectionId.continueReading},
      ),
    );
    await _pumpHome(
      tester,
      size: const Size(840, 3000),
      homeCustomizationRepository: repository,
      authRepository: FakeAuthRepository(
        initialState: const AuthSessionState.authenticated(_regularUser),
      ),
      homeAdRepository: const _TestHomeAdRepository(),
    );

    final latestTop = tester
        .getTopLeft(find.byKey(const ValueKey('home-latest-header')))
        .dy;
    final adTop = tester
        .getTopLeft(find.byKey(const ValueKey('home-native-ad-slot')))
        .dy;
    final updatedTop = tester
        .getTopLeft(find.byKey(const ValueKey('home-recent-header')))
        .dy;

    expect(
      find.byKey(const ValueKey('home-continue-reading-header')),
      findsNothing,
    );
    expect(latestTop, lessThan(adTop));
    expect(adTop, lessThan(updatedTop));
  });

  testWidgets('quick preset renders compact and limited home sections', (
    tester,
  ) async {
    final repository = _MemoryHomeCustomizationRepository(
      HomeCustomization.forPreset(HomeCustomizationPreset.quick),
    );
    await _pumpHome(
      tester,
      home: _homeWithLatestUpdates(12),
      size: const Size(840, 3000),
      homeCustomizationRepository: repository,
    );

    expect(
      find.byKey(const ValueKey('continue-reading-compact-0')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('updated-novels-grid')), findsOneWidget);
    expect(find.byKey(const ValueKey('latest-update-4')), findsOneWidget);
    expect(find.byKey(const ValueKey('latest-update-5')), findsNothing);
  });

  testWidgets('quick preset fits a narrow phone at 200 percent text', (
    tester,
  ) async {
    final repository = _MemoryHomeCustomizationRepository(
      HomeCustomization.forPreset(HomeCustomizationPreset.quick),
    );
    await _pumpHome(
      tester,
      home: _homeWithLatestUpdates(12),
      size: const Size(320, 1400),
      textScaler: const TextScaler.linear(2),
      homeCustomizationRepository: repository,
    );

    expect(tester.takeException(), isNull);
    expect(
      find.byKey(const ValueKey('continue-reading-compact-0')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('updated-novels-grid')), findsOneWidget);
  });

  testWidgets('visual preset renders v2 templates inside soft panels', (
    tester,
  ) async {
    final repository = _MemoryHomeCustomizationRepository(
      HomeCustomization.forPreset(HomeCustomizationPreset.visual),
    );
    await _pumpHome(
      tester,
      size: const Size(840, 3600),
      homeCustomizationRepository: repository,
      authRepository: FakeAuthRepository(
        initialState: const AuthSessionState.authenticated(_regularUser),
      ),
      homeAdRepository: const _TestHomeAdRepository(),
    );

    expect(
      find.byKey(const ValueKey('continue-reading-template-coverFocus-0')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('updated-card-poster-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('latest-card-poster-7')), findsOneWidget);
    for (final section in const [
      HomeSectionId.continueReading,
      HomeSectionId.updatedNovels,
      HomeSectionId.latestUpdates,
    ]) {
      expect(
        find.byKey(ValueKey('home-section-panel-${section.name}')),
        findsOneWidget,
      );
    }
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('home-section-panel-continueReading')),
        matching: find.byKey(const ValueKey('home-native-ad-slot')),
      ),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('applied customization updates home without reloading the app', (
    tester,
  ) async {
    final repository = _MemoryHomeCustomizationRepository(
      HomeCustomization.defaults,
    );
    await _pumpHome(tester, homeCustomizationRepository: repository);

    expect(
      find.byKey(const ValueKey('home-continue-reading-header')),
      findsOneWidget,
    );

    await repository.update(
      repository.value.copyWith(
        hiddenSections: const {HomeSectionId.continueReading},
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('home-continue-reading-header')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('home-recent-header')), findsOneWidget);
  });

  testWidgets('home native ad is absent for an active VIP account', (
    tester,
  ) async {
    await _pumpHome(
      tester,
      authRepository: FakeAuthRepository(
        initialState: const AuthSessionState.authenticated(_vipUser),
      ),
      homeAdRepository: const _TestHomeAdRepository(),
    );

    expect(find.byKey(const ValueKey('home-native-ad-slot')), findsNothing);
    expect(find.byKey(const ValueKey('test-home-native-ad')), findsNothing);
  });

  testWidgets('continue reading strip shows every local history entry', (
    tester,
  ) async {
    await _pumpHome(
      tester,
      history: [
        local_progress.ReadingProgress(
          novelId: 41,
          novelTitle: 'رواية السجل الأولى',
          chapterId: 7,
          chapterTitle: 'الفصل السابع',
          contentApi: '/chapters/7',
          chapterPosition: 7,
          chaptersTotal: 40,
          updatedAt: _historyDate,
        ),
        local_progress.ReadingProgress(
          novelId: 42,
          novelTitle: 'رواية السجل الثانية',
          chapterId: 3,
          chapterTitle: 'الفصل الثالث',
          contentApi: '/chapters/3',
          chapterPosition: 3,
          chaptersTotal: 20,
          updatedAt: _historyDate,
        ),
      ],
    );

    expect(
      find.byKey(const ValueKey('continue-reading-strip')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('continue-reading-card-0')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('continue-reading-card-1')),
      findsOneWidget,
    );
    expect(find.text('رواية السجل الأولى'), findsOneWidget);
    expect(find.text('رواية السجل الثانية'), findsOneWidget);
    expect(find.text('الفصل 7 من 40'), findsOneWidget);
    expect(find.text('الفصل 3 من 20'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('continue-reading-previous')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('continue-reading-next')), findsOneWidget);
    expect(find.text('1 / 2'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('continue-reading-next')));
    await tester.pumpAndSettle();
    expect(find.text('2 / 2'), findsOneWidget);
  });

  testWidgets('updated posters keep titles inside the cover gradient', (
    tester,
  ) async {
    await _pumpHome(tester, size: const Size(390, 1600));

    final card = find.byKey(const ValueKey('updated-card-poster-1'));
    final cover = find.descendant(
      of: card,
      matching: find.byType(HomeNovelCover),
    );
    final title = find.descendant(
      of: card,
      matching: find.text('الرواية الأولى'),
    );

    expect(card, findsOneWidget);
    expect(cover, findsOneWidget);
    expect(title, findsOneWidget);
    expect(
      tester.getTopLeft(title).dy,
      greaterThan(tester.getTopLeft(cover).dy),
    );
    expect(
      tester.getBottomLeft(title).dy,
      lessThanOrEqualTo(tester.getBottomLeft(cover).dy),
    );
    expect(find.byKey(const ValueKey('galaxy-adaptive-pair')), findsOneWidget);
    expect(tester.getSize(card).width, greaterThan(160));
    expect(find.byKey(const ValueKey('updated-action-1')), findsNothing);
  });

  testWidgets('Stitch home sections fit 320 pixels at 200 percent text', (
    tester,
  ) async {
    await _pumpHome(
      tester,
      size: const Size(320, 1200),
      textScaler: const TextScaler.linear(2),
    );

    expect(
      find.byKey(const ValueKey('continue-reading-strip')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('updated-novels-strip')), findsOneWidget);
    expect(
      tester.takeException(),
      isNull,
      reason: 'The initial shell and horizontal strips must fit before scroll.',
    );
    await _reveal(tester, find.byKey(const ValueKey('latest-update-7')));
    expect(tester.takeException(), isNull);
  });

  testWidgets('latest update list fits 320 pixels at 200 percent text', (
    tester,
  ) async {
    await _pumpLatestSection(
      tester,
      size: const Size(320, 1200),
      textScaler: const TextScaler.linear(2),
      customization: HomeCustomization.defaults.copyWith(
        latestUpdatesLayout: LatestUpdatesLayout.detailedList,
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('balanced home renders latest updates as an editorial list', (
    tester,
  ) async {
    await _pumpLatestSection(
      tester,
      size: const Size(390, 1000),
      textScaler: TextScaler.noScaling,
    );

    expect(find.byKey(const ValueKey('latest-list')), findsOneWidget);
    expect(find.byKey(const ValueKey('latest-updates-strip')), findsNothing);
    expect(find.byKey(const ValueKey('latest-grid')), findsNothing);
  });

  testWidgets('latest update derives a details manifest as final fallback', (
    tester,
  ) async {
    String? requestedManifest;
    const fallbackHome = HomeData(
      continueReading: null,
      recentNovels: [],
      latestChapters: [
        ChapterSummary(
          id: 91,
          novelId: 130585,
          novelTitle: 'تحديث بلا manifest',
          label: 'الفصل 91',
          title: '',
          dateLabel: 'الآن',
          url: '/chapter-91/',
        ),
      ],
    );
    await _pumpHome(
      tester,
      home: fallbackHome,
      novelRepository: _CapturingNovelRepository(
        onLoad: (manifest) => requestedManifest = manifest,
      ),
    );

    await tester.tap(find.byKey(const ValueKey('latest-update-91')));
    await tester.pumpAndSettle();

    expect(
      requestedManifest,
      '/wp-content/uploads/wor-reader-cache/app/manifest/novel-130585.json',
    );
    expect(find.byType(NovelDetailsScreen), findsOneWidget);
  });

  testWidgets('latest list shows two separate chapter and date rows', (
    tester,
  ) async {
    await _pumpLatestSection(
      tester,
      size: const Size(390, 1000),
      textScaler: TextScaler.noScaling,
      home: const HomeData(
        continueReading: null,
        recentNovels: [
          NovelSummary(
            id: 9,
            title: 'رواية التحديث المجمع',
            url: '/novel/9',
            coverThumbnail: '',
            statusLabel: 'مستمرة',
            genres: [],
            chaptersCount: 207,
            manifest: '/manifest/9.json',
          ),
        ],
        latestChapters: [
          ChapterSummary(
            id: 207,
            novelId: 9,
            novelTitle: 'رواية التحديث المجمع',
            label: 'الفصل 207',
            title: '',
            dateLabel: 'منذ ساعتين',
            url: '/chapter/207',
            chapters: [
              ChapterSummaryItem(
                id: 207,
                label: 'الفصل 207',
                title: '',
                dateLabel: 'منذ ساعتين',
                url: '/chapter/207',
              ),
              ChapterSummaryItem(
                id: 206,
                label: 'الفصل 206',
                title: '',
                dateLabel: 'منذ ثلاث ساعات',
                url: '/chapter/206',
              ),
              ChapterSummaryItem(
                id: 205,
                label: 'الفصل 205',
                title: '',
                dateLabel: 'منذ أربع ساعات',
                url: '/chapter/205',
              ),
            ],
            manifest: '/manifest/9.json',
          ),
        ],
      ),
      customization: HomeCustomization.defaults.copyWith(
        latestUpdatesLayout: LatestUpdatesLayout.detailedList,
      ),
    );

    expect(find.text('الفصل 207'), findsOneWidget);
    expect(find.text('الفصل 206'), findsOneWidget);
    expect(find.text('الفصل 205'), findsNothing);
    expect(find.text('منذ ساعتين'), findsOneWidget);
    expect(find.text('منذ ثلاث ساعات'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('latest-update-207')),
        matching: find.byKey(const ValueKey('latest-status-207')),
      ),
      findsOneWidget,
    );
  });

  for (final (width, expectedColumns) in const [
    (320.0, 1),
    (390.0, 1),
    (600.0, 2),
    (720.0, 2),
    (840.0, 2),
  ]) {
    testWidgets(
      'latest grid uses $expectedColumns columns at ${width.toInt()} with 200% text',
      (tester) async {
        await _pumpLatestSection(
          tester,
          size: Size(width, 1600),
          textScaler: const TextScaler.linear(2),
          customization: HomeCustomization.defaults.copyWith(
            latestUpdatesLayout: LatestUpdatesLayout.grid,
          ),
        );

        final visibleGridCards = find.byWidgetPredicate((widget) {
          final key = widget.key;
          return key is ValueKey<String> &&
              key.value.startsWith('latest-grid-');
        });
        final horizontalPositions = visibleGridCards
            .evaluate()
            .map(
              (element) => tester.getTopLeft(find.byWidget(element.widget)).dx,
            )
            .map((position) => position.round())
            .toSet();

        expect(horizontalPositions, hasLength(expectedColumns));
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'latest layout comes from customization without an inline toggle',
    (tester) async {
      await _pumpLatestSection(
        tester,
        size: const Size(390, 1600),
        textScaler: const TextScaler.linear(2),
        customization: HomeCustomization.defaults.copyWith(
          latestUpdatesLayout: LatestUpdatesLayout.grid,
        ),
      );

      final sectionContext = tester.element(find.byType(LatestUpdatesSection));
      expect(Directionality.of(sectionContext), TextDirection.rtl);
      expect(find.byKey(const ValueKey('latest-grid')), findsOneWidget);
      expect(find.byKey(const ValueKey('latest-view-toggle')), findsNothing);
      expect(find.byTooltip('عرض كشبكة'), findsNothing);
    },
  );
}

Future<void> _pumpHome(
  WidgetTester tester, {
  HomeData home = _home,
  Size size = const Size(390, 1600),
  TextScaler textScaler = TextScaler.noScaling,
  NovelRepository? novelRepository,
  List<local_progress.ReadingProgress> history = const [],
  AuthRepository? authRepository,
  HomeAdRepository? homeAdRepository,
  HomeCustomizationRepository? homeCustomizationRepository,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(size: size, textScaler: textScaler),
      child: GalaxyNovelsApp(
        homeRepository: _TestHomeRepository(home),
        novelRepository: novelRepository ?? _CapturingNovelRepository(),
        readingHistoryRepository: _TestReadingHistoryRepository(history),
        authRepository: authRepository,
        homeAdRepository: homeAdRepository,
        homeCustomizationRepository: homeCustomizationRepository,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _reveal(WidgetTester tester, Finder target) async {
  await tester.scrollUntilVisible(
    target,
    420,
    scrollable: find
        .descendant(
          of: find.byKey(const ValueKey('home-scroll-view')),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpLatestSection(
  WidgetTester tester, {
  required Size size,
  required TextScaler textScaler,
  HomeData? home,
  HomeCustomization? customization,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  final effectiveHome = home ?? _homeWithLatestUpdates(12);

  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('ar'),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: MediaQuery(
          data: MediaQueryData(size: size, textScaler: textScaler),
          child: Scaffold(
            body: SafeArea(
              child: CustomScrollView(
                slivers: [
                  LatestUpdatesSection(
                    chapters: effectiveHome.latestChapters,
                    novelsById: {
                      for (final novel in effectiveHome.recentNovels)
                        novel.id: novel,
                    },
                    onNovelTap: (_) {},
                    customization: customization,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

HomeData _homeWithLatestUpdates(int count) {
  return HomeData(
    continueReading: _home.continueReading,
    recentNovels: _home.recentNovels,
    latestChapters: List.generate(count, (index) {
      final chapter = index + 1;
      return ChapterSummary(
        id: chapter,
        novelId: 1,
        novelTitle: 'تحديث الشبكة $chapter',
        label: 'الفصل $chapter',
        title: '',
        dateLabel: 'الآن',
        url: '/chapter-$chapter/',
        manifest: '/manifest/latest-$chapter.json',
      );
    }),
  );
}

const _home = HomeData(
  continueReading: ReadingProgress(
    novelTitle: 'قراءة مستمرة',
    chapterLabel: 'الفصل 12',
    progress: 45,
  ),
  recentNovels: [
    NovelSummary(
      id: 1,
      title: 'الرواية الأولى',
      url: '/novel/first/',
      coverThumbnail: '',
      statusLabel: 'مستمرة',
      genres: ['خيال'],
      chaptersCount: 40,
      manifest: '/manifest/first.json',
    ),
    NovelSummary(
      id: 2,
      title: 'الرواية الثانية',
      url: '/novel/second/',
      coverThumbnail: '',
      statusLabel: 'مكتملة',
      genres: ['دراما'],
      chaptersCount: 70,
      manifest: '/manifest/second.json',
    ),
  ],
  latestChapters: [
    ChapterSummary(
      id: 7,
      novelId: 1,
      novelTitle: 'آخر تحديث تجريبي',
      label: 'الفصل 7',
      title: '',
      dateLabel: 'الآن',
      url: '/chapter-7/',
      manifest: '/manifest/latest.json',
    ),
  ],
);

class _TestHomeRepository implements HomeRepository {
  const _TestHomeRepository(this.home);

  final HomeData home;

  @override
  Future<HomeData> loadHome() async => home;
}

class _CapturingNovelRepository implements NovelRepository {
  _CapturingNovelRepository({this.onLoad});

  final ValueChanged<String>? onLoad;

  @override
  Future<NovelDetailsLoadResult> loadNovel(String manifestPath) async {
    onLoad?.call(manifestPath);
    return const NovelDetailsLoadResult(
      details: NovelDetails(
        id: 1,
        title: 'تفاصيل الوجهة',
        originalTitle: '',
        url: '/novel/details/',
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
        ratingAverage: 0,
        ratingCount: 0,
        views: 0,
        updatedAt: null,
        summary: '',
        chaptersManifest: '',
        vipScheduleManifest: '',
        manifest: '/manifest/details.json',
      ),
      chapters: [],
    );
  }
}

class _TestReadingHistoryRepository extends ChangeNotifier
    implements ReadingHistoryRepository {
  _TestReadingHistoryRepository([this.items = const []]);

  final List<local_progress.ReadingProgress> items;

  @override
  Future<List<local_progress.ReadingProgress>> load() async => items;

  @override
  Future<void> record(local_progress.ReadingProgress progress) async {}
}

final _historyDate = DateTime.utc(2026, 7, 19);

const _regularUser = AuthUser(
  id: 10,
  displayName: 'قارئ عادي',
  avatar: null,
  vip: AuthVip(active: false, tier: '', label: '', expiresAt: null),
  xp: AuthXp(
    total: 0,
    today: 0,
    secondsTotal: 0,
    chaptersTotal: 0,
    rank: AuthRank(level: 0, display: ''),
  ),
);

const _vipUser = AuthUser(
  id: 11,
  displayName: 'قارئ VIP',
  avatar: null,
  vip: AuthVip(active: true, tier: 'vip3', label: 'VIP 3', expiresAt: null),
  xp: AuthXp(
    total: 0,
    today: 0,
    secondsTotal: 0,
    chaptersTotal: 0,
    rank: AuthRank(level: 0, display: ''),
  ),
);

class _TestHomeAdRepository implements HomeAdRepository {
  const _TestHomeAdRepository();

  @override
  Future<void> initialize() async {}

  @override
  Widget? buildHomeNativeAd(BuildContext context) {
    return const SizedBox(key: ValueKey('test-home-native-ad'), height: 140);
  }
}

class _MemoryHomeCustomizationRepository extends ChangeNotifier
    implements HomeCustomizationRepository {
  _MemoryHomeCustomizationRepository(this._value);

  HomeCustomization _value;

  @override
  HomeCustomization get value => _value;

  @override
  Future<void> load() async {}

  @override
  Future<void> update(HomeCustomization customization) async {
    _value = customization;
    notifyListeners();
  }
}
