import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/features/ads/application/inline_native_ad_repository.dart';
import 'package:galaxy_novels_app/features/ads/application/ad_analytics.dart';
import 'package:galaxy_novels_app/features/ads/data/admob_ad_units.dart';
import 'package:galaxy_novels_app/features/ads/data/admob_initialization_coordinator.dart';
import 'package:galaxy_novels_app/features/ads/data/admob_inline_native_ad_repository.dart';
import 'package:galaxy_novels_app/features/ads/presentation/admob_inline_native_ad.dart';
import 'package:galaxy_novels_app/core/analytics/app_analytics.dart';

void main() {
  test('each inline placement resolves its own production unit', () {
    const config = AdMobAdConfig(isRelease: true);
    final repository = AdMobInlineNativeAdRepository(
      config: config,
      coordinator: AdMobInitializationCoordinator(isAndroid: () => false),
    );

    expect(
      repository.adUnitIdFor(InlineNativeAdPlacement.home),
      config.androidHomeNativeId,
    );
    expect(
      repository.adUnitIdFor(InlineNativeAdPlacement.novelDetails),
      config.androidNovelDetailsNativeId,
    );
    expect(
      repository.adUnitIdFor(InlineNativeAdPlacement.library),
      config.androidLibraryNativeId,
    );
    expect(
      repository.adUnitIdFor(InlineNativeAdPlacement.rankings),
      config.androidRankingsNativeId,
    );
    expect(
      repository.adUnitIdFor(InlineNativeAdPlacement.readerJourney),
      config.androidReaderJourneyNativeId,
    );
  });

  test('each inline placement resolves a stable analytics placement', () {
    expect(
      InlineNativeAdPlacement.home.analyticsPlacement,
      AdAnalyticsPlacement.home,
    );
    expect(
      InlineNativeAdPlacement.novelDetails.analyticsPlacement,
      AdAnalyticsPlacement.novelDetails,
    );
    expect(
      InlineNativeAdPlacement.library.analyticsPlacement,
      AdAnalyticsPlacement.library,
    );
    expect(
      InlineNativeAdPlacement.rankings.analyticsPlacement,
      AdAnalyticsPlacement.rankings,
    );
    expect(
      InlineNativeAdPlacement.readerJourney.analyticsPlacement,
      AdAnalyticsPlacement.readerJourney,
    );
  });

  testWidgets('inline ads return no placement on unsupported platforms', (
    tester,
  ) async {
    final repository = AdMobInlineNativeAdRepository(
      coordinator: AdMobInitializationCoordinator(isAndroid: () => false),
    );
    Widget? placement;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            placement = repository.buildNativeAd(
              context,
              placement: InlineNativeAdPlacement.library,
            );
            return placement ?? const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(placement, isNull);
  });

  testWidgets('inline repository injects its measurement session', (
    tester,
  ) async {
    final appAnalytics = _RecordingAppAnalytics();
    final adAnalytics = AdAnalytics(appAnalytics);
    final coordinator = AdMobInitializationCoordinator(
      isAndroid: () => true,
      updateConsentInfo: () async {},
      showConsentFormIfRequired: () async {},
      canRequestAds: () async => true,
      initializeMobileAds: () async {},
    );
    final repository = AdMobInlineNativeAdRepository(
      coordinator: coordinator,
      analytics: adAnalytics,
    );
    Widget? placement;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            placement = repository.buildNativeAd(
              context,
              placement: InlineNativeAdPlacement.library,
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(placement, isA<AdMobInlineNativeAd>());
    final native = placement! as AdMobInlineNativeAd;
    expect(native.analytics, same(adAnalytics));
  });
}

class _RecordingAppAnalytics implements AppAnalytics {
  @override
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {}

  @override
  Future<void> logScreenView(String screenName) async {}
}
