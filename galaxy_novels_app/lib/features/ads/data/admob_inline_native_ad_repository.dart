import 'package:flutter/widgets.dart';

import '../application/inline_native_ad_repository.dart';
import '../application/ad_analytics.dart';
import '../presentation/admob_inline_native_ad.dart';
import 'admob_ad_units.dart';
import 'admob_initialization_coordinator.dart';

class AdMobInlineNativeAdRepository implements InlineNativeAdRepository {
  AdMobInlineNativeAdRepository({
    AdMobAdConfig? config,
    AdMobInitializationCoordinator? coordinator,
    this.analytics = const AdAnalytics.noop(),
  }) : _config = config ?? AdMobAdUnits.current,
       _coordinator = coordinator ?? AdMobInitializationCoordinator.shared;

  final AdMobAdConfig _config;
  final AdMobInitializationCoordinator _coordinator;
  final AdAnalytics analytics;

  @override
  Future<void> initialize() => _coordinator.initialize();

  String adUnitIdFor(InlineNativeAdPlacement placement) => switch (placement) {
    InlineNativeAdPlacement.home => _config.androidHomeNativeId,
    InlineNativeAdPlacement.novelDetails => _config.androidNovelDetailsNativeId,
    InlineNativeAdPlacement.library => _config.androidLibraryNativeId,
    InlineNativeAdPlacement.rankings => _config.androidRankingsNativeId,
    InlineNativeAdPlacement.readerJourney =>
      _config.androidReaderJourneyNativeId,
  };

  @override
  Widget? buildNativeAd(
    BuildContext context, {
    required InlineNativeAdPlacement placement,
  }) {
    if (!_coordinator.isSupported) return null;
    return AdMobInlineNativeAd(
      adUnitId: adUnitIdFor(placement),
      placement: placement,
      readiness: _coordinator.initialize(),
      analytics: analytics,
    );
  }
}
