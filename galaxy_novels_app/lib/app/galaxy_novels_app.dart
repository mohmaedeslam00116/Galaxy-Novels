import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/config/app_config.dart';
import '../core/network/file_system_public_cache_store.dart';
import '../core/network/public_cache_client.dart';
import '../data/repositories/bootstrap_repository.dart';
import '../data/repositories/catalog_repository.dart';
import '../data/repositories/downloads_repository.dart';
import '../data/repositories/home_repository.dart';
import '../data/repositories/novel_repository.dart';
import '../data/repositories/public_catalog_repository.dart';
import '../data/repositories/public_home_repository.dart';
import '../data/repositories/public_novel_repository.dart';
import '../data/repositories/public_rankings_repository.dart';
import '../data/repositories/public_reader_repository.dart';
import '../data/repositories/public_search_repository.dart';
import '../data/repositories/reader_repository.dart';
import '../data/repositories/rankings_repository.dart';
import '../data/repositories/reading_history_repository.dart';
import '../data/repositories/search_repository.dart';
import '../data/repositories/shared_preferences_download_store.dart';
import '../data/repositories/shared_preferences_reading_history_store.dart';
import '../data/repositories/stored_downloads_repository.dart';
import '../data/repositories/stored_reading_history_repository.dart';
import '../features/shell/presentation/app_shell.dart';
import 'app_dependencies.dart';
import 'app_theme.dart';

final _defaultReadingHistoryRepository = StoredReadingHistoryRepository(
  store: SharedPreferencesReadingHistoryStore(),
);

class GalaxyNovelsApp extends StatefulWidget {
  const GalaxyNovelsApp({
    AppConfig? config,
    this.homeRepository,
    this.catalogRepository,
    this.novelRepository,
    this.readerRepository,
    this.rankingsRepository,
    this.searchRepository,
    this.readingHistoryRepository,
    this.downloadsRepository,
    super.key,
  }) : config = config ?? const AppConfig();

  final AppConfig config;
  final HomeRepository? homeRepository;
  final CatalogRepository? catalogRepository;
  final NovelRepository? novelRepository;
  final ReaderRepository? readerRepository;
  final RankingsRepository? rankingsRepository;
  final SearchRepository? searchRepository;
  final ReadingHistoryRepository? readingHistoryRepository;
  final DownloadsRepository? downloadsRepository;

  @override
  State<GalaxyNovelsApp> createState() => _GalaxyNovelsAppState();
}

class _GalaxyNovelsAppState extends State<GalaxyNovelsApp> {
  StoredDownloadsRepository? _defaultDownloadsRepository;

  @override
  void didUpdateWidget(covariant GalaxyNovelsApp oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.downloadsRepository != null) {
      return;
    }

    final switchedBackToDefault = oldWidget.downloadsRepository != null;
    final readerRepositoryChanged =
        widget.readerRepository != oldWidget.readerRepository;
    final configChanged = widget.config != oldWidget.config;
    final defaultDownloadsUsesConfig = widget.readerRepository == null;

    if (switchedBackToDefault ||
        readerRepositoryChanged ||
        (defaultDownloadsUsesConfig && configChanged)) {
      _defaultDownloadsRepository = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cacheClient = PublicCacheClient(
      config: widget.config,
      cacheStore: FileSystemPublicCacheStore(),
    );
    final bootstrapRepository = BootstrapRepository(cacheClient);
    final effectiveHomeRepository =
        widget.homeRepository ??
        PublicHomeRepository(
          bootstrapRepository: bootstrapRepository,
          cacheClient: cacheClient,
        );
    final effectiveCatalogRepository =
        widget.catalogRepository ??
        PublicCatalogRepository(
          bootstrapRepository: bootstrapRepository,
          cacheClient: cacheClient,
        );
    final effectiveNovelRepository =
        widget.novelRepository ??
        PublicNovelRepository(cacheClient: cacheClient);
    final effectiveReaderRepository =
        widget.readerRepository ??
        PublicReaderRepository(cacheClient: cacheClient);
    final effectiveDownloadsRepository =
        widget.downloadsRepository ??
        _defaultDownloadsRepositoryFor(effectiveReaderRepository);
    final effectiveRankingsRepository =
        widget.rankingsRepository ??
        PublicRankingsRepository(
          bootstrapRepository: bootstrapRepository,
          cacheClient: cacheClient,
        );
    final effectiveSearchRepository =
        widget.searchRepository ??
        PublicSearchRepository(
          bootstrapRepository: bootstrapRepository,
          cacheClient: cacheClient,
        );
    final effectiveReadingHistoryRepository =
        widget.readingHistoryRepository ?? _defaultReadingHistoryRepository;

    return AppDependencies(
      config: widget.config,
      homeRepository: effectiveHomeRepository,
      catalogRepository: effectiveCatalogRepository,
      novelRepository: effectiveNovelRepository,
      readerRepository: effectiveReaderRepository,
      rankingsRepository: effectiveRankingsRepository,
      searchRepository: effectiveSearchRepository,
      readingHistoryRepository: effectiveReadingHistoryRepository,
      downloadsRepository: effectiveDownloadsRepository,
      child: MaterialApp(
        title: 'مجرة الروايات',
        debugShowCheckedModeBanner: false,
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        home: const Directionality(
          textDirection: TextDirection.rtl,
          child: AppShell(),
        ),
      ),
    );
  }

  StoredDownloadsRepository _defaultDownloadsRepositoryFor(
    ReaderRepository readerRepository,
  ) {
    return _defaultDownloadsRepository ??= StoredDownloadsRepository(
      store: SharedPreferencesDownloadStore(),
      readerRepository: readerRepository,
    );
  }
}
