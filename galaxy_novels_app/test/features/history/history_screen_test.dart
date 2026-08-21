import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/app/app_dependencies.dart';
import 'package:galaxy_novels_app/app/app_theme.dart';
import 'package:galaxy_novels_app/core/config/app_config.dart';
import 'package:galaxy_novels_app/data/models/reader_content_data.dart';
import 'package:galaxy_novels_app/data/models/reading_progress.dart';
import 'package:galaxy_novels_app/data/repositories/fake_catalog_repository.dart';
import 'package:galaxy_novels_app/data/repositories/fake_home_repository.dart';
import 'package:galaxy_novels_app/data/repositories/fake_novel_repository.dart';
import 'package:galaxy_novels_app/data/repositories/fake_rankings_repository.dart';
import 'package:galaxy_novels_app/data/repositories/fake_search_repository.dart';
import 'package:galaxy_novels_app/data/repositories/reader_repository.dart';
import 'package:galaxy_novels_app/data/repositories/reading_history_repository.dart';
import 'package:galaxy_novels_app/features/history/presentation/history_screen.dart';
import 'package:galaxy_novels_app/design_system/novel/galaxy_novel_cover.dart';

import '../../helpers/fake_reader_preferences_repository.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_comments_repository.dart';
import '../../helpers/fake_favorites_repository.dart';
import '../../helpers/fake_novel_engagement_repository.dart';
import '../../helpers/fake_vip_repository.dart';

void main() {
  testWidgets('renders saved reading history entries', (tester) async {
    await tester.pumpWidget(
      _HistoryTestApp(
        readingHistoryRepository: _TestReadingHistoryRepository([
          ReadingProgress(
            novelId: 99,
            novelTitle: 'رواية الاختبار',
            chapterId: 10,
            chapterTitle: 'الفصل 10',
            contentApi: '/wp-json/wor-reader-app/v1/chapters/10',
            updatedAt: DateTime.utc(2026, 6, 20, 10),
          ),
        ]),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('متابعة القراءة'), findsOneWidget);
    expect(find.text('رواية الاختبار'), findsOneWidget);
    expect(find.text('الفصل 10'), findsOneWidget);
    expect(find.textContaining('آخر قراءة'), findsOneWidget);
  });

  testWidgets('shows an empty state when no reading history exists', (
    tester,
  ) async {
    var openLibraryCount = 0;
    await tester.pumpWidget(
      _HistoryTestApp(
        readingHistoryRepository: _TestReadingHistoryRepository(const []),
        onOpenLibrary: () => openLibraryCount += 1,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('لا يوجد سجل قراءة بعد'), findsOneWidget);
    final openLibrary = find.ancestor(
      of: find.text('فتح المكتبة'),
      matching: find.byType(FilledButton),
    );
    expect(tester.getSize(openLibrary).height, greaterThanOrEqualTo(44));

    await tester.tap(openLibrary);

    expect(openLibraryCount, 1);
  });

  testWidgets('history error retries and can recover to the empty state', (
    tester,
  ) async {
    final repository = _RecoveringHistoryRepository();
    await tester.pumpWidget(
      _HistoryTestApp(readingHistoryRepository: repository),
    );
    await tester.pumpAndSettle();

    expect(find.text('تعذر تحميل سجل القراءة'), findsOneWidget);
    final retry = find.text('إعادة المحاولة');
    expect(retry, findsOneWidget);

    await tester.tap(retry);
    await tester.pumpAndSettle();

    expect(repository.loadCalls, 2);
    expect(find.text('لا يوجد سجل قراءة بعد'), findsOneWidget);
  });

  testWidgets(
    'standalone empty history opens a titled library route and returns',
    (tester) async {
      await tester.pumpWidget(
        _HistoryTestApp(
          readingHistoryRepository: _TestReadingHistoryRepository(const []),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('فتح المكتبة'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, 'المكتبة'), findsOneWidget);
      expect(find.byType(BackButton), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.byType(HistoryScreen), findsOneWidget);
      expect(find.text('لا يوجد سجل قراءة بعد'), findsOneWidget);
    },
  );

  testWidgets('does not invent a percentage when chapter totals are missing', (
    tester,
  ) async {
    await tester.pumpWidget(
      _HistoryTestApp(
        readingHistoryRepository: _TestReadingHistoryRepository([
          ReadingProgress(
            novelId: 99,
            novelTitle: 'رواية الاختبار',
            chapterId: 52,
            chapterTitle: 'الفصل 1',
            contentApi: '/wp-json/wor-reader-app/v1/chapters/52',
            updatedAt: DateTime.utc(2026, 6, 20, 10),
          ),
        ]),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('60%'), findsNothing);
    expect(find.text('موضع محفوظ'), findsOneWidget);
  });

  testWidgets('renders novel covers for history entries when available', (
    tester,
  ) async {
    await tester.pumpWidget(
      _HistoryTestApp(
        readingHistoryRepository: _TestReadingHistoryRepository([
          ReadingProgress(
            novelId: 99,
            novelTitle: 'رواية بغلاف',
            chapterId: 10,
            chapterTitle: 'الفصل 10',
            contentApi: '/wp-json/wor-reader-app/v1/chapters/10',
            coverUrl: '/wp-content/uploads/covers/history.jpg',
            updatedAt: DateTime.utc(2026, 6, 20, 10),
          ),
        ]),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(GalaxyNovelCover), findsWidgets);
  });

  testWidgets('opens VIP history entries with their private content API', (
    tester,
  ) async {
    final readerRepository = _RecordingReaderRepository();
    await tester.pumpWidget(
      _HistoryTestApp(
        readerRepository: readerRepository,
        readingHistoryRepository: _TestReadingHistoryRepository([
          ReadingProgress(
            novelId: 99,
            novelTitle: 'رواية VIP',
            chapterId: 275,
            chapterTitle: 'الفصل 275',
            contentApi: '/wp-json/wor-reader-app/v1/vip/chapters/275',
            updatedAt: DateTime.utc(2026, 6, 20, 10),
          ),
        ]),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('رواية VIP'));
    await tester.pumpAndSettle();

    expect(
      readerRepository.loadedApis,
      contains('/wp-json/wor-reader-app/v1/vip/chapters/275'),
    );
  });

  testWidgets('history rows reflow at 320 pixels and 200 percent text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      _HistoryTestApp(
        textScaler: const TextScaler.linear(2),
        readingHistoryRepository: _TestReadingHistoryRepository([
          ReadingProgress(
            novelId: 99,
            novelTitle: 'رواية الاختبار ذات العنوان الطويل',
            chapterId: 10,
            chapterTitle: 'الفصل العاشر ذو العنوان الطويل',
            contentApi: '/wp-json/wor-reader-app/v1/chapters/10',
            updatedAt: DateTime.utc(2026, 6, 20, 10),
          ),
          ReadingProgress(
            novelId: 100,
            novelTitle: 'رواية سابقة ذات عنوان طويل',
            chapterId: 11,
            chapterTitle: 'الفصل السابق ذو العنوان الطويل',
            contentApi: '/wp-json/wor-reader-app/v1/chapters/11',
            updatedAt: DateTime.utc(2026, 6, 19, 10),
          ),
        ]),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final openReader = find.bySemanticsLabel(
      'متابعة قراءة رواية الاختبار ذات العنوان الطويل، الفصل العاشر ذو العنوان الطويل',
    );
    expect(openReader, findsOneWidget);
    expect(tester.getSize(openReader).height, greaterThanOrEqualTo(44));
    expect(find.bySemanticsLabel(RegExp('حذف.*السجل')), findsNothing);

    await tester.pumpWidget(
      _HistoryTestApp(
        textScaler: const TextScaler.linear(2),
        onOpenLibrary: () {},
        readingHistoryRepository: _TestReadingHistoryRepository(const []),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final emptyAction = find.ancestor(
      of: find.text('فتح المكتبة'),
      matching: find.byType(FilledButton),
    );
    expect(tester.getSize(emptyAction).height, greaterThanOrEqualTo(44));
    expect(find.bySemanticsLabel('فتح المكتبة'), findsOneWidget);
  });
}

class _HistoryTestApp extends StatelessWidget {
  const _HistoryTestApp({
    required this.readingHistoryRepository,
    this.readerRepository = const _TestReaderRepository(),
    this.onOpenLibrary,
    this.textScaler = TextScaler.noScaling,
  });

  final ReadingHistoryRepository readingHistoryRepository;
  final ReaderRepository readerRepository;
  final VoidCallback? onOpenLibrary;
  final TextScaler textScaler;

  @override
  Widget build(BuildContext context) {
    return AppDependencies(
      config: const AppConfig(),
      homeRepository: const FakeHomeRepository(),
      catalogRepository: const FakeCatalogRepository(),
      novelRepository: const FakeNovelRepository(result: null),
      readerRepository: readerRepository,
      rankingsRepository: const FakeRankingsRepository(),
      searchRepository: const FakeSearchRepository(),
      readingHistoryRepository: readingHistoryRepository,
      readerPreferencesRepository: FakeReaderPreferencesRepository(),
      authRepository: FakeAuthRepository(),
      commentsRepository: FakeCommentsRepository.empty(),
      favoritesRepository: FakeFavoritesRepository(),
      novelEngagementRepository: FakeNovelEngagementRepository(),
      vipRepository: const FakeVipRepository(),
      child: MaterialApp(
        locale: const Locale('ar'),
        theme: AppTheme.dark(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: textScaler),
          child: child!,
        ),
        home: Scaffold(
          body: Directionality(
            textDirection: TextDirection.rtl,
            child: HistoryScreen(onOpenLibrary: onOpenLibrary),
          ),
        ),
      ),
    );
  }
}

class _TestReadingHistoryRepository implements ReadingHistoryRepository {
  _TestReadingHistoryRepository(this.records);

  final List<ReadingProgress> records;

  @override
  void addListener(VoidCallback listener) {}

  @override
  Future<List<ReadingProgress>> load() async => records;

  @override
  Future<void> record(ReadingProgress progress) async {}

  @override
  void removeListener(VoidCallback listener) {}
}

class _RecoveringHistoryRepository implements ReadingHistoryRepository {
  int loadCalls = 0;

  @override
  void addListener(VoidCallback listener) {}

  @override
  Future<List<ReadingProgress>> load() async {
    loadCalls += 1;
    if (loadCalls == 1) {
      throw StateError('offline');
    }
    return const [];
  }

  @override
  Future<void> record(ReadingProgress progress) async {}

  @override
  void removeListener(VoidCallback listener) {}
}

class _TestReaderRepository implements ReaderRepository {
  const _TestReaderRepository();

  @override
  Future<ReaderChapterContent> loadChapter(String contentApi) async {
    return const ReaderChapterContent(
      id: 10,
      novelId: 99,
      label: 'الفصل 10',
      title: '',
      displayTitle: 'الفصل 10',
      position: 1,
      total: 1,
      contentHtml: '<p>نص الفصل</p>',
      navigation: ReaderChapterNavigation(
        previousApi: '',
        nextApi: '',
        previousId: 0,
        nextId: 0,
      ),
    );
  }
}

class _RecordingReaderRepository implements ReaderRepository {
  final loadedApis = <String>[];

  @override
  Future<ReaderChapterContent> loadChapter(String contentApi) async {
    loadedApis.add(contentApi);
    return const ReaderChapterContent(
      id: 275,
      novelId: 99,
      label: 'الفصل 275',
      title: '',
      displayTitle: 'الفصل 275',
      position: 275,
      total: 360,
      contentHtml: '<p>نص VIP</p>',
      navigation: ReaderChapterNavigation(
        previousApi: '',
        nextApi: '',
        previousId: 0,
        nextId: 0,
      ),
    );
  }
}
