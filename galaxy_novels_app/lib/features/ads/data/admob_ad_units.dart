import 'package:flutter/foundation.dart';

class AdMobAdUnits {
  const AdMobAdUnits._();

  static const androidTestAppId = 'ca-app-pub-3940256099942544~3347511713';
  static const androidReaderBannerTest =
      'ca-app-pub-3940256099942544/6300978111';
  static const androidRewardedTest = 'ca-app-pub-3940256099942544/5224354917';

  static const current = AdMobAdConfig(
    isRelease: kReleaseMode,
    androidReaderBannerId: String.fromEnvironment(
      'ADMOB_ANDROID_READER_BANNER_ID',
    ),
    androidRewardedId: String.fromEnvironment('ADMOB_ANDROID_REWARDED_ID'),
  );
}

class AdMobAdConfig {
  const AdMobAdConfig({
    required this.isRelease,
    required String androidReaderBannerId,
    required String androidRewardedId,
  }) : _androidReaderBannerId = androidReaderBannerId,
       _androidRewardedId = androidRewardedId;

  final bool isRelease;
  final String _androidReaderBannerId;
  final String _androidRewardedId;

  String get androidReaderBannerId => _adUnitId(
    value: _androidReaderBannerId,
    testValue: AdMobAdUnits.androidReaderBannerTest,
    defineName: 'ADMOB_ANDROID_READER_BANNER_ID',
  );

  String get androidRewardedId => _adUnitId(
    value: _androidRewardedId,
    testValue: AdMobAdUnits.androidRewardedTest,
    defineName: 'ADMOB_ANDROID_REWARDED_ID',
  );

  String _adUnitId({
    required String value,
    required String testValue,
    required String defineName,
  }) {
    final trimmedValue = value.trim();
    if (trimmedValue.isNotEmpty) {
      return trimmedValue;
    }
    if (!isRelease) {
      return testValue;
    }
    throw AdMobConfigurationException(
      'Missing $defineName. Production builds must pass real AdMob unit ids '
      'with --dart-define.',
    );
  }
}

class AdMobConfigurationException implements Exception {
  const AdMobConfigurationException(this.message);

  final String message;

  @override
  String toString() => 'AdMobConfigurationException: $message';
}
