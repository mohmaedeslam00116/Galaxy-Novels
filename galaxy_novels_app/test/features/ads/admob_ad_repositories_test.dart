import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/features/ads/data/admob_initialization_coordinator.dart';
import 'package:galaxy_novels_app/features/ads/data/admob_home_ad_repository.dart';
import 'package:galaxy_novels_app/features/ads/data/admob_rewarded_download_ad_repository.dart';
import 'package:galaxy_novels_app/features/ads/application/rewarded_download_ad_repository.dart';
import 'package:galaxy_novels_app/core/analytics/app_analytics.dart';
import 'package:galaxy_novels_app/features/ads/application/ad_analytics.dart';
import 'package:galaxy_novels_app/features/ads/application/full_screen_ad_cadence.dart';
import 'package:galaxy_novels_app/features/ads/data/admob_full_screen_ad_repository.dart';
import 'package:galaxy_novels_app/features/ads/application/reader_interstitial_policy_repository.dart';

void main() {
  testWidgets(
    'home ads return no native placement on an unsupported platform',
    (tester) async {
      final coordinator = AdMobInitializationCoordinator(
        isAndroid: () => false,
      );
      final repository = AdMobHomeAdRepository(
        coordinator: coordinator,
        homeNativeAdUnitId: 'home-test-unit',
      );
      Widget? homeAd;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              homeAd = repository.buildHomeNativeAd(context);
              return homeAd ?? const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(homeAd, isNull);
    },
  );

  test(
    'rewarded preload becomes unavailable on unsupported platforms',
    () async {
      final repository = AdMobRewardedDownloadAdRepository(
        coordinator: AdMobInitializationCoordinator(isAndroid: () => false),
      );

      expect(repository.availability, RewardedDownloadAdAvailability.idle);
      await repository.preload();
      expect(
        repository.availability,
        RewardedDownloadAdAvailability.unavailable,
      );
      expect(
        (await repository.show()).status,
        RewardedDownloadAdStatus.unavailable,
      );
      repository.dispose();
    },
  );

  test('browse interstitial reports when cadence becomes due', () async {
    final appAnalytics = _RecordingAppAnalytics();
    final repository = AdMobFullScreenAdRepository(
      coordinator: AdMobInitializationCoordinator(isAndroid: () => false),
      cadence: FullScreenAdCadence(store: _MemoryCadenceStore()),
      analytics: AdAnalytics(appAnalytics),
    );

    for (var open = 0; open < 5; open++) {
      await repository.showBrowseInterstitial(canShow: true);
    }

    final dueEvent = appAnalytics.events.singleWhere(
      (event) => event.name == 'galaxy_ad_due',
    );
    expect(dueEvent.parameters, {
      'format': 'interstitial',
      'placement': 'browse',
    });
    repository.dispose();
  });

  test('reader interstitial reports a distinct due placement', () async {
    final appAnalytics = _RecordingAppAnalytics();
    final repository = AdMobFullScreenAdRepository(
      coordinator: AdMobInitializationCoordinator(isAndroid: () => false),
      cadence: FullScreenAdCadence(
        store: _MemoryCadenceStore(),
        readerTargetPicker: (_, _) => 5,
      ),
      readerPolicyRepository: NoopReaderInterstitialPolicyRepository(),
      analytics: AdAnalytics(appAnalytics),
    );

    for (var transition = 0; transition < 5; transition++) {
      await repository.showReaderInterstitialIfDue(canShow: true);
    }

    final dueEvent = appAnalytics.events.singleWhere(
      (event) =>
          event.name == 'galaxy_ad_due' &&
          event.parameters?['placement'] == 'reader',
    );
    expect(dueEvent.parameters, {
      'format': 'interstitial',
      'placement': 'reader',
      'interval_chapters': 5,
      'transitions_since_last_ad': 5,
    });
    final deferredEvent = appAnalytics.events.singleWhere(
      (event) => event.name == 'galaxy_reader_ad_deferred',
    );
    expect(deferredEvent.parameters?['reason'], 'not_ready');
    repository.dispose();
  });
}

class _RecordingAppAnalytics implements AppAnalytics {
  final List<({String name, Map<String, Object>? parameters})> events = [];

  @override
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    events.add((name: name, parameters: parameters));
  }

  @override
  Future<void> logScreenView(String screenName) async {}
}

class _MemoryCadenceStore implements FullScreenAdCadenceStore {
  FullScreenAdCadenceState state = const FullScreenAdCadenceState();

  @override
  Future<FullScreenAdCadenceState> read() async => state;

  @override
  Future<void> write(FullScreenAdCadenceState state) async {
    this.state = state;
  }
}
