import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/app/galaxy_novels_app.dart';
import 'package:galaxy_novels_app/data/models/catalog_data.dart';
import 'package:galaxy_novels_app/data/models/chapter_summary.dart';
import 'package:galaxy_novels_app/data/models/home_data.dart';
import 'package:galaxy_novels_app/data/models/novel_details_data.dart';
import 'package:galaxy_novels_app/data/models/novel_summary.dart';
import 'package:galaxy_novels_app/data/repositories/catalog_repository.dart';
import 'package:galaxy_novels_app/data/repositories/home_repository.dart';
import 'package:galaxy_novels_app/data/repositories/novel_repository.dart';

void main() {
  testWidgets('shows Galaxy Novels Arabic shell', (tester) async {
    await tester.pumpWidget(
      GalaxyNovelsApp(
        homeRepository: _TestHomeRepository(_homeData),
        catalogRepository: const _TestCatalogRepository(),
        novelRepository: const _TestNovelRepository(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('الرئيسية'), findsWidgets);
    expect(find.text('المكتبة'), findsOneWidget);
    expect(find.text('السجل'), findsOneWidget);
    expect(find.text('الترتيب'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(BottomNavigationBar),
        matching: find.text('حسابي'),
      ),
      findsNothing,
    );
  });

  testWidgets('opens account screen from the drawer', (tester) async {
    await tester.pumpWidget(
      GalaxyNovelsApp(
        homeRepository: _TestHomeRepository(_homeData),
        catalogRepository: const _TestCatalogRepository(),
        novelRepository: const _TestNovelRepository(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    expect(find.text('حسابي'), findsOneWidget);

    await tester.tap(find.text('حسابي'));
    await tester.pumpAndSettle();

    expect(find.text('تسجيل الدخول'), findsOneWidget);
    expect(
      find.text('سجّل الدخول لمزامنة القراءة والمفضلة و XP.'),
      findsOneWidget,
    );
  });

  testWidgets('home screen renders repository-provided sections', (
    tester,
  ) async {
    await tester.pumpWidget(
      GalaxyNovelsApp(
        homeRepository: _TestHomeRepository(_homeData),
        catalogRepository: const _TestCatalogRepository(),
        novelRepository: const _TestNovelRepository(),
      ),
    );

    expect(find.text('جار تحميل الرئيسية...'), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.text('اختبار المجرة'), findsOneWidget);
    expect(find.text('رواية الاختبار'), findsWidgets);
    expect(find.text('مستمرة'), findsWidgets);

    await _scrollHomeDown(tester);

    expect(find.text('الفصل 5'), findsOneWidget);
  });

  testWidgets('latest updates can switch between list and three-column grid', (
    tester,
  ) async {
    await tester.pumpWidget(
      GalaxyNovelsApp(
        homeRepository: _TestHomeRepository(_homeData),
        catalogRepository: const _TestCatalogRepository(),
        novelRepository: const _TestNovelRepository(),
      ),
    );
    await tester.pumpAndSettle();

    await _scrollHomeDown(tester);

    expect(find.text('آخر تحديثات الروايات'), findsOneWidget);
    expect(find.text('الفصل 5'), findsOneWidget);
    expect(find.byTooltip('عرض كجرد ثلاثي'), findsOneWidget);

    await tester.tap(find.byTooltip('عرض كجرد ثلاثي'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('عرض كقائمة'), findsOneWidget);
    expect(find.text('نجوم الاختبار'), findsWidgets);
    expect(find.text('الفصل 5'), findsNothing);
  });

  testWidgets('latest update card keeps the novel title on one line', (
    tester,
  ) async {
    await tester.pumpWidget(
      GalaxyNovelsApp(
        homeRepository: _TestHomeRepository(_homeData),
        catalogRepository: const _TestCatalogRepository(),
        novelRepository: const _TestNovelRepository(),
      ),
    );
    await tester.pumpAndSettle();

    await _scrollHomeDown(tester);

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            widget.data == 'نجوم الاختبار' &&
            widget.maxLines == 1 &&
            widget.overflow == TextOverflow.ellipsis,
      ),
      findsOneWidget,
    );
  });

  testWidgets('recent novels are shown before latest updates', (tester) async {
    tester.view.physicalSize = const Size(720, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      GalaxyNovelsApp(
        homeRepository: _TestHomeRepository(_homeData),
        catalogRepository: const _TestCatalogRepository(),
        novelRepository: const _TestNovelRepository(),
      ),
    );
    await tester.pumpAndSettle();

    final recentTop = tester.getTopLeft(find.text('روايات محدثة')).dy;
    final latestTop = tester.getTopLeft(find.text('آخر تحديثات الروايات')).dy;

    expect(recentTop, lessThan(latestTop));
  });

  testWidgets('catalog tab renders repository-provided novels', (tester) async {
    await tester.pumpWidget(
      GalaxyNovelsApp(
        homeRepository: _TestHomeRepository(_homeData),
        catalogRepository: const _TestCatalogRepository(),
        novelRepository: const _TestNovelRepository(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('المكتبة'));
    await tester.pumpAndSettle();

    expect(find.text('مكتبة الاختبار'), findsOneWidget);
    expect(find.textContaining('10 فصل'), findsOneWidget);
    expect(find.text('آخر تحديث'), findsOneWidget);
  });

  testWidgets('catalog search filters results locally', (tester) async {
    await tester.pumpWidget(
      GalaxyNovelsApp(
        homeRepository: _TestHomeRepository(_homeData),
        catalogRepository: const _TestCatalogRepository(),
        novelRepository: const _TestNovelRepository(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('المكتبة'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'غير موجود');
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('لا توجد نتائج مطابقة'), findsOneWidget);

    await tester.tap(find.text('مسح البحث والفلاتر'));
    await tester.pumpAndSettle();

    expect(find.text('مكتبة الاختبار'), findsOneWidget);
  });

  testWidgets('catalog filters are applied from the bottom sheet', (
    tester,
  ) async {
    await tester.pumpWidget(
      GalaxyNovelsApp(
        homeRepository: _TestHomeRepository(_homeData),
        catalogRepository: const _TestCatalogRepository(),
        novelRepository: const _TestNovelRepository(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('المكتبة'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('فلاتر'));
    await tester.pumpAndSettle();

    expect(find.text('الحالة'), findsOneWidget);
    await tester.tap(find.text('مكتملة'));
    await tester.tap(find.text('تطبيق'));
    await tester.pumpAndSettle();

    expect(find.text('مكتملة الاختبار'), findsOneWidget);
    expect(find.text('مكتبة الاختبار'), findsNothing);
  });

  testWidgets('catalog keeps data visible when a later pack fails', (
    tester,
  ) async {
    await tester.pumpWidget(
      GalaxyNovelsApp(
        homeRepository: _TestHomeRepository(_homeData),
        catalogRepository: const _BackgroundErrorCatalogRepository(),
        novelRepository: const _TestNovelRepository(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('المكتبة'));
    await tester.pumpAndSettle();

    expect(find.text('مكتبة الاختبار'), findsOneWidget);
    expect(find.text('تعذر تحميل بقية المكتبة'), findsOneWidget);
    expect(find.text('إعادة المحاولة'), findsOneWidget);
  });

  testWidgets('opens novel details from the catalog', (tester) async {
    await tester.pumpWidget(
      GalaxyNovelsApp(
        homeRepository: _TestHomeRepository(_homeData),
        catalogRepository: const _TestCatalogRepository(),
        novelRepository: const _TestNovelRepository(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('المكتبة'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('مكتبة الاختبار'));
    await tester.pumpAndSettle();

    expect(find.text('تفاصيل الاختبار'), findsOneWidget);
    expect(find.text('هذه نبذة تفاصيل الاختبار.'), findsOneWidget);
    expect(find.text('ابدأ القراءة'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('الفصل 1'), 320);
    await tester.pumpAndSettle();

    expect(find.text('الفصل 1'), findsOneWidget);
  });

  testWidgets('opens novel details from the home screen', (tester) async {
    await tester.pumpWidget(
      GalaxyNovelsApp(
        homeRepository: _TestHomeRepository(_homeData),
        catalogRepository: const _TestCatalogRepository(),
        novelRepository: const _TestNovelRepository(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('رواية الاختبار').first);
    await tester.pumpAndSettle();

    expect(find.text('تفاصيل الاختبار'), findsOneWidget);
    expect(find.text('هذه نبذة تفاصيل الاختبار.'), findsOneWidget);
  });

  testWidgets(
    'novel details hides read button when no chapters are available',
    (tester) async {
      await tester.pumpWidget(
        GalaxyNovelsApp(
          homeRepository: _TestHomeRepository(_homeData),
          catalogRepository: const _TestCatalogRepository(),
          novelRepository: const _EmptyNovelRepository(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('المكتبة'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('مكتبة الاختبار'));
      await tester.pumpAndSettle();

      expect(find.text('لا توجد فصول متاحة للعرض الآن'), findsOneWidget);
      expect(find.text('ابدأ القراءة'), findsNothing);
    },
  );
}

Future<void> _scrollHomeDown(WidgetTester tester) async {
  final mainList = find.byWidgetPredicate(
    (widget) => widget is ListView && widget.scrollDirection == Axis.vertical,
  );

  await tester.drag(mainList, const Offset(0, -640));
  await tester.pumpAndSettle();
}

const _homeData = HomeData(
  continueReading: ReadingProgress(
    novelTitle: 'اختبار المجرة',
    chapterLabel: 'الفصل 5',
    progress: 42,
  ),
  latestChapters: [
    ChapterSummary(
      id: 5,
      novelId: 1,
      novelTitle: 'نجوم الاختبار',
      label: 'الفصل 5',
      title: '',
      dateLabel: 'الآن',
      url: '/chapter-5/',
      chapters: [
        ChapterSummaryItem(
          id: 5,
          label: 'الفصل 5',
          title: 'عنوان الاختبار',
          dateLabel: 'الآن',
          url: '/chapter-5/',
        ),
      ],
    ),
  ],
  recentNovels: [
    NovelSummary(
      id: 1,
      title: 'رواية الاختبار',
      url: '/novel/test/',
      coverThumbnail: '',
      statusLabel: 'مستمرة',
      genres: ['خيال'],
      chaptersCount: 12,
      manifest: '/novel-home-test.json',
    ),
  ],
);

class _TestHomeRepository implements HomeRepository {
  const _TestHomeRepository(this.data);

  final HomeData data;

  @override
  Future<HomeData> loadHome() async => data;
}

class _TestCatalogRepository implements CatalogRepository {
  const _TestCatalogRepository();

  @override
  Stream<CatalogLoadState> watchCatalog() async* {
    yield const CatalogLoadState(
      items: [
        CatalogNovel(
          id: 99,
          title: 'مكتبة الاختبار',
          originalTitle: '',
          url: '/novel/catalog-test/',
          coverThumbnail: '',
          coverMedium: '',
          statusKey: 'ongoing',
          statusLabel: 'مستمرة',
          genres: [CatalogGenre(id: 1, name: 'أكشن', slug: 'action')],
          chaptersCount: 10,
          ratingAverage: 4.2,
          ratingCount: 5,
          views: 100,
          updatedAt: null,
          manifest: '/novel-catalog-test.json',
        ),
        CatalogNovel(
          id: 100,
          title: 'مكتملة الاختبار',
          originalTitle: '',
          url: '/novel/completed-test/',
          coverThumbnail: '',
          coverMedium: '',
          statusKey: 'completed',
          statusLabel: 'مكتملة',
          genres: [CatalogGenre(id: 2, name: 'دراما', slug: 'drama')],
          chaptersCount: 20,
          ratingAverage: 4.6,
          ratingCount: 8,
          views: 200,
          updatedAt: null,
          manifest: '',
        ),
      ],
      loadedParts: 1,
      totalParts: 1,
      isLoadingMore: false,
    );
  }
}

class _BackgroundErrorCatalogRepository implements CatalogRepository {
  const _BackgroundErrorCatalogRepository();

  @override
  Stream<CatalogLoadState> watchCatalog() async* {
    yield const CatalogLoadState(
      items: [
        CatalogNovel(
          id: 99,
          title: 'مكتبة الاختبار',
          originalTitle: '',
          url: '/novel/catalog-test/',
          coverThumbnail: '',
          coverMedium: '',
          statusKey: 'ongoing',
          statusLabel: 'مستمرة',
          genres: [CatalogGenre(id: 1, name: 'أكشن', slug: 'action')],
          chaptersCount: 10,
          ratingAverage: 4.2,
          ratingCount: 5,
          views: 100,
          updatedAt: null,
          manifest: '',
        ),
      ],
      loadedParts: 1,
      totalParts: 2,
      isLoadingMore: false,
      backgroundError: 'Second pack failed.',
    );
  }
}

class _EmptyNovelRepository implements NovelRepository {
  const _EmptyNovelRepository();

  @override
  Future<NovelDetailsLoadResult> loadNovel(String manifestPath) async {
    return const NovelDetailsLoadResult(
      details: NovelDetails(
        id: 101,
        title: 'تفاصيل بلا فصول',
        originalTitle: '',
        url: '/novel/no-chapters/',
        coverThumbnail: '',
        coverMedium: '',
        coverLarge: '',
        statusKey: 'ongoing',
        statusLabel: 'مستمرة',
        country: '',
        author: '',
        translator: '',
        genres: [],
        chaptersCount: 10,
        firstChapterId: 0,
        firstChapterUrl: '',
        ratingAverage: 0,
        ratingCount: 0,
        views: 0,
        updatedAt: null,
        summary: 'لا توجد فصول بعد.',
        chaptersManifest: '',
        vipScheduleManifest: '',
        manifest: '/novel-empty.json',
      ),
      chapters: [],
    );
  }
}

class _TestNovelRepository implements NovelRepository {
  const _TestNovelRepository();

  @override
  Future<NovelDetailsLoadResult> loadNovel(String manifestPath) async {
    return const NovelDetailsLoadResult(
      details: NovelDetails(
        id: 99,
        title: 'تفاصيل الاختبار',
        originalTitle: 'Test Details',
        url: '/novel/details-test/',
        coverThumbnail: '',
        coverMedium: '',
        coverLarge: '',
        statusKey: 'ongoing',
        statusLabel: 'مستمرة',
        country: 'cn',
        author: 'كاتب الاختبار',
        translator: '',
        genres: [NovelGenre(id: 1, name: 'أكشن', slug: 'action')],
        chaptersCount: 2,
        firstChapterId: 1,
        firstChapterUrl: '/chapter-1/',
        ratingAverage: 4.2,
        ratingCount: 5,
        views: 120,
        updatedAt: null,
        summary: 'هذه نبذة تفاصيل الاختبار.',
        chaptersManifest: '/chapters.json',
        vipScheduleManifest: '',
        manifest: '/novel-test.json',
      ),
      chapters: [
        NovelChapter(
          id: 1,
          position: 1,
          number: '1',
          label: 'الفصل 1',
          title: 'البداية',
          url: '/chapter-1/',
          dateLabel: 'اليوم',
          dateIso: null,
          views: 0,
          comments: 0,
          search: '',
        ),
      ],
    );
  }
}
