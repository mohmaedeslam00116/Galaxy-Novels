import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/app/galaxy_novels_app.dart';
import 'package:galaxy_novels_app/data/models/catalog_data.dart';
import 'package:galaxy_novels_app/data/models/chapter_summary.dart';
import 'package:galaxy_novels_app/data/models/home_data.dart';
import 'package:galaxy_novels_app/data/models/novel_summary.dart';
import 'package:galaxy_novels_app/data/repositories/catalog_repository.dart';
import 'package:galaxy_novels_app/data/repositories/home_repository.dart';

void main() {
  testWidgets('shows Galaxy Novels Arabic shell', (tester) async {
    await tester.pumpWidget(
      GalaxyNovelsApp(
        homeRepository: _TestHomeRepository(_homeData),
        catalogRepository: const _TestCatalogRepository(),
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
      ),
    );
    await tester.pumpAndSettle();

    final recentTop = tester.getTopLeft(find.text('روايات محدثة')).dy;
    final latestTop = tester.getTopLeft(find.text('آخر تحديثات الروايات')).dy;

    expect(recentTop, lessThan(latestTop));
  });
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
      manifest: '',
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
          manifest: '',
        ),
      ],
      loadedParts: 1,
      totalParts: 1,
      isLoadingMore: false,
    );
  }
}
