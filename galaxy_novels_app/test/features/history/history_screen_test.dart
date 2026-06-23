import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/app/app_dependencies.dart';
import 'package:galaxy_novels_app/core/config/app_config.dart';
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
import 'package:galaxy_novels_app/features/history/presentation/history_screen.dart';

import '../../helpers/fake_reader_preferences_repository.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_favorites_repository.dart';

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
    await tester.pumpWidget(
      _HistoryTestApp(
        readingHistoryRepository: _TestReadingHistoryRepository(const []),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('لا يوجد سجل قراءة بعد'), findsOneWidget);
  });

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
}

class _HistoryTestApp extends StatelessWidget {
  const _HistoryTestApp({required this.readingHistoryRepository});

  final ReadingHistoryRepository readingHistoryRepository;

  @override
  Widget build(BuildContext context) {
    final downloadsRepository = FakeDownloadsRepository();
    return AppDependencies(
      config: const AppConfig(),
      homeRepository: const FakeHomeRepository(),
      catalogRepository: const FakeCatalogRepository(),
      novelRepository: const FakeNovelRepository(result: null),
      readerRepository: const _TestReaderRepository(),
      rankingsRepository: const FakeRankingsRepository(),
      searchRepository: const FakeSearchRepository(),
      readingHistoryRepository: readingHistoryRepository,
      downloadsRepository: downloadsRepository,
      downloadManager: DownloadManager(repository: downloadsRepository),
      readerPreferencesRepository: FakeReaderPreferencesRepository(),
      authRepository: FakeAuthRepository(),
      favoritesRepository: FakeFavoritesRepository(),
      child: const MaterialApp(
        locale: Locale('ar'),
        home: Scaffold(
          body: Directionality(
            textDirection: TextDirection.rtl,
            child: HistoryScreen(),
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
