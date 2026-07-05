import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../application/rewarded_ad_repository.dart';
import 'admob_ad_units.dart';

class AdMobRewardedAdRepository implements RewardedAdRepository {
  AdMobRewardedAdRepository({String? rewardedAdUnitId})
    : rewardedAdUnitId =
          rewardedAdUnitId ?? AdMobAdUnits.current.androidRewardedId;

  final String rewardedAdUnitId;
  Future<void>? _initialization;

  @override
  Future<void> initialize() {
    if (!_isSupportedPlatform) {
      return Future<void>.value();
    }
    return _initialization ??= MobileAds.instance.initialize();
  }

  @override
  Future<RewardedAdOutcome> showRewardedAd() async {
    if (!_isSupportedPlatform) {
      return RewardedAdOutcome.unavailable;
    }

    await initialize();
    final ad = await _loadRewardedAd();
    if (ad == null) {
      return RewardedAdOutcome.unavailable;
    }

    final completer = Completer<RewardedAdOutcome>();
    var earnedReward = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        if (!completer.isCompleted) {
          completer.complete(
            earnedReward
                ? RewardedAdOutcome.earnedReward
                : RewardedAdOutcome.dismissed,
          );
        }
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        if (!completer.isCompleted) {
          completer.complete(RewardedAdOutcome.failed);
        }
      },
    );

    await ad.show(
      onUserEarnedReward: (ad, reward) {
        earnedReward = true;
      },
    );

    return completer.future.timeout(
      const Duration(minutes: 2),
      onTimeout: () {
        ad.dispose();
        return earnedReward
            ? RewardedAdOutcome.earnedReward
            : RewardedAdOutcome.failed;
      },
    );
  }

  Future<RewardedAd?> _loadRewardedAd() {
    final completer = Completer<RewardedAd?>();
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          if (!completer.isCompleted) {
            completer.complete(ad);
          }
        },
        onAdFailedToLoad: (error) {
          if (!completer.isCompleted) {
            completer.complete(null);
          }
        },
      ),
    );
    return completer.future.timeout(
      const Duration(seconds: 12),
      onTimeout: () => null,
    );
  }
}

bool get _isSupportedPlatform {
  return !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
}
