import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/app/app_dependencies.dart';
import 'package:galaxy_novels_app/core/config/app_config.dart';
import 'package:galaxy_novels_app/data/models/novel_details_data.dart';
import 'package:galaxy_novels_app/data/models/reader_content_data.dart';
import 'package:galaxy_novels_app/data/models/reading_progress.dart';
import 'package:galaxy_novels_app/data/repositories/fake_catalog_repository.dart';
import 'package:galaxy_novels_app/data/repositories/fake_downloads_repository.dart';
import 'package:galaxy_novels_app/data/repositories/fake_home_repository.dart';
import 'package:galaxy_novels_app/data/repositories/fake_rankings_repository.dart';
import 'package:galaxy_novels_app/data/repositories/fake_search_repository.dart';
import 'package:galaxy_novels_app/data/repositories/novel_repository.dart';
import 'package:galaxy_novels_app/data/repositories/reader_repository.dart';
import 'package:galaxy_novels_app/data/repositories/reading_history_repository.dart';
import 'package:galaxy_novels_app/features/downloads/application/download_manager.dart';
import 'package:galaxy_novels_app/features/novel_details/presentation/novel_details_screen.dart';
import 'package:galaxy_novels_app/features/novel_details/presentation/widgets/novel_chapter_tile.dart';

import '../../helpers/fake_reader_preferences_repository.dart';

void main() {
  testWidgets('builds long chapter lists lazily and searches locally', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final repository = _LongNovelRepository();
    await tester.pumpWidget(_TestApp(repository: repository));
    await tester.pumpAndSettle();

    final searchField = find.byKey(const ValueKey('chapter-search-field'));
    await tester.scrollUntilVisible(
      searchField,
      400,
      scrollable: _verticalScrollable(),
    );
    await tester.pumpAndSettle();

    expect(find.text('300 فصل'), findsOneWidget);
    expect(
      find.byType(NovelChapterTile, skipOffstage: false).evaluate().length,
      lessThan(40),
    );

    await tester.enterText(searchField, 'الفصل 250');
    await tester.pump();

    expect(find.text('1 نتيجة'), findsOneWidget);
    expect(find.byType(NovelChapterTile), findsOneWidget);
    expect(find.text('الفصل 250'), findsWidgets);
    expect(repository.loadCalls, 1);

    await tester.tap(find.byKey(const ValueKey('clear-chapter-search')));
    await tester.pump();

    expect(find.text('300 فصل'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Finder _verticalScrollable() {
  return find.byWidgetPredicate(
    (widget) =>
        widget is Scrollable && widget.axisDirection == AxisDirection.down,
  );
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.repository});

  final NovelRepository repository;

  @override
  Widget build(BuildContext context) {
    final downloadsRepository = FakeDownloadsRepository();
    return AppDependencies(
      config: const AppConfig(),
      homeRepository: const FakeHomeRepository(),
      catalogRepository: const FakeCatalogRepository(),
      novelRepository: repository,
      readerRepository: const _TestReaderRepository(),
      rankingsRepository: const FakeRankingsRepository(),
      searchRepository: const FakeSearchRepository(),
      readingHistoryRepository: const _TestReadingHistoryRepository(),
      downloadsRepository: downloadsRepository,
      downloadManager: DownloadManager(repository: downloadsRepository),
      readerPreferencesRepository: FakeReaderPreferencesRepository(),
      child: const MaterialApp(
        locale: Locale('ar'),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: NovelDetailsScreen(manifestPath: '/novel-long.json'),
        ),
      ),
    );
  }
}

class _LongNovelRepository implements NovelRepository {
  int loadCalls = 0;

  @override
  Future<NovelDetailsLoadResult> loadNovel(String manifestPath) async {
    loadCalls++;
    return NovelDetailsLoadResult(
      details: const NovelDetails(
        id: 500,
        title: 'رواية طويلة',
        originalTitle: '',
        url: '/novel/long/',
        coverThumbnail: '',
        coverMedium: '',
        coverLarge: '',
        statusKey: 'ongoing',
        statusLabel: 'مستمرة',
        country: '',
        author: 'كاتب الاختبار',
        translator: '',
        genres: [],
        chaptersCount: 300,
        firstChapterId: 1,
        firstChapterUrl: '/chapter-1/',
        ratingAverage: 4.5,
        ratingCount: 10,
        views: 1000,
        updatedAt: null,
        summary: '',
        chaptersManifest: '/chapters.json',
        vipScheduleManifest: '',
        manifest: '/novel-long.json',
      ),
      chapters: List.generate(300, (index) {
        final number = index + 1;
        return NovelChapter(
          id: number,
          position: number,
          number: '$number',
          label: 'الفصل $number',
          title: 'عنوان الفصل $number',
          url: '/chapter-$number/',
          contentApi: '/chapters/$number',
          dateLabel: 'اليوم',
          dateIso: null,
          views: 0,
          comments: 0,
          search: 'الفصل $number عنوان الفصل $number',
        );
      }),
    );
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
