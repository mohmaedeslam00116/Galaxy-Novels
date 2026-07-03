import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../application/reader_ad_repository.dart';
import 'admob_ad_units.dart';
import '../presentation/admob_adaptive_banner.dart';

class AdMobReaderAdRepository implements ReaderAdRepository {
  AdMobReaderAdRepository({
    this.readerBannerAdUnitId = AdMobAdUnits.androidReaderBannerTest,
  });

  final String readerBannerAdUnitId;
  Future<void>? _initialization;

  @override
  Future<void> initialize() {
    if (!_isSupportedPlatform) {
      return Future<void>.value();
    }
    return _initialization ??= MobileAds.instance.initialize();
  }

  @override
  Widget? buildReaderBanner(BuildContext context) {
    if (!_isSupportedPlatform) {
      return null;
    }
    return AdMobAdaptiveBanner(adUnitId: readerBannerAdUnitId);
  }
}

bool get _isSupportedPlatform {
  return !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
}
