import 'package:flutter/widgets.dart';

import 'ad_analytics.dart';

enum InlineNativeAdPlacement {
  home,
  novelDetails,
  library,
  rankings,
  readerJourney,
}

extension InlineNativeAdPlacementAnalytics on InlineNativeAdPlacement {
  AdAnalyticsPlacement get analyticsPlacement => switch (this) {
    InlineNativeAdPlacement.home => AdAnalyticsPlacement.home,
    InlineNativeAdPlacement.novelDetails => AdAnalyticsPlacement.novelDetails,
    InlineNativeAdPlacement.library => AdAnalyticsPlacement.library,
    InlineNativeAdPlacement.rankings => AdAnalyticsPlacement.rankings,
    InlineNativeAdPlacement.readerJourney => AdAnalyticsPlacement.readerJourney,
  };
}

abstract class InlineNativeAdRepository {
  Future<void> initialize();

  Widget? buildNativeAd(
    BuildContext context, {
    required InlineNativeAdPlacement placement,
  });
}

class NoopInlineNativeAdRepository implements InlineNativeAdRepository {
  const NoopInlineNativeAdRepository();

  @override
  Future<void> initialize() async {}

  @override
  Widget? buildNativeAd(
    BuildContext context, {
    required InlineNativeAdPlacement placement,
  }) => null;
}
