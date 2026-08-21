import 'package:flutter/widgets.dart';

import '../core/config/app_config.dart';
import '../core/network/app_cache_maintenance.dart';
import '../data/repositories/catalog_repository.dart';
import '../data/repositories/home_repository.dart';
import '../data/repositories/novel_repository.dart';
import '../data/repositories/reader_repository.dart';
import '../data/repositories/rankings_repository.dart';
import '../data/repositories/reading_history_repository.dart';
import '../data/repositories/search_repository.dart';
import '../features/account/application/auth_repository.dart';
import '../features/ads/application/home_ad_repository.dart';
import '../features/ads/application/ad_privacy_options_repository.dart';
import '../features/ads/application/full_screen_ad_repository.dart';
import '../features/ads/application/inline_native_ad_repository.dart';
import '../features/ads/application/rewarded_download_ad_repository.dart';
import '../features/comments/application/comments_repository.dart';
import '../features/favorites/application/favorites_repository.dart';
import '../features/home/application/home_recommendation_exclusion_repository.dart';
import '../features/app_update/application/app_update_controller.dart';
import '../features/app_review/application/app_review_prompt_controller.dart';
import '../features/onboarding/application/app_onboarding_controller.dart';
import '../features/downloads/application/download_repository.dart';
import '../features/downloads/application/download_analytics.dart';
import '../features/novel_engagement/application/novel_engagement_repository.dart';
import '../features/reading_activity/application/reading_activity_recorder.dart';
import '../features/reader/application/reader_preferences_repository.dart';
import '../features/reader/application/reader_advanced_terminology_repository.dart';
import '../features/reader/application/reader_speech_controller.dart';
import '../features/reader/application/reader_term_replacement_repository.dart';
import '../features/vip/application/vip_repository.dart';

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
    required this.readerPreferencesRepository,
    this.readerSpeechController,
    this.readerTermReplacementRepository,
    this.readerAdvancedTerminologyRepository,
    this.homeRecommendationExclusionRepository,
    required this.authRepository,
    required this.commentsRepository,
    required this.favoritesRepository,
    required this.novelEngagementRepository,
    required this.vipRepository,
    this.homeAdRepository = const NoopHomeAdRepository(),
    this.adPrivacyOptionsRepository = const NoopAdPrivacyOptionsRepository(),
    this.fullScreenAdRepository = const NoopFullScreenAdRepository(),
    this.inlineNativeAdRepository = const NoopInlineNativeAdRepository(),
    this.downloadRepository = const NoopDownloadRepository(),
    this.downloadAnalytics = const NoopDownloadAnalytics(),
    this.rewardedDownloadAdRepository =
        const NoopRewardedDownloadAdRepository(),
    this.readingActivityRecorder = const NoopReadingActivityRecorder(),
    this.cacheMaintenance = const NoopAppCacheMaintenance(),
    this.appUpdateController,
    this.appReviewPromptController,
    this.appOnboardingController,
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
  final ReaderPreferencesRepository readerPreferencesRepository;
  final ReaderSpeechController? readerSpeechController;
  final ReaderTermReplacementRepository? readerTermReplacementRepository;
  final ReaderAdvancedTerminologyRepository?
  readerAdvancedTerminologyRepository;
  final HomeRecommendationExclusionRepository?
  homeRecommendationExclusionRepository;
  final AuthRepository authRepository;
  final CommentsRepository commentsRepository;
  final FavoritesRepository favoritesRepository;
  final NovelEngagementRepository novelEngagementRepository;
  final VipRepository vipRepository;
  final HomeAdRepository homeAdRepository;
  final AdPrivacyOptionsRepository adPrivacyOptionsRepository;
  final FullScreenAdRepository fullScreenAdRepository;
  final InlineNativeAdRepository inlineNativeAdRepository;
  final DownloadRepository downloadRepository;
  final DownloadAnalytics downloadAnalytics;
  final RewardedDownloadAdRepository rewardedDownloadAdRepository;
  final ReadingActivityRecorder readingActivityRecorder;
  final AppCacheMaintenance cacheMaintenance;
  final AppUpdateController? appUpdateController;
  final AppReviewPromptController? appReviewPromptController;
  final AppOnboardingController? appOnboardingController;

  static AppDependencies of(BuildContext context) {
    final dependencies = maybeOf(context);

    assert(dependencies != null, 'AppDependencies was not found in context.');
    return dependencies!;
  }

  static AppDependencies? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppDependencies>();
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
        readerPreferencesRepository != oldWidget.readerPreferencesRepository ||
        readerSpeechController != oldWidget.readerSpeechController ||
        readerTermReplacementRepository !=
            oldWidget.readerTermReplacementRepository ||
        readerAdvancedTerminologyRepository !=
            oldWidget.readerAdvancedTerminologyRepository ||
        homeRecommendationExclusionRepository !=
            oldWidget.homeRecommendationExclusionRepository ||
        authRepository != oldWidget.authRepository ||
        commentsRepository != oldWidget.commentsRepository ||
        favoritesRepository != oldWidget.favoritesRepository ||
        novelEngagementRepository != oldWidget.novelEngagementRepository ||
        vipRepository != oldWidget.vipRepository ||
        homeAdRepository != oldWidget.homeAdRepository ||
        adPrivacyOptionsRepository != oldWidget.adPrivacyOptionsRepository ||
        fullScreenAdRepository != oldWidget.fullScreenAdRepository ||
        inlineNativeAdRepository != oldWidget.inlineNativeAdRepository ||
        downloadRepository != oldWidget.downloadRepository ||
        downloadAnalytics != oldWidget.downloadAnalytics ||
        rewardedDownloadAdRepository !=
            oldWidget.rewardedDownloadAdRepository ||
        readingActivityRecorder != oldWidget.readingActivityRecorder ||
        cacheMaintenance != oldWidget.cacheMaintenance ||
        appUpdateController != oldWidget.appUpdateController ||
        appReviewPromptController != oldWidget.appReviewPromptController ||
        appOnboardingController != oldWidget.appOnboardingController;
  }
}
