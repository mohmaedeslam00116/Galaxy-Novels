import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../core/analytics/app_analytics.dart';
import '../core/analytics/app_analytics_navigator_observer.dart';
import '../core/analytics/firebase_app_analytics.dart';
import '../core/config/app_config.dart';
import '../core/network/app_cache_maintenance.dart';
import '../core/network/file_system_public_cache_store.dart';
import '../core/network/private_api_client.dart';
import '../core/network/public_cache_client.dart';
import '../data/repositories/bootstrap_repository.dart';
import '../data/repositories/catalog_repository.dart';
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
import '../data/repositories/shared_preferences_reading_history_store.dart';
import '../data/repositories/stored_reading_history_repository.dart';
import '../features/account/application/auth_repository.dart';
import '../features/account/data/secure_auth_session_store.dart';
import '../features/account/data/session_auth_repository.dart';
import '../features/account/domain/auth_session.dart';
import '../features/ads/application/home_ad_repository.dart';
import '../features/ads/application/ad_analytics.dart';
import '../features/ads/application/ad_privacy_options_repository.dart';
import '../features/ads/application/full_screen_ad_repository.dart';
import '../features/ads/application/reader_interstitial_policy_repository.dart';
import '../features/ads/application/rewarded_download_ad_repository.dart';
import '../features/ads/data/admob_initialization_coordinator.dart';
import '../features/ads/data/admob_ad_privacy_options_repository.dart';
import '../features/ads/data/admob_home_ad_repository.dart';
import '../features/ads/application/inline_native_ad_repository.dart';
import '../features/ads/data/admob_inline_native_ad_repository.dart';
import '../features/ads/data/admob_full_screen_ad_repository.dart';
import '../features/ads/data/admob_rewarded_download_ad_repository.dart';
import '../features/ads/data/firebase_reader_interstitial_policy_remote_source.dart';
import '../features/ads/data/shared_preferences_reader_interstitial_policy_cache.dart';
import '../features/ads/data/stored_reader_interstitial_policy_repository.dart';
import '../features/ads/presentation/app_open_ad_host.dart';
import '../features/about/application/app_version_info.dart';
import '../features/app_update/application/app_update_controller.dart';
import '../features/app_update/application/app_update_policy_repository.dart';
import '../features/app_update/application/app_update_snooze_store.dart';
import '../features/app_update/data/firebase_app_update_policy_remote_source.dart';
import '../features/app_update/data/play_store_app_update_gateway.dart';
import '../features/app_update/data/shared_preferences_app_update_policy_cache.dart';
import '../features/app_update/data/shared_preferences_app_update_snooze_store.dart';
import '../features/app_update/data/stored_app_update_policy_repository.dart';
import '../features/app_update/presentation/app_update_gate.dart';
import '../features/app_review/application/app_review_policy_repository.dart';
import '../features/app_review/application/app_review_prompt_controller.dart';
import '../features/app_review/application/app_review_prompt_store.dart';
import '../features/app_review/application/play_app_review_gateway.dart';
import '../features/app_review/data/firebase_app_review_policy_remote_source.dart';
import '../features/app_review/data/in_app_review_gateway.dart';
import '../features/app_review/data/shared_preferences_app_review_policy_cache.dart';
import '../features/app_review/data/shared_preferences_app_review_prompt_store.dart';
import '../features/app_review/data/stored_app_review_policy_repository.dart';
import '../features/app_review/presentation/app_review_prompt_navigator_observer.dart';
import '../features/onboarding/application/app_onboarding_controller.dart';
import '../features/onboarding/application/app_onboarding_store.dart';
import '../features/onboarding/data/shared_preferences_app_onboarding_store.dart';
import '../features/onboarding/domain/app_onboarding_state.dart';
import '../features/onboarding/presentation/app_onboarding_gate.dart';
import '../features/comments/application/comments_repository.dart';
import '../features/comments/data/public_comments_repository.dart';
import '../features/catalog/application/library_customization_repository.dart';
import '../features/catalog/data/shared_preferences_library_customization_store.dart';
import '../features/catalog/data/stored_library_customization_repository.dart';
import '../features/favorites/application/favorites_repository.dart';
import '../features/downloads/application/download_repository.dart';
import '../features/downloads/application/download_analytics.dart';
import '../features/downloads/data/background_download_transfer.dart';
import '../features/downloads/data/download_aware_reader_repository.dart';
import '../features/downloads/data/downloaded_chapter_file_store.dart';
import '../features/downloads/data/secure_download_key_store.dart';
import '../features/downloads/data/sqflite_download_store.dart';
import '../features/downloads/data/stored_download_repository.dart';
import '../features/downloads/data/firebase_download_analytics.dart';
import '../features/downloads/data/workmanager_download_resume_scheduler.dart';
import '../features/downloads/presentation/download_quota_prompt_host.dart';
import '../features/favorites/data/favorites_remote_service.dart';
import '../features/favorites/data/shared_preferences_favorites_store.dart';
import '../features/favorites/data/synced_favorites_repository.dart';
import '../features/history/data/account_reading_history_repository.dart';
import '../features/history/data/reading_history_remote_service.dart';
import '../features/home/application/home_customization_repository.dart';
import '../features/home/application/home_recommendation_exclusion_repository.dart';
import '../features/home/data/shared_preferences_home_recommendation_exclusion_store.dart';
import '../features/home/data/shared_preferences_home_customization_store.dart';
import '../features/home/data/stored_home_recommendation_exclusion_repository.dart';
import '../features/home/data/stored_home_customization_repository.dart';
import '../features/novel_engagement/application/novel_engagement_repository.dart';
import '../features/novel_engagement/data/private_novel_engagement_repository.dart';
import '../features/reading_activity/application/reading_activity_recorder.dart';
import '../features/reading_activity/data/reading_activity_remote_service.dart';
import '../features/reading_activity/data/shared_preferences_reading_activity_store.dart';
import '../features/reading_activity/data/synced_reading_activity_repository.dart';
import '../features/reader/application/reader_preferences_repository.dart';
import '../features/reader/application/reader_advanced_terminology_repository.dart';
import '../features/reader/application/reader_speech_controller.dart';
import '../features/reader/application/reader_term_replacement_repository.dart';
import '../features/reader/data/file_reader_advanced_terminology_state_store.dart';
import '../features/reader/data/repository_reader_speech_chapter_source.dart';
import '../features/reader/data/shared_preferences_reader_preferences_store.dart';
import '../features/reader/data/shared_preferences_reader_advanced_terminology_access_store.dart';
import '../features/reader/data/shared_preferences_reader_term_replacement_store.dart';
import '../features/reader/data/stored_reader_advanced_terminology_repository.dart';
import '../features/reader/data/stored_reader_preferences_repository.dart';
import '../features/reader/data/stored_reader_term_replacement_repository.dart';
import '../features/shell/presentation/app_shell.dart';
import '../features/startup/presentation/galaxy_splash_screen.dart';
import '../features/vip/application/vip_repository.dart';
import '../features/vip/data/private_vip_repository.dart';
import '../features/vip/data/vip_aware_reader_repository.dart';
import 'app_dependencies.dart';
import 'app_theme.dart';
import 'app_theme_controller.dart';

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
    this.readerPreferencesRepository,
    this.readerSpeechController,
    this.readerTermReplacementRepository,
    this.readerAdvancedTerminologyRepository,
    this.homeCustomizationRepository,
    this.libraryCustomizationRepository,
    this.homeRecommendationExclusionRepository,
    this.authRepository,
    this.commentsRepository,
    this.favoritesRepository,
    this.novelEngagementRepository,
    this.vipRepository,
    this.homeAdRepository,
    this.adPrivacyOptionsRepository,
    this.fullScreenAdRepository,
    this.inlineNativeAdRepository,
    this.downloadRepository,
    this.downloadAnalytics,
    this.rewardedDownloadAdRepository,
    this.readingActivityRecorder,
    this.cacheMaintenance,
    this.appAnalytics,
    this.appUpdateController,
    this.appReviewPromptController,
    this.appOnboardingController,
    this.appThemeController,
    this.splashDuration = Duration.zero,
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
  final ReaderPreferencesRepository? readerPreferencesRepository;
  final ReaderSpeechController? readerSpeechController;
  final ReaderTermReplacementRepository? readerTermReplacementRepository;
  final ReaderAdvancedTerminologyRepository?
  readerAdvancedTerminologyRepository;
  final HomeCustomizationRepository? homeCustomizationRepository;
  final LibraryCustomizationRepository? libraryCustomizationRepository;
  final HomeRecommendationExclusionRepository?
  homeRecommendationExclusionRepository;
  final AuthRepository? authRepository;
  final CommentsRepository? commentsRepository;
  final FavoritesRepository? favoritesRepository;
  final NovelEngagementRepository? novelEngagementRepository;
  final VipRepository? vipRepository;
  final HomeAdRepository? homeAdRepository;
  final AdPrivacyOptionsRepository? adPrivacyOptionsRepository;
  final FullScreenAdRepository? fullScreenAdRepository;
  final InlineNativeAdRepository? inlineNativeAdRepository;
  final DownloadRepository? downloadRepository;
  final DownloadAnalytics? downloadAnalytics;
  final RewardedDownloadAdRepository? rewardedDownloadAdRepository;
  final ReadingActivityRecorder? readingActivityRecorder;
  final AppCacheMaintenance? cacheMaintenance;
  final AppAnalytics? appAnalytics;
  final AppUpdateController? appUpdateController;
  final AppReviewPromptController? appReviewPromptController;
  final AppOnboardingController? appOnboardingController;
  final AppThemeController? appThemeController;
  final Duration splashDuration;

  @override
  State<GalaxyNovelsApp> createState() => _GalaxyNovelsAppState();
}

class _GalaxyNovelsAppState extends State<GalaxyNovelsApp> {
  static const _postStartupAdInitializationDelay = Duration(milliseconds: 1200);

  late final StoredReaderPreferencesRepository
  _defaultReaderPreferencesRepository = StoredReaderPreferencesRepository(
    store: SharedPreferencesReaderPreferencesStore(),
  );
  late final AppAnalytics _defaultAppAnalytics = Firebase.apps.isEmpty
      ? const NoopAppAnalytics()
      : FirebaseAppAnalytics();
  late final AppAnalyticsNavigatorObserver _analyticsNavigatorObserver =
      AppAnalyticsNavigatorObserver(
        analytics: widget.appAnalytics ?? _defaultAppAnalytics,
      );
  late final AdAnalytics _defaultAdAnalytics = AdAnalytics(
    widget.appAnalytics ?? _defaultAppAnalytics,
  );
  AppUpdatePolicyRepository? _defaultAppUpdatePolicyRepository;
  AppUpdateController? _defaultAppUpdateController;
  AppReviewPolicyRepository? _defaultAppReviewPolicyRepository;
  AppReviewPromptController? _defaultAppReviewPromptController;
  AppOnboardingController? _defaultAppOnboardingController;
  AppReviewPromptNavigatorObserver? _appReviewNavigatorObserver;
  late final StoredReaderTermReplacementRepository
  _defaultReaderTermReplacementRepository =
      StoredReaderTermReplacementRepository(
        store: SharedPreferencesReaderTermReplacementStore(),
      );
  late final StoredReaderAdvancedTerminologyRepository
  _defaultReaderAdvancedTerminologyRepository =
      StoredReaderAdvancedTerminologyRepository(
        stateStore: FileReaderAdvancedTerminologyStateStore(),
        accessStore: SharedPreferencesReaderAdvancedTerminologyAccessStore(),
      );
  late final StoredHomeCustomizationRepository
  _defaultHomeCustomizationRepository = StoredHomeCustomizationRepository(
    store: SharedPreferencesHomeCustomizationStore(),
  );
  late final StoredLibraryCustomizationRepository
  _defaultLibraryCustomizationRepository = StoredLibraryCustomizationRepository(
    store: SharedPreferencesLibraryCustomizationStore(),
  );
  late final StoredAppThemeController _defaultAppThemeController =
      StoredAppThemeController(store: SharedPreferencesAppThemeStore());
  SessionAuthRepository? _defaultAuthRepository;
  StoredHomeRecommendationExclusionRepository?
  _defaultHomeRecommendationExclusionRepository;
  SyncedFavoritesRepository? _defaultFavoritesRepository;
  PrivateNovelEngagementRepository? _defaultNovelEngagementRepository;
  PublicCommentsRepository? _defaultCommentsRepository;
  late final StoredReadingHistoryRepository
  _defaultLocalReadingHistoryRepository = StoredReadingHistoryRepository(
    store: SharedPreferencesReadingHistoryStore(),
  );
  AccountReadingHistoryRepository? _defaultAccountReadingHistoryRepository;
  SyncedReadingActivityRepository? _defaultReadingActivityRepository;
  PrivateVipRepository? _defaultVipRepository;
  late final AdMobInitializationCoordinator _defaultAdMobCoordinator =
      AdMobInitializationCoordinator();
  late final AdMobAdPrivacyOptionsRepository
  _defaultAdPrivacyOptionsRepository = AdMobAdPrivacyOptionsRepository(
    coordinator: _defaultAdMobCoordinator,
  );
  late final AdMobHomeAdRepository _defaultHomeAdRepository =
      AdMobHomeAdRepository(
        coordinator: _defaultAdMobCoordinator,
        analytics: _defaultAdAnalytics,
      );
  late final ReaderInterstitialPolicyRepository
  _defaultReaderInterstitialPolicyRepository =
      _createDefaultReaderInterstitialPolicyRepository();
  late final AdMobFullScreenAdRepository _defaultFullScreenAdRepository =
      AdMobFullScreenAdRepository(
        coordinator: _defaultAdMobCoordinator,
        analytics: _defaultAdAnalytics,
        readerPolicyRepository: _defaultReaderInterstitialPolicyRepository,
      );
  late final AdMobInlineNativeAdRepository _defaultInlineNativeAdRepository =
      AdMobInlineNativeAdRepository(
        coordinator: _defaultAdMobCoordinator,
        analytics: _defaultAdAnalytics,
      );
  late final AdMobRewardedDownloadAdRepository
  _defaultRewardedDownloadAdRepository = AdMobRewardedDownloadAdRepository(
    coordinator: _defaultAdMobCoordinator,
  );
  late final DownloadAnalytics _defaultDownloadAnalytics = Firebase.apps.isEmpty
      ? const NoopDownloadAnalytics()
      : FirebaseDownloadAnalytics();
  DownloadRepository _defaultDownloadRepository =
      const UnavailableDownloadRepository(isInitializing: true);
  DownloadRepository? _initializedDownloadRepository;
  AuthRepository? _downloadAuthRepository;
  DownloadRepository? _authBoundDownloadRepository;
  ReaderRepository? _downloadAwareReaderRepository;
  ReaderRepository? _downloadAwareNetworkRepository;
  DownloadRepository? _downloadAwareDownloads;
  PrivateApiClient? _privateApiClient;
  AuthRepository? _startupRestoredAuthRepository;
  HomeAdRepository? _scheduledHomeAdRepository;
  FullScreenAdRepository? _scheduledFullScreenAdRepository;
  int _adInitializationGeneration = 0;
  Timer? _adInitializationTimer;

  late final FileSystemPublicCacheStore _defaultPublicCacheStore =
      FileSystemPublicCacheStore();

  PublicCacheClient? _publicCacheClient;
  BootstrapRepository? _defaultBootstrapRepository;
  HomeRepository? _defaultHomeRepository;
  CatalogRepository? _defaultCatalogRepository;
  NovelRepository? _defaultNovelRepository;
  ReaderRepository? _defaultReaderRepository;
  RankingsRepository? _defaultRankingsRepository;
  SearchRepository? _defaultSearchRepository;
  RestorableReaderSpeechController? _speechRestorationController;
  ReaderRepository? _speechRestorationReaderRepository;
  ReaderTermReplacementRepository? _speechRestorationTermRepository;
  ReaderAdvancedTerminologyRepository? _speechRestorationAdvancedRepository;
  int _speechRestorationGeneration = 0;

  @override
  void didUpdateWidget(covariant GalaxyNovelsApp oldWidget) {
    super.didUpdateWidget(oldWidget);

    final authRepositoryChanged =
        widget.authRepository != oldWidget.authRepository;
    final favoritesRepositoryChanged =
        widget.favoritesRepository != oldWidget.favoritesRepository;
    final readingHistoryRepositoryChanged =
        widget.readingHistoryRepository != oldWidget.readingHistoryRepository;
    final readingActivityRecorderChanged =
        widget.readingActivityRecorder != oldWidget.readingActivityRecorder;
    final vipRepositoryChanged =
        widget.vipRepository != oldWidget.vipRepository;
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
    if (authRepositoryChanged ||
        configChanged ||
        widget.homeRecommendationExclusionRepository !=
            oldWidget.homeRecommendationExclusionRepository) {
      _defaultHomeRecommendationExclusionRepository?.dispose();
      _defaultHomeRecommendationExclusionRepository = null;
    }
    if (readingActivityRecorderChanged ||
        authRepositoryChanged ||
        configChanged) {
      _defaultReadingActivityRepository?.dispose();
      _defaultReadingActivityRepository = null;
    }
    final defaultAuthConfigChanged =
        widget.authRepository == null && widget.config != oldWidget.config;
    if (authRepositoryChanged || defaultAuthConfigChanged) {
      _defaultAuthRepository?.dispose();
      _defaultAuthRepository = null;
    }
    if (configChanged) {
      _privateApiClient = null;
      _defaultNovelEngagementRepository = null;
      _defaultCommentsRepository = null;
      _defaultVipRepository = null;
      _publicCacheClient = null;
      _defaultBootstrapRepository = null;
      _defaultHomeRepository = null;
      _defaultCatalogRepository = null;
      _defaultNovelRepository = null;
      _defaultReaderRepository = null;
      _defaultRankingsRepository = null;
      _defaultSearchRepository = null;
    }

    if (vipRepositoryChanged) {
      _defaultReaderRepository = null;
    }

    final readerPreferencesRepositoryChanged =
        widget.readerPreferencesRepository !=
        oldWidget.readerPreferencesRepository;
    final readerTermReplacementRepositoryChanged =
        widget.readerTermReplacementRepository !=
        oldWidget.readerTermReplacementRepository;
    final readerAdvancedTerminologyRepositoryChanged =
        widget.readerAdvancedTerminologyRepository !=
        oldWidget.readerAdvancedTerminologyRepository;
    final homeCustomizationRepositoryChanged =
        widget.homeCustomizationRepository !=
        oldWidget.homeCustomizationRepository;
    final libraryCustomizationRepositoryChanged =
        widget.libraryCustomizationRepository !=
        oldWidget.libraryCustomizationRepository;
    final appThemeControllerChanged =
        widget.appThemeController != oldWidget.appThemeController;
    final appUpdateControllerChanged =
        widget.appUpdateController != oldWidget.appUpdateController;
    final appReviewPromptControllerChanged =
        widget.appReviewPromptController != oldWidget.appReviewPromptController;
    final appOnboardingControllerChanged =
        widget.appOnboardingController != oldWidget.appOnboardingController;
    final homeAdRepositoryChanged =
        widget.homeAdRepository != oldWidget.homeAdRepository;
    final fullScreenAdRepositoryChanged =
        widget.fullScreenAdRepository != oldWidget.fullScreenAdRepository;

    if (readerPreferencesRepositoryChanged) {
      unawaited(
        (widget.readerPreferencesRepository ??
                _defaultReaderPreferencesRepository)
            .load(),
      );
    }
    if (readerTermReplacementRepositoryChanged) {
      unawaited(
        (widget.readerTermReplacementRepository ??
                _defaultReaderTermReplacementRepository)
            .load(),
      );
    }
    if (readerAdvancedTerminologyRepositoryChanged) {
      unawaited(
        (widget.readerAdvancedTerminologyRepository ??
                _defaultReaderAdvancedTerminologyRepository)
            .load(),
      );
    }
    if (homeCustomizationRepositoryChanged) {
      unawaited(
        (widget.homeCustomizationRepository ??
                _defaultHomeCustomizationRepository)
            .load(),
      );
    }
    if (libraryCustomizationRepositoryChanged) {
      unawaited(
        (widget.libraryCustomizationRepository ??
                _defaultLibraryCustomizationRepository)
            .load(),
      );
    }
    if (appThemeControllerChanged) {
      unawaited(
        (widget.appThemeController ?? _defaultAppThemeController).load(),
      );
    }
    if (appUpdateControllerChanged) {
      unawaited(
        (widget.appUpdateController ?? _defaultAppUpdateControllerFor())
            .initialize(),
      );
    }
    if (appReviewPromptControllerChanged) {
      unawaited(
        (widget.appReviewPromptController ??
                _defaultAppReviewPromptControllerFor())
            .initialize(),
      );
    }
    if (appOnboardingControllerChanged) {
      unawaited(
        (widget.appOnboardingController ?? _defaultAppOnboardingControllerFor())
            .initialize(),
      );
    }
    if (homeAdRepositoryChanged || fullScreenAdRepositoryChanged) {
      _scheduleAdInitialization(
        homeAdRepository: widget.homeAdRepository ?? _defaultHomeAdRepository,
        fullScreenAdRepository:
            widget.fullScreenAdRepository ?? _defaultFullScreenAdRepository,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    unawaited(
      (widget.readerPreferencesRepository ??
              _defaultReaderPreferencesRepository)
          .load(),
    );
    unawaited(
      (widget.readerTermReplacementRepository ??
              _defaultReaderTermReplacementRepository)
          .load(),
    );
    unawaited(
      (widget.readerAdvancedTerminologyRepository ??
              _defaultReaderAdvancedTerminologyRepository)
          .load(),
    );
    unawaited(
      (widget.homeCustomizationRepository ??
              _defaultHomeCustomizationRepository)
          .load(),
    );
    unawaited(
      (widget.libraryCustomizationRepository ??
              _defaultLibraryCustomizationRepository)
          .load(),
    );
    unawaited((widget.appThemeController ?? _defaultAppThemeController).load());
    unawaited(
      (widget.appUpdateController ?? _defaultAppUpdateControllerFor())
          .initialize(),
    );
    unawaited(
      (widget.appReviewPromptController ??
              _defaultAppReviewPromptControllerFor())
          .initialize(),
    );
    unawaited(
      (widget.appOnboardingController ?? _defaultAppOnboardingControllerFor())
          .initialize(),
    );
    _scheduleAdInitialization(
      homeAdRepository: widget.homeAdRepository ?? _defaultHomeAdRepository,
      fullScreenAdRepository:
          widget.fullScreenAdRepository ?? _defaultFullScreenAdRepository,
    );
    if (widget.downloadRepository == null) {
      unawaited(_initializeDefaultDownloads());
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveAppAnalytics = widget.appAnalytics ?? _defaultAppAnalytics;
    final effectiveHomeRepository =
        widget.homeRepository ?? _defaultHomeRepositoryFor();
    final effectiveCatalogRepository =
        widget.catalogRepository ?? _defaultCatalogRepositoryFor();
    final effectiveNovelRepository =
        widget.novelRepository ?? _defaultNovelRepositoryFor();
    final defaultPrivateVipRepository = _defaultVipRepositoryFor();
    final effectiveVipRepository =
        widget.vipRepository ?? defaultPrivateVipRepository;
    final networkReaderRepository =
        widget.readerRepository ?? _defaultReaderRepositoryFor();
    final effectiveAuthRepository =
        widget.authRepository ?? _defaultAuthRepositoryFor();
    final effectiveDownloadRepository =
        widget.downloadRepository ?? _defaultDownloadRepository;
    final effectiveDownloadAnalytics =
        widget.downloadAnalytics ?? _defaultDownloadAnalytics;
    _bindDownloadsToAuth(effectiveDownloadRepository, effectiveAuthRepository);
    final effectiveReaderRepository = _readerRepositoryWithDownloads(
      networkReaderRepository,
      effectiveDownloadRepository,
    );
    final effectiveRewardedDownloadAdRepository =
        widget.rewardedDownloadAdRepository ??
        _defaultRewardedDownloadAdRepository;
    _restoreAuthSessionOnStartup(effectiveAuthRepository);
    final effectiveRankingsRepository =
        widget.rankingsRepository ?? _defaultRankingsRepositoryFor();
    final effectiveSearchRepository =
        widget.searchRepository ?? _defaultSearchRepositoryFor();
    final effectiveReaderPreferencesRepository =
        widget.readerPreferencesRepository ??
        _defaultReaderPreferencesRepository;
    final effectiveReaderTermReplacementRepository =
        widget.readerTermReplacementRepository ??
        _defaultReaderTermReplacementRepository;
    final effectiveReaderAdvancedTerminologyRepository =
        widget.readerAdvancedTerminologyRepository ??
        _defaultReaderAdvancedTerminologyRepository;
    _scheduleSpeechSessionRestoration(
      controller: widget.readerSpeechController,
      readerRepository: effectiveReaderRepository,
      termRepository: effectiveReaderTermReplacementRepository,
      advancedRepository: effectiveReaderAdvancedTerminologyRepository,
    );
    final effectiveHomeCustomizationRepository =
        widget.homeCustomizationRepository ??
        _defaultHomeCustomizationRepository;
    final effectiveLibraryCustomizationRepository =
        widget.libraryCustomizationRepository ??
        _defaultLibraryCustomizationRepository;
    final effectiveReadingHistoryRepository =
        widget.readingHistoryRepository ??
        _defaultReadingHistoryRepositoryFor(effectiveAuthRepository);
    final effectiveHomeRecommendationExclusionRepository =
        widget.homeRecommendationExclusionRepository ??
        _defaultHomeRecommendationExclusionRepositoryFor(
          effectiveAuthRepository,
        );
    final effectiveFavoritesRepository =
        widget.favoritesRepository ??
        _defaultFavoritesRepositoryFor(effectiveAuthRepository);
    final effectiveCommentsRepository =
        widget.commentsRepository ?? _defaultCommentsRepositoryFor();
    final effectiveNovelEngagementRepository =
        widget.novelEngagementRepository ??
        _defaultNovelEngagementRepositoryFor();
    final effectiveReadingActivityRecorder =
        widget.readingActivityRecorder ??
        _defaultReadingActivityRepositoryFor(effectiveAuthRepository);
    final effectiveHomeAdRepository =
        widget.homeAdRepository ?? _defaultHomeAdRepository;
    final effectiveAdPrivacyOptionsRepository =
        widget.adPrivacyOptionsRepository ?? _defaultAdPrivacyOptionsRepository;
    final effectiveFullScreenAdRepository =
        widget.fullScreenAdRepository ?? _defaultFullScreenAdRepository;
    final effectiveInlineNativeAdRepository =
        widget.inlineNativeAdRepository ?? _defaultInlineNativeAdRepository;
    final effectiveAppThemeController =
        widget.appThemeController ?? _defaultAppThemeController;
    final effectiveAppUpdateController =
        widget.appUpdateController ?? _defaultAppUpdateControllerFor();
    final effectiveAppReviewPromptController =
        widget.appReviewPromptController ??
        _defaultAppReviewPromptControllerFor();
    final effectiveAppOnboardingController =
        widget.appOnboardingController ?? _defaultAppOnboardingControllerFor();
    final reviewNavigatorObserver = _appReviewNavigatorObserver ??=
        AppReviewPromptNavigatorObserver(
          controller: effectiveAppReviewPromptController,
          isForcedUpdateActive: () =>
              effectiveAppUpdateController.state.blocksApplication,
          presentationBlocker: effectiveAppUpdateController,
        );
    reviewNavigatorObserver.update(
      controller: effectiveAppReviewPromptController,
      isForcedUpdateActive: () =>
          effectiveAppUpdateController.state.blocksApplication,
      presentationBlocker: effectiveAppUpdateController,
    );

    return AppThemeControllerScope(
      controller: effectiveAppThemeController,
      child: ValueListenableBuilder<AppThemeChoice>(
        valueListenable: effectiveAppThemeController,
        builder: (context, appThemeChoice, child) {
          final activeTheme = _themeFor(appThemeChoice);
          final disableAnimations = View.of(
            context,
          ).platformDispatcher.accessibilityFeatures.disableAnimations;
          return LibraryCustomizationRepositoryScope(
            repository: effectiveLibraryCustomizationRepository,
            child: HomeCustomizationRepositoryScope(
              repository: effectiveHomeCustomizationRepository,
              child: AppDependencies(
                config: widget.config,
                homeRepository: effectiveHomeRepository,
                catalogRepository: effectiveCatalogRepository,
                novelRepository: effectiveNovelRepository,
                readerRepository: effectiveReaderRepository,
                rankingsRepository: effectiveRankingsRepository,
                searchRepository: effectiveSearchRepository,
                readingHistoryRepository: effectiveReadingHistoryRepository,
                readerPreferencesRepository:
                    effectiveReaderPreferencesRepository,
                readerSpeechController: widget.readerSpeechController,
                readerTermReplacementRepository:
                    effectiveReaderTermReplacementRepository,
                readerAdvancedTerminologyRepository:
                    effectiveReaderAdvancedTerminologyRepository,
                homeRecommendationExclusionRepository:
                    effectiveHomeRecommendationExclusionRepository,
                authRepository: effectiveAuthRepository,
                commentsRepository: effectiveCommentsRepository,
                favoritesRepository: effectiveFavoritesRepository,
                novelEngagementRepository: effectiveNovelEngagementRepository,
                vipRepository: effectiveVipRepository,
                homeAdRepository: effectiveHomeAdRepository,
                adPrivacyOptionsRepository: effectiveAdPrivacyOptionsRepository,
                fullScreenAdRepository: effectiveFullScreenAdRepository,
                inlineNativeAdRepository: effectiveInlineNativeAdRepository,
                downloadRepository: effectiveDownloadRepository,
                downloadAnalytics: effectiveDownloadAnalytics,
                rewardedDownloadAdRepository:
                    effectiveRewardedDownloadAdRepository,
                readingActivityRecorder: effectiveReadingActivityRecorder,
                cacheMaintenance:
                    widget.cacheMaintenance ?? _defaultPublicCacheStore,
                appUpdateController: effectiveAppUpdateController,
                appReviewPromptController: effectiveAppReviewPromptController,
                appOnboardingController: effectiveAppOnboardingController,
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
                  theme: activeTheme,
                  darkTheme: activeTheme,
                  themeMode: appThemeChoice.themeMode,
                  themeAnimationDuration: disableAnimations
                      ? Duration.zero
                      : AppVisualMetrics.themeTransition,
                  themeAnimationCurve: Curves.easeOutCubic,
                  navigatorObservers: [
                    _analyticsNavigatorObserver,
                    reviewNavigatorObserver,
                  ],
                  builder: (context, child) {
                    return AnnotatedRegion<SystemUiOverlayStyle>(
                      value: AppTheme.systemOverlayStyleFor(Theme.of(context)),
                      child: child ?? const SizedBox.shrink(),
                    );
                  },
                  home: Directionality(
                    textDirection: TextDirection.rtl,
                    child: GalaxySplashGate(
                      duration: widget.splashDuration,
                      child: AppUpdateGate(
                        controller: effectiveAppUpdateController,
                        child: AppOnboardingGate(
                          controller: effectiveAppOnboardingController,
                          child: AppOpenAdHost(
                            authRepository: effectiveAuthRepository,
                            ads: effectiveFullScreenAdRepository,
                            suppressColdStartAd:
                                effectiveAppOnboardingController
                                    .suppressColdStartAdForSession,
                            child: DownloadQuotaPromptHost(
                              repository: effectiveDownloadRepository,
                              rewardedAds:
                                  effectiveRewardedDownloadAdRepository,
                              downloadAnalytics: effectiveDownloadAnalytics,
                              child: AppShell(analytics: effectiveAppAnalytics),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  SessionAuthRepository _defaultAuthRepositoryFor() {
    return _defaultAuthRepository ??= SessionAuthRepository(
      client: _privateApiClientFor(),
      sessionStore: SecureAuthSessionStore(),
    );
  }

  StoredHomeRecommendationExclusionRepository
  _defaultHomeRecommendationExclusionRepositoryFor(
    AuthRepository authRepository,
  ) {
    return _defaultHomeRecommendationExclusionRepository ??=
        StoredHomeRecommendationExclusionRepository(
          store: SharedPreferencesHomeRecommendationExclusionStore(),
          authRepository: authRepository,
        );
  }

  Future<void> _initializeDefaultDownloads() async {
    SqfliteDownloadStore? store;
    StoredDownloadRepository? repository;
    try {
      final supportDirectory = await getApplicationSupportDirectory();
      store = await SqfliteDownloadStore.open();
      repository = StoredDownloadRepository(
        store: store,
        transfer: BackgroundDownloadTransfer(),
        fileStore: DownloadedChapterFileStore(
          rootDirectory: Directory(
            path.join(supportDirectory.path, 'downloads', 'chapters'),
          ),
          keyStore: SecureDownloadKeyStore(),
        ),
        scheduler: WorkmanagerDownloadResumeScheduler(),
        config: widget.config,
        sessionStore: SecureAuthSessionStore(),
      );
      await repository.initialize();
      if (!mounted || widget.downloadRepository != null) {
        repository.dispose();
        await store.close();
        return;
      }
      final initializedRepository = repository;
      _initializedDownloadRepository = initializedRepository;
      setState(() => _defaultDownloadRepository = initializedRepository);
    } on MissingPluginException catch (error) {
      await _recoverFromDownloadInitializationFailure(repository, store, error);
    } on PlatformException catch (error) {
      await _recoverFromDownloadInitializationFailure(repository, store, error);
    } on FileSystemException catch (error) {
      await _recoverFromDownloadInitializationFailure(repository, store, error);
    } on DatabaseException catch (error) {
      await _recoverFromDownloadInitializationFailure(repository, store, error);
    }
  }

  Future<void> _recoverFromDownloadInitializationFailure(
    StoredDownloadRepository? repository,
    SqfliteDownloadStore? store,
    Object error,
  ) async {
    debugPrint('Download initialization failed: ${error.runtimeType}');
    await repository?.shutdown();
    await store?.close();
    if (!mounted || widget.downloadRepository != null) return;
    setState(() {
      _defaultDownloadRepository = const UnavailableDownloadRepository();
    });
  }

  void _bindDownloadsToAuth(
    DownloadRepository downloads,
    AuthRepository authRepository,
  ) {
    if (identical(_downloadAuthRepository, authRepository) &&
        identical(_authBoundDownloadRepository, downloads)) {
      return;
    }
    _downloadAuthRepository?.removeListener(_refreshDownloadMembership);
    _downloadAuthRepository = authRepository;
    _authBoundDownloadRepository = downloads;
    authRepository.addListener(_refreshDownloadMembership);
    scheduleMicrotask(_refreshDownloadMembership);
  }

  void _refreshDownloadMembership() {
    final authRepository = _downloadAuthRepository;
    final downloads = _authBoundDownloadRepository;
    if (authRepository == null || downloads == null) return;
    unawaited(downloads.refreshMembership(authRepository.value));
  }

  ReaderRepository _readerRepositoryWithDownloads(
    ReaderRepository network,
    DownloadRepository downloads,
  ) {
    if (_downloadAwareReaderRepository != null &&
        identical(_downloadAwareNetworkRepository, network) &&
        identical(_downloadAwareDownloads, downloads)) {
      return _downloadAwareReaderRepository!;
    }
    _downloadAwareNetworkRepository = network;
    _downloadAwareDownloads = downloads;
    return _downloadAwareReaderRepository = DownloadAwareReaderRepository(
      network: network,
      downloads: downloads,
    );
  }

  void _restoreAuthSessionOnStartup(AuthRepository authRepository) {
    if (identical(_startupRestoredAuthRepository, authRepository)) {
      return;
    }
    _startupRestoredAuthRepository = authRepository;
    if (authRepository.value.status == AuthSessionStatus.idle) {
      scheduleMicrotask(() {
        if (!mounted ||
            !identical(_startupRestoredAuthRepository, authRepository) ||
            authRepository.value.status != AuthSessionStatus.idle) {
          return;
        }
        unawaited(authRepository.restoreSession());
      });
    }
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

  PrivateNovelEngagementRepository _defaultNovelEngagementRepositoryFor() {
    return _defaultNovelEngagementRepository ??=
        PrivateNovelEngagementRepository(client: _privateApiClientFor());
  }

  PrivateVipRepository _defaultVipRepositoryFor() {
    return _defaultVipRepository ??= PrivateVipRepository(
      client: _privateApiClientFor(),
    );
  }

  PublicCommentsRepository _defaultCommentsRepositoryFor() {
    return _defaultCommentsRepository ??= PublicCommentsRepository(
      client: _privateApiClientFor(),
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

  SyncedReadingActivityRepository _defaultReadingActivityRepositoryFor(
    AuthRepository authRepository,
  ) {
    return _defaultReadingActivityRepository ??=
        SyncedReadingActivityRepository(
          store: SharedPreferencesReadingActivityStore(),
          remoteService: ReadingActivityRemoteService(
            client: _privateApiClientFor(),
          ),
          authRepository: authRepository,
        );
  }

  PublicCacheClient _cacheClientFor() {
    return _publicCacheClient ??= PublicCacheClient(
      config: widget.config,
      cacheStore: _defaultPublicCacheStore,
    );
  }

  BootstrapRepository _bootstrapRepositoryFor() {
    return _defaultBootstrapRepository ??= BootstrapRepository(
      _cacheClientFor(),
    );
  }

  HomeRepository _defaultHomeRepositoryFor() {
    return _defaultHomeRepository ??= PublicHomeRepository(
      bootstrapRepository: _bootstrapRepositoryFor(),
      cacheClient: _cacheClientFor(),
    );
  }

  CatalogRepository _defaultCatalogRepositoryFor() {
    return _defaultCatalogRepository ??= PublicCatalogRepository(
      bootstrapRepository: _bootstrapRepositoryFor(),
      cacheClient: _cacheClientFor(),
    );
  }

  NovelRepository _defaultNovelRepositoryFor() {
    return _defaultNovelRepository ??= PublicNovelRepository(
      cacheClient: _cacheClientFor(),
    );
  }

  ReaderRepository _defaultReaderRepositoryFor() {
    return _defaultReaderRepository ??= VipAwareReaderRepository(
      publicReader: PublicReaderRepository(cacheClient: _cacheClientFor()),
      vipRepository: _defaultVipRepositoryFor(),
    );
  }

  RankingsRepository _defaultRankingsRepositoryFor() {
    return _defaultRankingsRepository ??= PublicRankingsRepository(
      bootstrapRepository: _bootstrapRepositoryFor(),
      cacheClient: _cacheClientFor(),
    );
  }

  SearchRepository _defaultSearchRepositoryFor() {
    return _defaultSearchRepository ??= PublicSearchRepository(
      bootstrapRepository: _bootstrapRepositoryFor(),
      cacheClient: _cacheClientFor(),
    );
  }

  PrivateApiClient _privateApiClientFor() {
    return _privateApiClient ??= PrivateApiClient(config: widget.config);
  }

  void _scheduleAdInitialization({
    required HomeAdRepository homeAdRepository,
    required FullScreenAdRepository fullScreenAdRepository,
  }) {
    if (identical(_scheduledHomeAdRepository, homeAdRepository) &&
        identical(_scheduledFullScreenAdRepository, fullScreenAdRepository)) {
      return;
    }

    _adInitializationTimer?.cancel();
    _adInitializationTimer = null;
    _scheduledHomeAdRepository = homeAdRepository;
    _scheduledFullScreenAdRepository = fullScreenAdRepository;
    final generation = ++_adInitializationGeneration;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || generation != _adInitializationGeneration) {
        return;
      }
      late final Timer timer;
      timer = Timer(_postStartupAdInitializationDelay, () {
        if (identical(_adInitializationTimer, timer)) {
          _adInitializationTimer = null;
        }
        if (!mounted || generation != _adInitializationGeneration) {
          return;
        }
        unawaited(
          Future.wait([
            homeAdRepository.initialize(),
            fullScreenAdRepository.initialize(),
          ]),
        );
      });
      _adInitializationTimer = timer;
    });
  }

  ThemeData _themeFor(AppThemeChoice choice) {
    return switch (choice) {
      AppThemeChoice.starlightPaper => AppTheme.light(),
      AppThemeChoice.neutralDark => AppTheme.neutralDarkTheme(),
      AppThemeChoice.galaxyNoir => AppTheme.dark(),
      AppThemeChoice.cosmicNight => AppTheme.cosmicNightTheme(),
      AppThemeChoice.lightNature => AppTheme.lightNatureTheme(),
      AppThemeChoice.oceanAsh => AppTheme.oceanAshTheme(),
      AppThemeChoice.moonForest => AppTheme.moonForestTheme(),
      AppThemeChoice.garnetVelvet => AppTheme.garnetVelvetTheme(),
      AppThemeChoice.copperDusk => AppTheme.copperDuskTheme(),
      AppThemeChoice.midnightTide => AppTheme.midnightTideTheme(),
    };
  }

  AppUpdatePolicyRepository _createDefaultAppUpdatePolicyRepository() {
    if (kDebugMode || !Platform.isAndroid || Firebase.apps.isEmpty) {
      return NoopAppUpdatePolicyRepository();
    }
    return StoredAppUpdatePolicyRepository(
      cache: SharedPreferencesAppUpdatePolicyCache(),
      remote: FirebaseAppUpdatePolicyRemoteSource(
        minimumFetchInterval: kProfileMode
            ? Duration.zero
            : const Duration(hours: 1),
      ),
    );
  }

  ReaderInterstitialPolicyRepository
  _createDefaultReaderInterstitialPolicyRepository() {
    if (kDebugMode || !Platform.isAndroid || Firebase.apps.isEmpty) {
      return NoopReaderInterstitialPolicyRepository();
    }
    return StoredReaderInterstitialPolicyRepository(
      cache: SharedPreferencesReaderInterstitialPolicyCache(),
      remote: FirebaseReaderInterstitialPolicyRemoteSource(
        minimumFetchInterval: kProfileMode
            ? Duration.zero
            : const Duration(hours: 1),
      ),
    );
  }

  AppUpdateController _defaultAppUpdateControllerFor() {
    final usePlatformUpdates =
        !kDebugMode && Platform.isAndroid && Firebase.apps.isNotEmpty;
    return _defaultAppUpdateController ??= AppUpdateController(
      policies: _defaultAppUpdatePolicyRepository ??=
          _createDefaultAppUpdatePolicyRepository(),
      play: usePlatformUpdates
          ? PlayStoreAppUpdateGateway()
          : const NoopPlayAppUpdateGateway(),
      snoozes: usePlatformUpdates
          ? SharedPreferencesAppUpdateSnoozeStore()
          : MemoryAppUpdateSnoozeStore(),
      versionLoader: usePlatformUpdates
          ? loadPackageVersionInfo
          : () async => const AppVersionInfo(version: '', buildNumber: ''),
      analytics: widget.appAnalytics ?? _defaultAppAnalytics,
    );
  }

  AppReviewPolicyRepository _createDefaultAppReviewPolicyRepository() {
    if (kDebugMode || !Platform.isAndroid || Firebase.apps.isEmpty) {
      return NoopAppReviewPolicyRepository();
    }
    return StoredAppReviewPolicyRepository(
      cache: SharedPreferencesAppReviewPolicyCache(),
      remote: FirebaseAppReviewPolicyRemoteSource(
        minimumFetchInterval: kProfileMode
            ? Duration.zero
            : const Duration(hours: 1),
      ),
    );
  }

  AppReviewPromptController _defaultAppReviewPromptControllerFor() {
    final useGooglePlay =
        !kDebugMode && Platform.isAndroid && Firebase.apps.isNotEmpty;
    return _defaultAppReviewPromptController ??= AppReviewPromptController(
      policies: _defaultAppReviewPolicyRepository ??=
          _createDefaultAppReviewPolicyRepository(),
      store: useGooglePlay
          ? SharedPreferencesAppReviewPromptStore()
          : MemoryAppReviewPromptStore(),
      play: useGooglePlay
          ? InAppReviewGateway()
          : const NoopPlayAppReviewGateway(),
      analytics: widget.appAnalytics ?? _defaultAppAnalytics,
    );
  }

  AppOnboardingController _defaultAppOnboardingControllerFor() {
    final existing = _defaultAppOnboardingController;
    if (existing != null) return existing;

    final debugCompletedState = AppOnboardingState.completed(
      completedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      method: AppOnboardingCompletionMethod.completed,
    );
    final store = kDebugMode
        ? MemoryAppOnboardingStore(debugCompletedState)
        : SharedPreferencesAppOnboardingStore();
    return _defaultAppOnboardingController = AppOnboardingController(
      store: store,
      analytics: widget.appAnalytics ?? _defaultAppAnalytics,
      initialState: kDebugMode ? debugCompletedState : null,
    );
  }

  void _scheduleSpeechSessionRestoration({
    required ReaderSpeechController? controller,
    required ReaderRepository readerRepository,
    required ReaderTermReplacementRepository termRepository,
    required ReaderAdvancedTerminologyRepository advancedRepository,
  }) {
    if (controller is! RestorableReaderSpeechController) return;
    final restorableController = controller as RestorableReaderSpeechController;
    if (identical(_speechRestorationController, restorableController) &&
        identical(_speechRestorationReaderRepository, readerRepository) &&
        identical(_speechRestorationTermRepository, termRepository) &&
        identical(_speechRestorationAdvancedRepository, advancedRepository)) {
      return;
    }
    _speechRestorationController = restorableController;
    _speechRestorationReaderRepository = readerRepository;
    _speechRestorationTermRepository = termRepository;
    _speechRestorationAdvancedRepository = advancedRepository;
    final generation = ++_speechRestorationGeneration;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || generation != _speechRestorationGeneration) return;
      unawaited(
        _restoreSpeechSession(
          controller: restorableController,
          readerRepository: readerRepository,
          termRepository: termRepository,
          advancedRepository: advancedRepository,
        ),
      );
    });
  }

  Future<void> _restoreSpeechSession({
    required RestorableReaderSpeechController controller,
    required ReaderRepository readerRepository,
    required ReaderTermReplacementRepository termRepository,
    required ReaderAdvancedTerminologyRepository advancedRepository,
  }) async {
    try {
      await controller.restoreSession(
        (checkpoint) => RepositoryReaderSpeechChapterSource(
          readerRepository: readerRepository,
          termRepository: termRepository,
          advancedRepository: advancedRepository,
          checkpoint: checkpoint,
        ),
      );
    } on Exception catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'reader speech restoration',
        ),
      );
    }
  }

  @override
  void dispose() {
    _speechRestorationGeneration += 1;
    _adInitializationGeneration += 1;
    _adInitializationTimer?.cancel();
    _adInitializationTimer = null;
    _defaultAccountReadingHistoryRepository?.dispose();
    _defaultReadingActivityRepository?.dispose();
    _defaultFavoritesRepository?.dispose();
    _defaultHomeRecommendationExclusionRepository?.dispose();
    _defaultAuthRepository?.dispose();
    _defaultFullScreenAdRepository.dispose();
    _defaultRewardedDownloadAdRepository.dispose();
    _downloadAuthRepository?.removeListener(_refreshDownloadMembership);
    _initializedDownloadRepository?.dispose();
    _defaultLocalReadingHistoryRepository.dispose();
    _defaultReaderPreferencesRepository.dispose();
    _defaultReaderTermReplacementRepository.dispose();
    _defaultReaderAdvancedTerminologyRepository.dispose();
    _defaultHomeCustomizationRepository.dispose();
    _defaultLibraryCustomizationRepository.dispose();
    _defaultAppThemeController.dispose();
    _defaultAppUpdateController?.dispose();
    _defaultAppUpdatePolicyRepository?.dispose();
    _appReviewNavigatorObserver?.dispose();
    _defaultAppReviewPromptController?.dispose();
    _defaultAppOnboardingController?.dispose();
    super.dispose();
  }
}
