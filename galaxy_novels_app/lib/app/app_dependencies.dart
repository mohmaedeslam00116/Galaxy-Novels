import 'package:flutter/widgets.dart';

import '../core/config/app_config.dart';
import '../data/repositories/catalog_repository.dart';
import '../data/repositories/downloads_repository.dart';
import '../data/repositories/home_repository.dart';
import '../data/repositories/novel_repository.dart';
import '../data/repositories/reader_repository.dart';
import '../data/repositories/rankings_repository.dart';
import '../data/repositories/reading_history_repository.dart';
import '../data/repositories/search_repository.dart';
import '../features/account/application/auth_repository.dart';
import '../features/comments/application/comments_repository.dart';
import '../features/downloads/application/download_manager.dart';
import '../features/favorites/application/favorites_repository.dart';
import '../features/novel_engagement/application/novel_engagement_repository.dart';
import '../features/reading_activity/application/reading_activity_recorder.dart';
import '../features/reader/application/reader_preferences_repository.dart';

class AppDependencies extends InheritedWidget {
  const AppDependencies({
    required this.config,
    required this.homeRepository,
    required this.catalogRepository,
    required this.novelRepository,
    required this.readerRepository,
    required this.rankingsRepository,
    required this.searchRepository,
    required this.readingHistoryRepository,
    required this.downloadsRepository,
    required this.downloadManager,
    required this.readerPreferencesRepository,
    required this.authRepository,
    required this.commentsRepository,
    required this.favoritesRepository,
    required this.novelEngagementRepository,
    this.readingActivityRecorder = const NoopReadingActivityRecorder(),
    required super.child,
    super.key,
  });

  final AppConfig config;
  final HomeRepository homeRepository;
  final CatalogRepository catalogRepository;
  final NovelRepository novelRepository;
  final ReaderRepository readerRepository;
  final RankingsRepository rankingsRepository;
  final SearchRepository searchRepository;
  final ReadingHistoryRepository readingHistoryRepository;
  final DownloadsRepository downloadsRepository;
  final DownloadManager downloadManager;
  final ReaderPreferencesRepository readerPreferencesRepository;
  final AuthRepository authRepository;
  final CommentsRepository commentsRepository;
  final FavoritesRepository favoritesRepository;
  final NovelEngagementRepository novelEngagementRepository;
  final ReadingActivityRecorder readingActivityRecorder;

  static AppDependencies of(BuildContext context) {
    final dependencies = context
        .dependOnInheritedWidgetOfExactType<AppDependencies>();

    assert(dependencies != null, 'AppDependencies was not found in context.');
    return dependencies!;
  }

  @override
  bool updateShouldNotify(AppDependencies oldWidget) {
    return config != oldWidget.config ||
        homeRepository != oldWidget.homeRepository ||
        catalogRepository != oldWidget.catalogRepository ||
        novelRepository != oldWidget.novelRepository ||
        readerRepository != oldWidget.readerRepository ||
        rankingsRepository != oldWidget.rankingsRepository ||
        searchRepository != oldWidget.searchRepository ||
        readingHistoryRepository != oldWidget.readingHistoryRepository ||
        downloadsRepository != oldWidget.downloadsRepository ||
        downloadManager != oldWidget.downloadManager ||
        readerPreferencesRepository != oldWidget.readerPreferencesRepository ||
        authRepository != oldWidget.authRepository ||
        commentsRepository != oldWidget.commentsRepository ||
        favoritesRepository != oldWidget.favoritesRepository ||
        novelEngagementRepository != oldWidget.novelEngagementRepository ||
        readingActivityRecorder != oldWidget.readingActivityRecorder;
  }
}
