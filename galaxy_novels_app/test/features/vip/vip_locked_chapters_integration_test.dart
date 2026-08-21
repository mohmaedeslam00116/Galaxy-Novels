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
import 'package:galaxy_novels_app/design_system/novel/galaxy_chapter_row.dart';
import 'package:galaxy_novels_app/features/account/domain/auth_session.dart';
import 'package:galaxy_novels_app/features/novel_details/domain/readable_chapter.dart';
import 'package:galaxy_novels_app/features/novel_details/presentation/all_chapters_screen.dart';
import 'package:galaxy_novels_app/features/novel_details/presentation/widgets/novel_details_content.dart';
import 'package:galaxy_novels_app/features/novel_details/presentation/widgets/novel_chapter_tile.dart';
import 'package:galaxy_novels_app/features/novel_details/presentation/widgets/readable_chapter_tile.dart';
import 'package:galaxy_novels_app/features/novel_engagement/application/novel_engagement_controller.dart';
import 'package:galaxy_novels_app/features/novel_engagement/domain/novel_user_state.dart';
import 'package:galaxy_novels_app/features/vip/application/vip_chapters_controller.dart';
import 'package:galaxy_novels_app/features/vip/domain/vip_chapter.dart';
import 'package:galaxy_novels_app/features/vip/presentation/vip_access_notice.dart';

import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_comments_repository.dart';
import '../../helpers/fake_favorites_repository.dart';
import '../../helpers/fake_novel_engagement_repository.dart';
import '../../helpers/fake_reader_preferences_repository.dart';
import '../../helpers/fake_vip_repository.dart';

void main() {
  testWidgets('guest sees the locked VIP reason and can open their account', (
    tester,
  ) async {
    var accountOpenCount = 0;
    await _pumpDetails(
      tester,
      size: const Size(320, 1200),
      textScaler: const TextScaler.linear(2),
      loadResult: _vipOnlyLoadResult,
      onSignIn: () => accountOpenCount += 1,
    );
    await _openChapters(tester);

    expect(find.text('فصول VIP مقفلة'), findsOneWidget);
    expect(
      find.text('سجّل الدخول بحساب يملك اشتراك VIP لقراءة هذه الفصول.'),
      findsOneWidget,
    );

    final accountAction = find.text('فتح حسابي');
    await _reveal(tester, accountAction);
    expect(accountAction.hitTestable(), findsOneWidget);
    await tester.tap(accountAction);
    expect(accountOpenCount, 1);
  });

  testWidgets(
    'authenticated non-subscriber sees no unavailable purchase action',
    (tester) async {
      await _pumpDetails(
        tester,
        size: const Size(320, 1200),
        textScaler: const TextScaler.linear(2),
        loadResult: _vipOnlyLoadResult,
        authRepository: FakeAuthRepository(
          initialState: const AuthSessionState.authenticated(_regularUser),
        ),
        engagementState: _nonSubscriberEngagement,
      );
      await _openChapters(tester);

      expect(
        find.text(
          'لا يوجد اشتراك VIP فعال. الشراء داخل التطبيق غير متاح حاليًا.',
        ),
        findsOneWidget,
      );
      expect(find.text('فتح حسابي'), findsNothing);
      expect(
        find.descendant(
          of: find.byType(VipAccessNotice),
          matching: find.byType(TextButton),
        ),
        findsNothing,
      );
    },
  );

  testWidgets('locked VIP notice follows the observable auth session', (
    tester,
  ) async {
    final authRepository = FakeAuthRepository();
    await _pumpDetails(
      tester,
      size: const Size(320, 1200),
      textScaler: const TextScaler.linear(2),
      loadResult: _vipOnlyLoadResult,
      authRepository: authRepository,
    );
    await _openChapters(tester);

    expect(find.text('فتح حسابي'), findsOneWidget);
    authRepository.value = const AuthSessionState.authenticated(_regularUser);
    await tester.pump();

    expect(find.text('فتح حسابي'), findsNothing);
    expect(
      find.text(
        'لا يوجد اشتراك VIP فعال. الشراء داخل التطبيق غير متاح حاليًا.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('subscriber sees merged VIP rows and opens the direct route', (
    tester,
  ) async {
    String? openedContentApi;
    await _pumpSubscriberDetails(
      tester,
      onOpenVipChapter: (contentApi, _) => openedContentApi = contentApi,
    );
    await _openChapters(tester);
    await _reveal(tester, find.text('الفصل 2'));

    expect(find.text('الفصل 2'), findsOneWidget);
    await tester.tap(find.text('الفصل 2'));

    expect(openedContentApi, '/wp-json/wor-reader-app/v1/vip/chapters/2');
  });

  testWidgets(
    'disabled VIP route is visibly explained and flexible at 320 and 200 percent',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await _pumpSubscriberDetails(tester, directVipRouteAvailable: false);
      await _openChapters(tester);

      final disabledReason = find.text('مسار القراءة غير متاح حاليًا');
      await _reveal(tester, disabledReason);
      final vipTile = find
          .ancestor(of: disabledReason, matching: find.byType(GalaxyChapterRow))
          .first;
      final semanticsData = tester.getSemantics(vipTile).getSemanticsData();

      expect(find.text(_longVipTitle), findsOneWidget);
      expect(
        tester
            .getSize(
              find
                  .ancestor(
                    of: find.text(_longVipTitle),
                    matching: find.byType(GalaxyChapterRow),
                  )
                  .first,
            )
            .height,
        greaterThan(74),
      );
      expect(semanticsData.flagsCollection.isButton, isFalse);
      expect(semanticsData.hasAction(ui.SemanticsAction.tap), isFalse);
      expect(
        find.textContaining('قراءة هذا الفصل تحتاج تحديث مسار VIP'),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
  );

  testWidgets(
    'all chapters keeps unavailable VIP rows disabled without a snackbar',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await _pumpSubscriberDetails(
        tester,
        size: const Size(320, 1600),
        vipRepository: _vipRepositoryWithMore,
        directVipRouteAvailable: false,
      );
      await _openChapters(tester);

      final showAllButton = find.byKey(const ValueKey('show-all-chapters'));
      await _reveal(tester, showAllButton, alignment: 0.38);
      expect(showAllButton.hitTestable(), findsOneWidget);
      await tester.tap(showAllButton);
      await tester.pumpAndSettle();

      expect(find.byType(AllChaptersScreen), findsOneWidget);
      final disabledReason = find.text('مسار القراءة غير متاح حاليًا');
      await _reveal(tester, disabledReason);
      final vipTile = find
          .ancestor(of: disabledReason, matching: find.byType(GalaxyChapterRow))
          .first;
      final semanticsData = tester.getSemantics(vipTile).getSemanticsData();

      expect(semanticsData.flagsCollection.isButton, isFalse);
      expect(semanticsData.hasAction(ui.SemanticsAction.tap), isFalse);
      await tester.tap(vipTile);
      await tester.pumpAndSettle();

      expect(find.byType(AllChaptersScreen), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
      expect(
        find.textContaining('قراءة هذا الفصل تحتاج تحديث مسار VIP'),
        findsNothing,
      );
      semantics.dispose();
    },
  );

  final publicRowCases = <({String name, Widget Function() build})>[
    (
      name: 'readable public',
      build: () => ReadableChapterTile(
        chapter: ReadableChapter.public(_loadResult.chapters.single),
        onTap: () {},
      ),
    ),
    (
      name: 'public chapter',
      build: () =>
          NovelChapterTile(chapter: _loadResult.chapters.single, onTap: () {}),
    ),
  ];
  for (final rowCase in publicRowCases) {
    testWidgets('${rowCase.name} row grows at 320 and 200 percent', (
      tester,
    ) async {
      await _pumpChapterRow(tester, rowCase.build());

      final title = find.text(_longPublicTitle);
      final rowSurface = find
          .ancestor(of: title, matching: find.byType(GalaxyChapterRow))
          .first;
      expect(tester.getSize(rowSurface).height, greaterThan(74));
      expect(tester.takeException(), isNull);
    });
  }
}

Future<void> _pumpChapterRow(WidgetTester tester, Widget row) async {
  tester.view.physicalSize = const Size(320, 600);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('ar'),
      theme: AppTheme.light(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: const TextScaler.linear(2)),
        child: child!,
      ),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(body: ListView(children: [row])),
      ),
    ),
  );
  await tester.pump();
}

Future<void> _pumpSubscriberDetails(
  WidgetTester tester, {
  Size size = const Size(320, 1200),
  FakeVipRepository vipRepository = _vipRepository,
  bool directVipRouteAvailable = true,
  void Function(String contentApi, String title)? onOpenVipChapter,
}) {
  return _pumpDetails(
    tester,
    size: size,
    textScaler: const TextScaler.linear(2),
    authRepository: FakeAuthRepository(
      initialState: const AuthSessionState.authenticated(_vipUser),
    ),
    engagementState: _subscriberEngagement,
    loadResult: _vipOnlyLoadResult,
    vipRepository: vipRepository,
    directVipRouteAvailable: directVipRouteAvailable,
    onOpenVipChapter: onOpenVipChapter,
  );
}

Future<void> _pumpDetails(
  WidgetTester tester, {
  Size size = const Size(600, 900),
  TextScaler textScaler = TextScaler.noScaling,
  FakeAuthRepository? authRepository,
  NovelDetailsLoadResult loadResult = _loadResult,
  NovelEngagementState engagementState = const NovelEngagementState(
    status: NovelEngagementStatus.guest,
    novelId: 42,
  ),
  FakeVipRepository vipRepository = const FakeVipRepository(),
  bool directVipRouteAvailable = true,
  VoidCallback? onSignIn,
  void Function(String contentApi, String title)? onOpenVipChapter,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  final resolvedAuthRepository = authRepository ?? FakeAuthRepository();
  final commentsRepository = FakeCommentsRepository.empty();
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
      authRepository: resolvedAuthRepository,
      commentsRepository: commentsRepository,
      favoritesRepository: FakeFavoritesRepository(),
      novelEngagementRepository: FakeNovelEngagementRepository(),
      vipRepository: vipRepository,
      child: MaterialApp(
        locale: const Locale('ar'),
        theme: AppTheme.light(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: textScaler),
          child: child!,
        ),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: NovelDetailsContent(
              loadResult: loadResult,
              engagementState: engagementState,
              commentsRepository: commentsRepository,
              authRepository: resolvedAuthRepository,
              vipController: vipController,
              isVipNativeReaderAvailable: directVipRouteAvailable,
              onRead: (_, _) {},
              onOpenVipChapter: onOpenVipChapter ?? (_, _) {},
              onRate: () {},
              onSignIn: onSignIn ?? () {},
              onRetryEngagement: () {},
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _openChapters(WidgetTester tester) async {
  final chaptersTab = find.byKey(const ValueKey('novel-section-chapters'));
  await _reveal(tester, chaptersTab);
  expect(chaptersTab.hitTestable(), findsOneWidget);
  await tester.tap(chaptersTab);
  await tester.pumpAndSettle();
}

Future<void> _reveal(
  WidgetTester tester,
  Finder finder, {
  double alignment = 0.1,
}) async {
  await tester.scrollUntilVisible(finder, 300, scrollable: _scrollable());
  await Scrollable.ensureVisible(
    tester.element(finder),
    alignment: alignment,
    duration: Duration.zero,
  );
  await tester.pumpAndSettle();
}

Finder _scrollable() {
  return find.byWidgetPredicate(
    (widget) =>
        widget is Scrollable && widget.axisDirection == AxisDirection.down,
  );
}

const _longPublicTitle =
    'عنوان عام طويل يلتف على سطرين عند تكبير النص إلى مئتي بالمئة';
const _longVipTitle =
    'عنوان خاص طويل يلتف على سطرين عند تكبير النص إلى مئتي بالمئة';

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
    genres: [],
    chaptersCount: 2,
    firstChapterId: 1,
    firstChapterUrl: '/chapters/1',
    ratingAverage: 4.5,
    ratingCount: 10,
    views: 100,
    updatedAt: null,
    summary: '',
    chaptersManifest: '/novels/test/chapters.json',
    vipScheduleManifest: '/novels/test/vip.json',
    manifest: '/novels/test.json',
  ),
  chapters: [
    NovelChapter(
      id: 1,
      position: 1,
      number: '1',
      label: 'الفصل 1',
      title: _longPublicTitle,
      url: '/chapters/1',
      contentApi: '/api/chapters/1',
      dateLabel: 'اليوم',
      dateIso: null,
      views: 10,
      comments: 0,
      search: 'الفصل 1',
    ),
  ],
);

final _vipOnlyLoadResult = NovelDetailsLoadResult(
  details: _loadResult.details,
  chapters: const [],
);

const _vipRepository = FakeVipRepository(
  page: VipChapterPage(
    items: [_vipChapter],
    hasMore: false,
    nextCursorOrder: '',
    nextCursorId: 0,
    totalAvailable: 1,
  ),
);

const _vipRepositoryWithMore = FakeVipRepository(
  page: VipChapterPage(
    items: [_vipChapter],
    hasMore: true,
    nextCursorOrder: '2.000000',
    nextCursorId: 2,
    totalAvailable: 2,
  ),
);

const _vipChapter = VipChapter(
  id: 2,
  number: '2',
  position: 2,
  order: '2.000000',
  title: _longVipTitle,
  url: '',
  publicAt: '',
  views: 0,
  comments: 0,
  contentApi: '/wp-json/wor-reader-app/v1/vip/chapters/2',
);

const _regularUser = AuthUser(
  id: 7,
  displayName: 'قارئ',
  avatar: null,
  vip: AuthVip(active: false, tier: '', label: '', expiresAt: null),
  xp: AuthXp(
    total: 0,
    today: 0,
    secondsTotal: 0,
    chaptersTotal: 0,
    rank: AuthRank(level: 1, display: 'قارئ'),
  ),
);

const _vipUser = AuthUser(
  id: 8,
  displayName: 'قارئ VIP',
  avatar: null,
  vip: AuthVip(active: true, tier: 'gold', label: 'VIP', expiresAt: null),
  xp: AuthXp(
    total: 0,
    today: 0,
    secondsTotal: 0,
    chaptersTotal: 0,
    rank: AuthRank(level: 1, display: 'قارئ'),
  ),
);

const _nonSubscriberEngagement = NovelEngagementState(
  status: NovelEngagementStatus.loading,
  novelId: 42,
  userId: 7,
);

const _subscriberEngagement = NovelEngagementState(
  status: NovelEngagementStatus.loading,
  novelId: 42,
  userId: 8,
  userState: NovelUserState(
    novelId: 42,
    favorite: false,
    myRating: 0,
    lastRead: NovelLastRead(
      chapterId: 0,
      chapterUrl: '',
      progress: 0,
      updatedAt: null,
    ),
    vip: NovelVipAccess(active: true, canReadPrivate: true),
  ),
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
