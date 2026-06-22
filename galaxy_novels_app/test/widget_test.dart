import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/app/galaxy_novels_app.dart';
import 'package:galaxy_novels_app/data/models/catalog_data.dart';
import 'package:galaxy_novels_app/data/models/chapter_summary.dart';
import 'package:galaxy_novels_app/data/models/home_data.dart';
import 'package:galaxy_novels_app/data/models/novel_details_data.dart';
import 'package:galaxy_novels_app/data/models/novel_summary.dart';
import 'package:galaxy_novels_app/data/models/reader_content_data.dart';
import 'package:galaxy_novels_app/data/models/reading_progress.dart'
    as local_progress;
import 'package:galaxy_novels_app/data/models/rankings_data.dart';
import 'package:galaxy_novels_app/data/models/search_index_data.dart';
import 'package:galaxy_novels_app/data/repositories/catalog_repository.dart';
import 'package:galaxy_novels_app/data/repositories/fake_downloads_repository.dart';
import 'package:galaxy_novels_app/data/repositories/home_repository.dart';
import 'package:galaxy_novels_app/data/repositories/novel_repository.dart';
import 'package:galaxy_novels_app/data/repositories/reader_repository.dart';
import 'package:galaxy_novels_app/data/repositories/reading_history_repository.dart';
import 'package:galaxy_novels_app/data/repositories/rankings_repository.dart';
import 'package:galaxy_novels_app/data/repositories/search_repository.dart';
import 'package:galaxy_novels_app/features/about/presentation/about_screen.dart';
import 'package:galaxy_novels_app/features/account/domain/auth_session.dart';

import 'helpers/fake_auth_repository.dart';
import 'helpers/fake_reader_preferences_repository.dart';

void main() {
  testWidgets('shows Galaxy Novels Arabic shell', (tester) async {
    await tester.pumpWidget(
      GalaxyNovelsApp(
        homeRepository: _TestHomeRepository(_homeData),
        catalogRepository: const _TestCatalogRepository(),
        novelRepository: const _TestNovelRepository(),
        searchRepository: const _TestSearchRepository.empty(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('الرئيسية'), findsWidgets);
    expect(find.text('المكتبة'), findsOneWidget);
    expect(find.text('التنزيلات'), findsOneWidget);
    expect(find.text('السجل'), findsOneWidget);
    expect(find.text('الترتيب'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('حسابي'),
      ),
      findsNothing,
    );
  });

  testWidgets('opens account screen and submits login credentials', (
    tester,
  ) async {
    final authRepository = FakeAuthRepository(
      initialState: const AuthSessionState.idle(),
    );
    await tester.pumpWidget(
      GalaxyNovelsApp(
        homeRepository: _TestHomeRepository(_homeData),
        catalogRepository: const _TestCatalogRepository(),
        novelRepository: const _TestNovelRepository(),
        authRepository: authRepository,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    expect(find.text('حسابي'), findsOneWidget);

    await tester.tap(find.text('حسابي'));
    await tester.pumpAndSettle();

    expect(find.text('تسجيل الدخول'), findsNWidgets(2));
    await tester.enterText(
      find.byKey(const ValueKey('login-username')),
      'reader@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('login-password')),
      'secret-value',
    );
    await tester.tap(find.byKey(const ValueKey('login-submit')));
    await tester.pump();

    expect(authRepository.lastLogin?.username, 'reader@example.com');
    expect(authRepository.lastLogin?.password, 'secret-value');
    expect(authRepository.lastLogin?.rememberSession, isTrue);
  });

  testWidgets('signed in account can log out', (tester) async {
    final authRepository = FakeAuthRepository(
      initialState: const AuthSessionState.authenticated(_testAuthUser),
    );
    await tester.pumpWidget(
      GalaxyNovelsApp(
        homeRepository: _TestHomeRepository(_homeData),
        catalogRepository: const _TestCatalogRepository(),
        novelRepository: const _TestNovelRepository(),
        authRepository: authRepository,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.text('حسابي'));
    await tester.pumpAndSettle();

    expect(find.text('قارئ الاختبار'), findsOneWidget);
    await tester.tap(find.text('تسجيل الخروج'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('login-submit')), findsOneWidget);
  });

  testWidgets('drawer exposes only working destinations and opens about', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 720);
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

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationDrawerDestination), findsNWidgets(3));
    expect(find.text('المفضلة'), findsNothing);
    expect(find.text('الاشتراك و VIP'), findsNothing);

    await tester.tap(find.text('حول التطبيق'));
    await tester.pumpAndSettle();

    expect(find.byType(AboutScreen), findsOneWidget);
    expect(find.text('الإصدار 0.1.0 (1)'), findsOneWidget);
    expect(find.text('تراخيص البرمجيات المفتوحة'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reader settings stay shared after closing and reopening', (
    tester,
  ) async {
    final preferencesRepository = FakeReaderPreferencesRepository();
    await tester.pumpWidget(
      GalaxyNovelsApp(
        homeRepository: _TestHomeRepository(_homeData),
        catalogRepository: const _TestCatalogRepository(),
        novelRepository: const _TestNovelRepository(),
        readerPreferencesRepository: preferencesRepository,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.text('إعدادات القراءة'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('reader-settings-preview')),
      findsOneWidget,
    );
    expect(find.text('100%'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('reader-font-increase')));
    await tester.pumpAndSettle();

    expect(preferencesRepository.value.fontScale, 1.1);
    expect(find.text('110%'), findsOneWidget);

    Navigator.of(
      tester.element(find.byKey(const ValueKey('reader-settings-preview'))),
    ).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.text('إعدادات القراءة'));
    await tester.pumpAndSettle();

    expect(find.text('110%'), findsOneWidget);
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
    expect(find.text('مختارة من المجرة'), findsOneWidget);

    await _scrollHomeDown(tester);

    expect(find.text('الفصل 5'), findsOneWidget);
  });

  testWidgets('home prefers local history and continues in native reader', (
    tester,
  ) async {
    final historyRepository = _TestReadingHistoryRepository();
    String? requestedContentApi;
    await tester.pumpWidget(
      GalaxyNovelsApp(
        homeRepository: _TestHomeRepository(_homeData),
        catalogRepository: const _TestCatalogRepository(),
        novelRepository: const _TestNovelRepository(),
        readerRepository: _TestReaderRepository(
          onLoad: (value) => requestedContentApi = value,
        ),
        readingHistoryRepository: historyRepository,
        downloadsRepository: FakeDownloadsRepository(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('اختبار المجرة'), findsOneWidget);

    await historyRepository.record(
      local_progress.ReadingProgress(
        novelId: 99,
        novelTitle: 'رواية السجل المحلي',
        chapterId: 2,
        chapterTitle: 'الفصل 2',
        contentApi: '/wp-json/wor-reader-app/v1/chapters/2',
        chapterPosition: 2,
        chaptersTotal: 100,
        updatedAt: DateTime.utc(2026, 6, 22),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('رواية السجل المحلي'), findsOneWidget);
    expect(find.text('2%'), findsOneWidget);
    expect(find.text('اختبار المجرة'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('continue-reading-tile')));
    await tester.pumpAndSettle();

    expect(requestedContentApi, '/wp-json/wor-reader-app/v1/chapters/2');
    expect(find.text('قارئ تجريبي'), findsOneWidget);
  });

  testWidgets('latest update opens its newest chapter in native reader', (
    tester,
  ) async {
    String? requestedContentApi;
    await tester.pumpWidget(
      GalaxyNovelsApp(
        homeRepository: _TestHomeRepository(_homeData),
        catalogRepository: const _TestCatalogRepository(),
        novelRepository: const _TestNovelRepository(),
        readerRepository: _TestReaderRepository(
          onLoad: (value) => requestedContentApi = value,
        ),
        readingHistoryRepository: _TestReadingHistoryRepository(),
        downloadsRepository: FakeDownloadsRepository(),
      ),
    );
    await tester.pumpAndSettle();

    final latestUpdate = find.byKey(const ValueKey('latest-update-5'));
    await _scrollHomeDown(tester);
    await tester.ensureVisible(latestUpdate);
    await tester.pumpAndSettle();
    await tester.tap(latestUpdate);
    await tester.pumpAndSettle();

    expect(requestedContentApi, '/wp-json/wor-reader-app/v1/chapters/5');
    expect(find.text('قارئ تجريبي'), findsOneWidget);
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
    expect(find.text('ابحث عن رواية...'), findsOneWidget);
    expect(find.text('2 رواية'), findsOneWidget);
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

  testWidgets('catalog search can use the public search index', (tester) async {
    await tester.pumpWidget(
      GalaxyNovelsApp(
        homeRepository: _TestHomeRepository(_homeData),
        catalogRepository: const _TestCatalogRepository(),
        novelRepository: const _TestNovelRepository(),
        searchRepository: const _TestSearchRepository.withExternalResult(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('المكتبة'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'خارجي');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    expect(find.text('بحث خارجي'), findsOneWidget);
    expect(find.text('مكتبة الاختبار'), findsNothing);
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
    await tester.tap(find.text('كل التصنيفات'));
    await tester.pumpAndSettle();

    expect(find.text('الحالة'), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(FilterChip),
        matching: find.text('مكتملة'),
      ),
    );
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
        readerRepository: const _TestReaderRepository(),
        downloadsRepository: FakeDownloadsRepository(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('المكتبة'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('مكتبة الاختبار'));
    await tester.pumpAndSettle();

    expect(find.text('تفاصيل الاختبار'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('هذه نبذة تفاصيل الاختبار.'),
      420,
      scrollable: _verticalScrollable(),
    );
    await tester.pumpAndSettle();

    expect(find.text('هذه نبذة تفاصيل الاختبار.'), findsOneWidget);
    expect(find.text('ابدأ القراءة'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('الفصل 1'),
      320,
      scrollable: _verticalScrollable(),
    );
    await tester.pumpAndSettle();

    expect(find.text('الفصل 1'), findsOneWidget);

    await tester.tap(find.text('ابدأ القراءة'));
    await tester.pumpAndSettle();

    expect(find.text('الفصل 1'), findsWidgets);
    expect(find.text('قارئ تجريبي'), findsOneWidget);
    expect(find.text('القارئ سيكون في المرحلة التالية'), findsNothing);
  });

  testWidgets('downloads a chapter from novel details', (tester) async {
    final downloadsRepository = FakeDownloadsRepository();
    await tester.pumpWidget(
      GalaxyNovelsApp(
        homeRepository: _TestHomeRepository(_homeData),
        catalogRepository: const _TestCatalogRepository(),
        novelRepository: const _TestNovelRepository(),
        readerRepository: const _TestReaderRepository(),
        downloadsRepository: downloadsRepository,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('المكتبة'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('مكتبة الاختبار'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byTooltip('تحميل الفصل'),
      320,
      scrollable: _verticalScrollable(),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('تحميل الفصل'));
    await tester.pumpAndSettle();

    expect(downloadsRepository.state.value.downloadedCount, 1);
    expect(find.byTooltip('محمل'), findsOneWidget);
  });

  testWidgets('opens batch download picker from novel details', (tester) async {
    await tester.pumpWidget(
      GalaxyNovelsApp(
        homeRepository: _TestHomeRepository(_homeData),
        catalogRepository: const _TestCatalogRepository(),
        novelRepository: const _TestNovelRepository(),
        readerRepository: const _TestReaderRepository(),
        downloadsRepository: FakeDownloadsRepository(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('المكتبة'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('مكتبة الاختبار'));
    await tester.pumpAndSettle();
    final batchDownloadButton = find.widgetWithText(TextButton, 'تحميل الفصول');
    await tester.scrollUntilVisible(
      batchDownloadButton,
      320,
      scrollable: _verticalScrollable(),
    );
    await tester.ensureVisible(batchDownloadButton);
    await tester.pumpAndSettle();
    await tester.tap(batchDownloadButton);
    await tester.pumpAndSettle();

    expect(find.text('0 محدد'), findsOneWidget);
    expect(find.text('آخر 10 فصول'), findsOneWidget);
    expect(find.text('غير المحمل'), findsOneWidget);
  });

  testWidgets('shows batch download progress over novel details', (
    tester,
  ) async {
    final downloadsRepository = FakeDownloadsRepository();
    await tester.pumpWidget(
      GalaxyNovelsApp(
        homeRepository: _TestHomeRepository(_homeData),
        catalogRepository: const _TestCatalogRepository(),
        novelRepository: const _TestNovelRepository(),
        readerRepository: const _TestReaderRepository(),
        downloadsRepository: downloadsRepository,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('المكتبة'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('مكتبة الاختبار'));
    await tester.pumpAndSettle();
    final batchDownloadButton = find.widgetWithText(TextButton, 'تحميل الفصول');
    await tester.scrollUntilVisible(
      batchDownloadButton,
      320,
      scrollable: _verticalScrollable(),
    );
    await tester.ensureVisible(batchDownloadButton);
    await tester.pumpAndSettle();
    await tester.tap(batchDownloadButton);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('download-chapter-1')));
    await tester.pump();
    await tester.tap(find.text('تحميل 1 فصل'));
    await tester.pumpAndSettle();

    expect(find.text('اكتمل التنزيل'), findsOneWidget);
    expect(find.text('تم تحميل 1 فصل بنجاح'), findsOneWidget);
    expect(downloadsRepository.state.value.downloadedCount, 1);
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

    await tester.scrollUntilVisible(
      find.text('هذه نبذة تفاصيل الاختبار.'),
      420,
      scrollable: _verticalScrollable(),
    );
    await tester.pumpAndSettle();

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

      await tester.scrollUntilVisible(
        find.text('لا توجد فصول متاحة للعرض الآن'),
        420,
        scrollable: _verticalScrollable(),
      );
      await tester.pumpAndSettle();

      expect(find.text('لا توجد فصول متاحة للعرض الآن'), findsOneWidget);
      expect(find.text('ابدأ القراءة'), findsNothing);
    },
  );

  testWidgets('rankings tab renders repository-provided novels', (
    tester,
  ) async {
    await tester.pumpWidget(
      GalaxyNovelsApp(
        homeRepository: _TestHomeRepository(_homeData),
        catalogRepository: const _TestCatalogRepository(),
        novelRepository: const _TestNovelRepository(),
        rankingsRepository: const _TestRankingsRepository(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('الترتيب'));
    await tester.pumpAndSettle();

    expect(find.text('ترتيب الاختبار'), findsOneWidget);
    expect(find.text('#1'), findsOneWidget);
    expect(find.textContaining('150 فصل'), findsOneWidget);
    expect(find.text('حارس النجوم'), findsNothing);
  });
}

Future<void> _scrollHomeDown(WidgetTester tester) async {
  final mainList = find.byWidgetPredicate(
    (widget) => widget is ListView && widget.scrollDirection == Axis.vertical,
  );

  await tester.drag(mainList, const Offset(0, -640));
  await tester.pumpAndSettle();
}

Finder _verticalScrollable() {
  return find.byWidgetPredicate(
    (widget) =>
        widget is Scrollable && widget.axisDirection == AxisDirection.down,
  );
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

const _testAuthUser = AuthUser(
  id: 7,
  displayName: 'قارئ الاختبار',
  avatar: null,
  vip: AuthVip(active: false, tier: '', label: '', expiresAt: null),
  xp: AuthXp(
    total: 120,
    today: 10,
    secondsTotal: 600,
    chaptersTotal: 8,
    rank: AuthRank(level: 2, display: 'مستكشف'),
  ),
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

class _TestRankingsRepository implements RankingsRepository {
  const _TestRankingsRepository();

  @override
  Future<RankingsData> loadRankings() async {
    return const RankingsData(
      period: 'month',
      items: [
        CatalogNovel(
          id: 77,
          title: 'ترتيب الاختبار',
          originalTitle: '',
          url: '/novel/ranking-test/',
          coverThumbnail: '',
          coverMedium: '',
          statusKey: 'ongoing',
          statusLabel: 'مستمرة',
          genres: [CatalogGenre(id: 1, name: 'أكشن', slug: 'action')],
          chaptersCount: 150,
          ratingAverage: 4.8,
          ratingCount: 22,
          views: 15000,
          updatedAt: null,
          manifest: '/manifest/novel-77.json',
        ),
      ],
    );
  }
}

class _TestSearchRepository implements SearchRepository {
  const _TestSearchRepository(this.index);

  const _TestSearchRepository.empty() : index = const SearchIndex(items: []);

  const _TestSearchRepository.withExternalResult()
    : index = const SearchIndex(
        items: [
          SearchIndexItem(
            id: 700,
            title: 'بحث خارجي',
            originalTitle: '',
            url: '/novel/external-search/',
            cover: '',
            genres: ['خيال'],
            chaptersCount: 77,
            statusLabel: 'مستمرة',
            views: 900,
            normalizedSearch: 'بحث خارجي',
            manifest:
                '/wp-content/uploads/wor-reader-cache/app/manifest/novel-700.json',
          ),
        ],
      );

  final SearchIndex index;

  @override
  Future<SearchIndex> loadSearchIndex() async => index;
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
          contentApi: '/wp-json/wor-reader-app/v1/chapters/1',
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

class _TestReaderRepository implements ReaderRepository {
  const _TestReaderRepository({this.onLoad});

  final ValueChanged<String>? onLoad;

  @override
  Future<ReaderChapterContent> loadChapter(String contentApi) async {
    onLoad?.call(contentApi);
    return const ReaderChapterContent(
      id: 1,
      novelId: 99,
      label: 'الفصل 1',
      title: '',
      displayTitle: 'الفصل 1',
      position: 1,
      total: 2,
      contentHtml: '<p>قارئ تجريبي</p>',
      navigation: ReaderChapterNavigation(
        previousApi: '',
        nextApi: '',
        previousId: 0,
        nextId: 0,
      ),
    );
  }
}

class _TestReadingHistoryRepository extends ChangeNotifier
    implements ReadingHistoryRepository {
  _TestReadingHistoryRepository({
    List<local_progress.ReadingProgress> items = const [],
  }) : _items = [...items];

  List<local_progress.ReadingProgress> _items;

  @override
  Future<List<local_progress.ReadingProgress>> load() async {
    return List.unmodifiable(_items);
  }

  @override
  Future<void> record(local_progress.ReadingProgress progress) async {
    _items = [
      progress,
      for (final item in _items)
        if (item.novelId != progress.novelId) item,
    ];
    notifyListeners();
  }
}
