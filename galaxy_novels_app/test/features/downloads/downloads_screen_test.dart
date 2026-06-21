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
import 'package:galaxy_novels_app/features/downloads/application/download_manager.dart';
import 'package:galaxy_novels_app/features/downloads/presentation/downloads_screen.dart';

void main() {
  testWidgets('renders downloaded chapters grouped by novel', (tester) async {
    await tester.pumpWidget(
      _DownloadsTestApp(
        downloadsRepository: FakeDownloadsRepository(
          chapters: [
            _downloadedChapter(
              novelId: 99,
              novelTitle: 'رواية الاختبار',
              chapterId: 1,
              chapterLabel: 'الفصل 1',
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('التنزيلات'), findsOneWidget);
    expect(find.text('1 / 100 فصل محمل'), findsOneWidget);
    expect(find.text('رواية الاختبار'), findsOneWidget);
    expect(find.text('الفصل 1'), findsOneWidget);
  });

  testWidgets('shows empty state when no chapters are downloaded', (
    tester,
  ) async {
    var openedLibrary = false;
    await tester.pumpWidget(
      _DownloadsTestApp(
        downloadsRepository: FakeDownloadsRepository(),
        onOpenLibrary: () => openedLibrary = true,
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('الفصول التي تحملها ستظهر هنا للقراءة بدون إنترنت'),
      findsOneWidget,
    );
    expect(find.text('فتح المكتبة'), findsOneWidget);

    await tester.tap(find.text('فتح المكتبة'));

    expect(openedLibrary, isTrue);
  });
}

class _DownloadsTestApp extends StatelessWidget {
  const _DownloadsTestApp({
    required this.downloadsRepository,
    this.onOpenLibrary,
  });

  final DownloadsRepository downloadsRepository;
  final VoidCallback? onOpenLibrary;

  @override
  Widget build(BuildContext context) {
    return AppDependencies(
      config: const AppConfig(),
      homeRepository: const FakeHomeRepository(),
      catalogRepository: const FakeCatalogRepository(),
      novelRepository: const FakeNovelRepository(result: null),
      readerRepository: const _TestReaderRepository(),
      rankingsRepository: const FakeRankingsRepository(),
      searchRepository: const FakeSearchRepository(),
      readingHistoryRepository: const _TestReadingHistoryRepository(),
      downloadsRepository: downloadsRepository,
      downloadManager: DownloadManager(repository: downloadsRepository),
      child: MaterialApp(
        locale: const Locale('ar'),
        theme: ThemeData(useMaterial3: true),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: DownloadsScreen(onOpenLibrary: onOpenLibrary),
        ),
      ),
    );
  }
}

DownloadedChapter _downloadedChapter({
  required int novelId,
  required String novelTitle,
  required int chapterId,
  required String chapterLabel,
}) {
  return DownloadedChapter(
    novelId: novelId,
    novelTitle: novelTitle,
    novelCover: '',
    chapterId: chapterId,
    chapterTitle: '',
    chapterLabel: chapterLabel,
    chapterPosition: chapterId,
    chaptersTotal: 1,
    contentApi: '/wp-json/wor-reader-app/v1/chapters/$chapterId',
    contentHtml: '<p>$chapterLabel</p>',
    plainTextPreview: chapterLabel,
    downloadedAt: DateTime.utc(2026, 6, 20),
    lastOpenedAt: null,
  );
}

class _TestReaderRepository implements ReaderRepository {
  const _TestReaderRepository();

  @override
  Future<ReaderChapterContent> loadChapter(String contentApi) async {
    return const ReaderChapterContent(
      id: 1,
      novelId: 99,
      label: 'الفصل 1',
      title: '',
      displayTitle: 'الفصل 1',
      position: 1,
      total: 1,
      contentHtml: '<p>الفصل 1</p>',
      navigation: ReaderChapterNavigation(
        previousApi: '',
        nextApi: '',
        previousId: 0,
        nextId: 0,
      ),
    );
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
