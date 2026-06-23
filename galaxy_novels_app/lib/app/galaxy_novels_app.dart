import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/config/app_config.dart';
import '../core/network/file_system_public_cache_store.dart';
import '../core/network/private_api_client.dart';
import '../core/network/public_cache_client.dart';
import '../data/repositories/bootstrap_repository.dart';
import '../data/repositories/catalog_repository.dart';
import '../data/repositories/downloads_repository.dart';
import '../data/repositories/file_system_download_store.dart';
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
import '../features/account/application/auth_repository.dart';
import '../features/account/data/secure_auth_session_store.dart';
import '../features/account/data/session_auth_repository.dart';
import '../features/downloads/application/download_manager.dart';
import '../features/downloads/presentation/download_activity_layer.dart';
import '../features/favorites/application/favorites_repository.dart';
import '../features/favorites/data/favorites_remote_service.dart';
import '../features/favorites/data/shared_preferences_favorites_store.dart';
import '../features/favorites/data/synced_favorites_repository.dart';
import '../features/history/data/account_reading_history_repository.dart';
import '../features/history/data/reading_history_remote_service.dart';
import '../features/reader/application/reader_preferences_repository.dart';
import '../features/reader/data/shared_preferences_reader_preferences_store.dart';
import '../features/reader/data/stored_reader_preferences_repository.dart';
import '../features/shell/presentation/app_shell.dart';
import 'app_dependencies.dart';
import 'app_theme.dart';

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
    this.readerPreferencesRepository,
    this.authRepository,
    this.favoritesRepository,
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
  final ReaderPreferencesRepository? readerPreferencesRepository;
  final AuthRepository? authRepository;
  final FavoritesRepository? favoritesRepository;

  @override
  State<GalaxyNovelsApp> createState() => _GalaxyNovelsAppState();
}

class _GalaxyNovelsAppState extends State<GalaxyNovelsApp> {
  late final StoredReaderPreferencesRepository
  _defaultReaderPreferencesRepository = StoredReaderPreferencesRepository(
    store: SharedPreferencesReaderPreferencesStore(),
  );
  StoredDownloadsRepository? _defaultDownloadsRepository;
  DownloadsRepository? _downloadManagerRepository;
  DownloadManager? _downloadManager;
  SessionAuthRepository? _defaultAuthRepository;
  SyncedFavoritesRepository? _defaultFavoritesRepository;
  late final StoredReadingHistoryRepository
  _defaultLocalReadingHistoryRepository = StoredReadingHistoryRepository(
    store: SharedPreferencesReadingHistoryStore(),
  );
  AccountReadingHistoryRepository? _defaultAccountReadingHistoryRepository;
  PrivateApiClient? _privateApiClient;

  @override
  void didUpdateWidget(covariant GalaxyNovelsApp oldWidget) {
    super.didUpdateWidget(oldWidget);

    final authRepositoryChanged =
        widget.authRepository != oldWidget.authRepository;
    final favoritesRepositoryChanged =
        widget.favoritesRepository != oldWidget.favoritesRepository;
    final readingHistoryRepositoryChanged =
        widget.readingHistoryRepository != oldWidget.readingHistoryRepository;
    final configChanged = widget.config != oldWidget.config;
    if (favoritesRepositoryChanged || authRepositoryChanged || configChanged) {
      _defaultFavoritesRepository?.dispose();
      _defaultFavoritesRepository = null;
    }
    if (readingHistoryRepositoryChanged ||
        authRepositoryChanged ||
        configChanged) {
      _defaultAccountReadingHistoryRepository?.dispose();
      _defaultAccountReadingHistoryRepository = null;
    }
    final defaultAuthConfigChanged =
        widget.authRepository == null && widget.config != oldWidget.config;
    if (authRepositoryChanged || defaultAuthConfigChanged) {
      _defaultAuthRepository?.dispose();
      _defaultAuthRepository = null;
    }
    if (configChanged) {
      _privateApiClient = null;
    }

    if (widget.downloadsRepository != null) {
      return;
    }

    final switchedBackToDefault = oldWidget.downloadsRepository != null;
    final readerRepositoryChanged =
        widget.readerRepository != oldWidget.readerRepository;
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
    final effectiveDownloadManager = _downloadManagerFor(
      effectiveDownloadsRepository,
    );
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
    final effectiveReaderPreferencesRepository =
        widget.readerPreferencesRepository ??
        _defaultReaderPreferencesRepository;
    final effectiveAuthRepository =
        widget.authRepository ?? _defaultAuthRepositoryFor();
    final effectiveReadingHistoryRepository =
        widget.readingHistoryRepository ??
        _defaultReadingHistoryRepositoryFor(effectiveAuthRepository);
    final effectiveFavoritesRepository =
        widget.favoritesRepository ??
        _defaultFavoritesRepositoryFor(effectiveAuthRepository);
    unawaited(effectiveReaderPreferencesRepository.load());

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
      downloadManager: effectiveDownloadManager,
      readerPreferencesRepository: effectiveReaderPreferencesRepository,
      authRepository: effectiveAuthRepository,
      favoritesRepository: effectiveFavoritesRepository,
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
        builder: (context, child) => DownloadActivityLayer(
          manager: effectiveDownloadManager,
          child: child ?? const SizedBox.shrink(),
        ),
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
      store: FileSystemDownloadStore(
        legacyStore: SharedPreferencesDownloadStore(),
      ),
      readerRepository: readerRepository,
    );
  }

  DownloadManager _downloadManagerFor(DownloadsRepository repository) {
    if (_downloadManagerRepository == repository && _downloadManager != null) {
      return _downloadManager!;
    }

    final previousManager = _downloadManager;
    if (previousManager != null) {
      unawaited(previousManager.dispose());
    }
    _downloadManagerRepository = repository;
    return _downloadManager = DownloadManager(repository: repository);
  }

  SessionAuthRepository _defaultAuthRepositoryFor() {
    return _defaultAuthRepository ??= SessionAuthRepository(
      client: _privateApiClientFor(),
      sessionStore: SecureAuthSessionStore(),
    );
  }

  SyncedFavoritesRepository _defaultFavoritesRepositoryFor(
    AuthRepository authRepository,
  ) {
    return _defaultFavoritesRepository ??= SyncedFavoritesRepository(
      remoteService: FavoritesRemoteService(client: _privateApiClientFor()),
      localStore: SharedPreferencesFavoritesStore(),
      authRepository: authRepository,
    );
  }

  AccountReadingHistoryRepository _defaultReadingHistoryRepositoryFor(
    AuthRepository authRepository,
  ) {
    return _defaultAccountReadingHistoryRepository ??=
        AccountReadingHistoryRepository(
          localRepository: _defaultLocalReadingHistoryRepository,
          remoteService: ReadingHistoryRemoteService(
            client: _privateApiClientFor(),
          ),
          authRepository: authRepository,
        );
  }

  PrivateApiClient _privateApiClientFor() {
    return _privateApiClient ??= PrivateApiClient(config: widget.config);
  }

  @override
  void dispose() {
    final manager = _downloadManager;
    if (manager != null) {
      unawaited(manager.dispose());
    }
    _defaultAccountReadingHistoryRepository?.dispose();
    _defaultFavoritesRepository?.dispose();
    _defaultAuthRepository?.dispose();
    _defaultLocalReadingHistoryRepository.dispose();
    _defaultReaderPreferencesRepository.dispose();
    super.dispose();
  }
}
