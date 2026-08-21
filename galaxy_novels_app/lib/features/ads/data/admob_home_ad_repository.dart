import 'package:flutter/widgets.dart';

import '../application/home_ad_repository.dart';
import '../application/ad_analytics.dart';
import '../application/inline_native_ad_repository.dart';
import '../presentation/admob_inline_native_ad.dart';
import 'admob_ad_units.dart';
import 'admob_initialization_coordinator.dart';

class AdMobHomeAdRepository implements HomeAdRepository {
  AdMobHomeAdRepository({
    String? homeNativeAdUnitId,
    AdMobInitializationCoordinator? coordinator,
    this.analytics = const AdAnalytics.noop(),
  }) : homeNativeAdUnitId =
           homeNativeAdUnitId ?? AdMobAdUnits.current.androidHomeNativeId,
       _coordinator = coordinator ?? AdMobInitializationCoordinator.shared;

  final String homeNativeAdUnitId;
  final AdMobInitializationCoordinator _coordinator;
  final AdAnalytics analytics;

  @override
  Future<void> initialize() async {
    await _coordinator.initialize();
  }

  @override
  Widget? buildHomeNativeAd(BuildContext context) {
    if (!_coordinator.isSupported) {
      return null;
    }
    return AdMobInlineNativeAd(
      adUnitId: homeNativeAdUnitId,
      placement: InlineNativeAdPlacement.home,
      readiness: _coordinator.initialize(),
      analytics: analytics,
    );
  }
}
