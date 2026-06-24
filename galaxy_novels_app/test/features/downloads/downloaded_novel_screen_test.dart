import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/app/app_dependencies.dart';
import 'package:galaxy_novels_app/core/config/app_config.dart';
import 'package:galaxy_novels_app/data/models/downloaded_chapter.dart';
import 'package:galaxy_novels_app/data/models/reader_content_data.dart';
import 'package:galaxy_novels_app/data/models/reading_progress.dart';
import 'package:galaxy_novels_app/data/repositories/fake_catalog_repository.dart';
import 'package:galaxy_novels_app/data/repositories/fake_downloads_repository.dart';
import 'package:galaxy_novels_app/data/repositories/fake_home_repository.dart';
import 'package:galaxy_novels_app/data/repositories/fake_novel_repository.dart';
import 'package:galaxy_novels_app/data/repositories/fake_rankings_repository.dart';
import 'package:galaxy_novels_app/data/repositories/fake_search_repository.dart';
import 'package:galaxy_novels_app/data/repositories/reader_repository.dart';
import 'package:galaxy_novels_app/data/repositories/reading_history_repository.dart';
import 'package:galaxy_novels_app/features/downloads/application/download_manager.dart';
import 'package:galaxy_novels_app/features/downloads/presentation/downloaded_novel_screen.dart';

import '../../helpers/fake_reader_preferences_repository.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_comments_repository.dart';
import '../../helpers/fake_favorites_repository.dart';
import '../../helpers/fake_novel_engagement_repository.dart';

void main() {
  testWidgets('opens a downloaded chapter in the native reader', (
    tester,
  ) async {
    final repository = FakeDownloadsRepository(
      chapters: [
        _downloadedChapter(1, '<p>محتوى محلي للفصل الأول</p>', 1024),
        _downloadedChapter(2, '<p>محتوى محلي للفصل الثاني</p>', 2048),
      ],
    );
    await tester.pumpWidget(_TestApp(repository: repository));
    await tester.pumpAndSettle();

    expect(find.text('رواية الاختبار'), findsOneWidget);
    expect(find.text('2 فصل متاح دون إنترنت'), findsOneWidget);
    expect(find.text('3.0 KB'), findsOneWidget);

    await tester.tap(find.text('الفصل 2'));
    await tester.pumpAndSettle();

    expect(find.text('محتوى محلي للفصل الثاني'), findsOneWidget);
    expect(find.text('تعذر تحميل الفصل'), findsNothing);
  });

  testWidgets('deletes one downloaded chapter after confirmation', (
    tester,
  ) async {
    final repository = FakeDownloadsRepository(
      chapters: [
        _downloadedChapter(1, '<p>الفصل الأول</p>', 1024),
        _downloadedChapter(2, '<p>الفصل الثاني</p>', 2048),
      ],
    );
    await tester.pumpWidget(_TestApp(repository: repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('حذف الفصل').first);
    await tester.pumpAndSettle();

    expect(find.text('حذف الفصل المحمل؟'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'حذف الفصل'));
    await tester.pumpAndSettle();

    expect(repository.state.value.downloadedCount, 1);
    expect(find.text('1 فصل متاح دون إنترنت'), findsOneWidget);
  });

  testWidgets('deletes every chapter downloaded for the novel', (tester) async {
    final repository = FakeDownloadsRepository(
      chapters: [_downloadedChapter(1, '<p>الفصل الأول</p>', 1024)],
    );
    await tester.pumpWidget(_TestApp(repository: repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('حذف تنزيلات الرواية'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'حذف الكل'));
    await tester.pumpAndSettle();

    expect(repository.state.value.downloadedCount, 0);
  });

  testWidgets('fits a narrow phone without overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = FakeDownloadsRepository(
      chapters: [_downloadedChapter(1, '<p>الفصل الأول</p>', 1024)],
    );

    await tester.pumpWidget(_TestApp(repository: repository));
    await tester.pumpAndSettle();

    expect(find.text('الفصول المحملة'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.repository});

  final FakeDownloadsRepository repository;

  @override
  Widget build(BuildContext context) {
    return AppDependencies(
      config: const AppConfig(),
      homeRepository: const FakeHomeRepository(),
      catalogRepository: const FakeCatalogRepository(),
      novelRepository: const FakeNovelRepository(result: null),
      readerRepository: const _OfflineOnlyReaderRepository(),
      rankingsRepository: const FakeRankingsRepository(),
      searchRepository: const FakeSearchRepository(),
      readingHistoryRepository: _TestReadingHistoryRepository(),
      downloadsRepository: repository,
      downloadManager: DownloadManager(repository: repository),
      readerPreferencesRepository: FakeReaderPreferencesRepository(),
      authRepository: FakeAuthRepository(),
      commentsRepository: FakeCommentsRepository.empty(),
      favoritesRepository: FakeFavoritesRepository(),
      novelEngagementRepository: FakeNovelEngagementRepository(),
      child: const MaterialApp(
        locale: Locale('ar'),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: DownloadedNovelScreen(novelId: 99),
        ),
      ),
    );
  }
}

DownloadedChapter _downloadedChapter(
  int id,
  String contentHtml,
  int contentByteSize,
) {
  return DownloadedChapter(
    novelId: 99,
    novelTitle: 'رواية الاختبار',
    novelCover: '',
    chapterId: id,
    chapterTitle: 'عنوان الفصل $id',
    chapterLabel: 'الفصل $id',
    chapterPosition: id,
    chaptersTotal: 20,
    contentApi: '/chapters/$id',
    contentHtml: contentHtml,
    plainTextPreview: 'الفصل $id',
    contentByteSize: contentByteSize,
    downloadedAt: DateTime.utc(2026, 6, 21, id),
    lastOpenedAt: null,
  );
}

class _OfflineOnlyReaderRepository implements ReaderRepository {
  const _OfflineOnlyReaderRepository();

  @override
  Future<ReaderChapterContent> loadChapter(String contentApi) {
    throw StateError('Network must not be used for downloaded content.');
  }
}

class _TestReadingHistoryRepository implements ReadingHistoryRepository {
  final List<ReadingProgress> records = [];

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
