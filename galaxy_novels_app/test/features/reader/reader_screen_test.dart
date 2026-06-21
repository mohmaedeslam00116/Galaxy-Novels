import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/app/app_dependencies.dart';
import 'package:galaxy_novels_app/core/config/app_config.dart';
import 'package:galaxy_novels_app/data/models/downloaded_chapter.dart';
import 'package:galaxy_novels_app/data/models/reader_content_data.dart';
import 'package:galaxy_novels_app/data/models/reading_progress.dart';
import 'package:galaxy_novels_app/data/repositories/downloads_repository.dart';
import 'package:galaxy_novels_app/data/repositories/fake_catalog_repository.dart';
import 'package:galaxy_novels_app/data/repositories/fake_downloads_repository.dart';
import 'package:galaxy_novels_app/data/repositories/fake_home_repository.dart';
import 'package:galaxy_novels_app/data/repositories/fake_novel_repository.dart';
import 'package:galaxy_novels_app/data/repositories/fake_rankings_repository.dart';
import 'package:galaxy_novels_app/data/repositories/fake_search_repository.dart';
import 'package:galaxy_novels_app/data/repositories/reader_repository.dart';
import 'package:galaxy_novels_app/data/repositories/reading_history_repository.dart';
import 'package:galaxy_novels_app/features/reader/presentation/reader_screen.dart';

void main() {
  testWidgets('loads chapter content and renders it natively', (tester) async {
    await tester.pumpWidget(
      _ReaderTestApp(
        readerRepository: const _TestReaderRepository(),
        child: const ReaderScreen(
          contentApi: '/wp-json/wor-reader-app/v1/chapters/10',
          chapterTitle: 'الفصل 1',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('الفصل 1'), findsOneWidget);
    expect(find.text('عنوان الفصل'), findsOneWidget);
    expect(find.text('نص الفصل الأول'), findsOneWidget);
    expect(find.text('التالي'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await tester.tap(find.byKey(const ValueKey('reader-content-tap-area')));
    await tester.pumpAndSettle();

    expect(find.text('التالي'), findsOneWidget);

    await tester.tap(find.text('التالي'));
    await tester.pumpAndSettle();

    expect(find.text('عنوان الفصل التالي'), findsOneWidget);
    expect(find.text('نص الفصل التالي'), findsOneWidget);
  });

  testWidgets('toggles floating controls when tapping reader content', (
    tester,
  ) async {
    await tester.pumpWidget(
      _ReaderTestApp(
        readerRepository: const _TestReaderRepository(),
        child: const ReaderScreen(
          contentApi: '/wp-json/wor-reader-app/v1/chapters/10',
          chapterTitle: 'الفصل 1',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('التالي'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('reader-content-tap-area')));
    await tester.pumpAndSettle();

    expect(find.text('التالي'), findsOneWidget);

    await tester.tap(find.text('نص الفصل الأول'));
    await tester.pumpAndSettle();

    expect(find.text('التالي'), findsNothing);
  });

  testWidgets('opens reader settings and updates paragraph text size', (
    tester,
  ) async {
    await tester.pumpWidget(
      _ReaderTestApp(
        readerRepository: const _TestReaderRepository(),
        child: const ReaderScreen(
          contentApi: '/wp-json/wor-reader-app/v1/chapters/10',
          chapterTitle: 'الفصل 1',
        ),
      ),
    );
    await tester.pumpAndSettle();

    final beforeStyle = tester.widget<Text>(find.text('نص الفصل الأول')).style;

    await tester.tap(find.byKey(const ValueKey('reader-content-tap-area')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('reader-settings-button')));
    await tester.pumpAndSettle();

    expect(find.text('إعدادات القراءة'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('reader-font-increase')));
    await tester.pumpAndSettle();

    final afterStyle = tester.widget<Text>(find.text('نص الفصل الأول')).style;

    expect(afterStyle?.fontSize, greaterThan(beforeStyle?.fontSize ?? 0));
  });

  testWidgets('reader settings can switch to a light reading palette', (
    tester,
  ) async {
    await tester.pumpWidget(
      _ReaderTestApp(
        readerRepository: const _TestReaderRepository(),
        child: const ReaderScreen(
          contentApi: '/wp-json/wor-reader-app/v1/chapters/10',
          chapterTitle: 'الفصل 1',
        ),
      ),
    );
    await tester.pumpAndSettle();

    final seedColor = Theme.of(
      tester.element(find.byType(ReaderScreen)),
    ).colorScheme.primary;

    await tester.tap(find.byKey(const ValueKey('reader-content-tap-area')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('reader-settings-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('reader-palette-light')));
    await tester.pumpAndSettle();

    final background = tester.widget<ColoredBox>(
      find.byKey(const ValueKey('reader-background')),
    );

    expect(
      ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.light,
      ).surface,
      background.color,
    );
  });

  testWidgets('records reading progress when chapter content loads', (
    tester,
  ) async {
    final historyRepository = _TestReadingHistoryRepository();

    await tester.pumpWidget(
      _ReaderTestApp(
        readerRepository: const _TestReaderRepository(),
        readingHistoryRepository: historyRepository,
        child: const ReaderScreen(
          contentApi: '/wp-json/wor-reader-app/v1/chapters/10',
          chapterTitle: 'الفصل 1',
          novelTitle: 'رواية الاختبار',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(historyRepository.records, hasLength(1));
    expect(historyRepository.records.single.novelId, 1);
    expect(historyRepository.records.single.novelTitle, 'رواية الاختبار');
    expect(historyRepository.records.single.chapterId, 10);
    expect(historyRepository.records.single.chapterTitle, 'عنوان الفصل');
    expect(historyRepository.records.single.chapterPosition, 1);
    expect(historyRepository.records.single.chaptersTotal, 2);
  });

  testWidgets('shows an error when chapter content fails', (tester) async {
    await tester.pumpWidget(
      _ReaderTestApp(
        readerRepository: const _FailingReaderRepository(),
        child: const ReaderScreen(
          contentApi: '/wp-json/wor-reader-app/v1/chapters/10',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('تعذر تحميل الفصل'), findsOneWidget);
    expect(find.text('إعادة المحاولة'), findsOneWidget);
  });

  testWidgets('opens a downloaded chapter without using the network', (
    tester,
  ) async {
    final downloadsRepository = FakeDownloadsRepository(
      chapters: [
        DownloadedChapter(
          novelId: 7,
          novelTitle: 'رواية محلية',
          novelCover: '',
          chapterId: 70,
          chapterTitle: 'عنوان الفصل المحلي',
          chapterLabel: 'الفصل 7',
          chapterPosition: 7,
          chaptersTotal: 120,
          contentApi: '/chapters/70',
          contentHtml: '<p>هذا النص متاح دون إنترنت</p>',
          plainTextPreview: 'هذا النص متاح دون إنترنت',
          downloadedAt: DateTime.utc(2026, 6, 20),
          lastOpenedAt: null,
        ),
      ],
    );

    await tester.pumpWidget(
      _ReaderTestApp(
        readerRepository: const _FailingReaderRepository(),
        downloadsRepository: downloadsRepository,
        child: const ReaderScreen(
          contentApi: '/chapters/70',
          novelTitle: 'رواية محلية',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('هذا النص متاح دون إنترنت'), findsOneWidget);
    expect(find.text('تعذر تحميل الفصل'), findsNothing);
    expect(
      downloadsRepository.state.value.chapters.single.lastOpenedAt,
      isNotNull,
    );
  });
}

class _ReaderTestApp extends StatelessWidget {
  const _ReaderTestApp({
    required this.child,
    this.readerRepository = const _TestReaderRepository(),
    this.readingHistoryRepository,
    this.downloadsRepository,
  });

  final Widget child;
  final ReaderRepository readerRepository;
  final ReadingHistoryRepository? readingHistoryRepository;
  final DownloadsRepository? downloadsRepository;

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
      readingHistoryRepository:
          readingHistoryRepository ?? _TestReadingHistoryRepository(),
      downloadsRepository: downloadsRepository ?? FakeDownloadsRepository(),
      child: MaterialApp(
        locale: const Locale('ar'),
        home: Directionality(textDirection: TextDirection.rtl, child: child),
      ),
    );
  }
}

class _TestReaderRepository implements ReaderRepository {
  const _TestReaderRepository();

  @override
  Future<ReaderChapterContent> loadChapter(String contentApi) async {
    if (contentApi.endsWith('/11')) {
      return const ReaderChapterContent(
        id: 11,
        novelId: 1,
        label: 'الفصل 2',
        title: '',
        displayTitle: 'عنوان الفصل التالي',
        position: 2,
        total: 2,
        contentHtml: '<p>نص الفصل التالي</p>',
        navigation: ReaderChapterNavigation(
          previousApi: '/wp-json/wor-reader-app/v1/chapters/10',
          nextApi: '',
          previousId: 10,
          nextId: 0,
        ),
      );
    }

    return const ReaderChapterContent(
      id: 10,
      novelId: 1,
      label: 'الفصل 1',
      title: '',
      displayTitle: 'عنوان الفصل',
      position: 1,
      total: 2,
      contentHtml: '<p>نص الفصل الأول</p>',
      navigation: ReaderChapterNavigation(
        previousApi: '',
        nextApi: '/wp-json/wor-reader-app/v1/chapters/11',
        previousId: 0,
        nextId: 11,
      ),
    );
  }
}

class _FailingReaderRepository implements ReaderRepository {
  const _FailingReaderRepository();

  @override
  Future<ReaderChapterContent> loadChapter(String contentApi) async {
    throw Exception('reader failed');
  }
}

class _TestReadingHistoryRepository implements ReadingHistoryRepository {
  final records = <ReadingProgress>[];

  @override
  void addListener(VoidCallback listener) {}

  @override
  Future<List<ReadingProgress>> load() async => records;

  @override
  Future<void> record(ReadingProgress progress) async {
    records.add(progress);
  }

  @override
  void removeListener(VoidCallback listener) {}
}
