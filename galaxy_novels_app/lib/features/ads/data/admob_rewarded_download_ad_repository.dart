import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../application/rewarded_download_ad_repository.dart';
import '../application/reward_grant_verifier.dart';
import 'admob_ad_units.dart';
import 'admob_full_screen_ad_guard.dart';
import 'admob_initialization_coordinator.dart';

class AdMobRewardedDownloadAdRepository extends ChangeNotifier
    implements RewardedDownloadAdRepository {
  AdMobRewardedDownloadAdRepository({
    String? adUnitId,
    AdMobInitializationCoordinator? coordinator,
    AdMobFullScreenAdGuard? guard,
  }) : _adUnitId = adUnitId ?? AdMobAdUnits.current.androidDownloadRewardedId,
       _coordinator = coordinator ?? AdMobInitializationCoordinator.shared,
       _guard = guard ?? AdMobFullScreenAdGuard.shared;

  final String _adUnitId;
  final AdMobInitializationCoordinator _coordinator;
  final AdMobFullScreenAdGuard _guard;
  bool _showing = false;
  int _eventSequence = 0;
  RewardedAd? _cachedAd;
  DateTime? _loadedAt;
  Future<void>? _preloadOperation;
  RewardedDownloadAdAvailability _availability =
      RewardedDownloadAdAvailability.idle;
  bool _disposed = false;

  static const _maximumCacheAge = Duration(minutes: 55);

  @override
  RewardedDownloadAdAvailability get availability => _availability;

  @override
  RewardedDownloadAdAvailability get value => _availability;

  @override
  Future<void> preload() {
    if (_disposed || _showing) return Future.value();
    if (_hasFreshAd) {
      _setAvailability(RewardedDownloadAdAvailability.ready);
      return Future.value();
    }
    final inFlight = _preloadOperation;
    if (inFlight != null) return inFlight;
    final operation = _preloadInternal();
    _preloadOperation = operation;
    return operation.whenComplete(() {
      if (identical(_preloadOperation, operation)) {
        _preloadOperation = null;
      }
    });
  }

  @override
  Future<RewardedDownloadAdResult> show() async {
    if (_disposed || _showing) {
      return const RewardedDownloadAdResult(RewardedDownloadAdStatus.busy);
    }
    try {
      await preload();
      final ad = _takeFreshAd();
      if (ad == null) {
        _setAvailability(RewardedDownloadAdAvailability.unavailable);
        return const RewardedDownloadAdResult(
          RewardedDownloadAdStatus.unavailable,
        );
      }
      if (!_guard.tryAcquire()) {
        _cachedAd = ad;
        _loadedAt = DateTime.now();
        _setAvailability(RewardedDownloadAdAvailability.ready);
        return const RewardedDownloadAdResult(RewardedDownloadAdStatus.busy);
      }
      _showing = true;
      _setAvailability(RewardedDownloadAdAvailability.showing);
      try {
        return await _present(ad);
      } finally {
        _guard.release();
      }
    } on PlatformException {
      return const RewardedDownloadAdResult(
        RewardedDownloadAdStatus.unavailable,
      );
    } finally {
      _showing = false;
      if (!_disposed &&
          _availability == RewardedDownloadAdAvailability.showing) {
        _setAvailability(RewardedDownloadAdAvailability.idle);
      }
      if (!_disposed && !_hasFreshAd) {
        unawaited(preload());
      }
    }
  }

  Future<void> _preloadInternal() async {
    _disposeCachedAd();
    _setAvailability(RewardedDownloadAdAvailability.loading);
    try {
      if (!await _coordinator.initialize()) {
        _setAvailability(RewardedDownloadAdAvailability.unavailable);
        return;
      }
      final ad = await _load();
      if (_disposed) {
        ad?.dispose();
        return;
      }
      if (ad == null) {
        _setAvailability(RewardedDownloadAdAvailability.unavailable);
        return;
      }
      ad.setServerSideOptions(
        ServerSideVerificationOptions(customData: downloadChaptersRewardType),
      );
      _cachedAd = ad;
      _loadedAt = DateTime.now();
      _setAvailability(RewardedDownloadAdAvailability.ready);
    } on PlatformException {
      _setAvailability(RewardedDownloadAdAvailability.unavailable);
    }
  }

  bool get _hasFreshAd {
    final loadedAt = _loadedAt;
    if (_cachedAd == null || loadedAt == null) return false;
    if (DateTime.now().difference(loadedAt) <= _maximumCacheAge) return true;
    _disposeCachedAd();
    return false;
  }

  RewardedAd? _takeFreshAd() {
    if (!_hasFreshAd) return null;
    final ad = _cachedAd;
    _cachedAd = null;
    _loadedAt = null;
    return ad;
  }

  void _disposeCachedAd() {
    _cachedAd?.dispose();
    _cachedAd = null;
    _loadedAt = null;
  }

  void _setAvailability(RewardedDownloadAdAvailability availability) {
    if (_availability == availability) return;
    _availability = availability;
    if (!_disposed) notifyListeners();
  }

  Future<RewardedAd?> _load() {
    final completer = Completer<RewardedAd?>();
    RewardedAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: completer.complete,
        onAdFailedToLoad: (_) => completer.complete(null),
      ),
    );
    return completer.future;
  }

  Future<RewardedDownloadAdResult> _present(RewardedAd ad) {
    final completer = Completer<RewardedDownloadAdResult>();
    var earned = false;
    ad.fullScreenContentCallback = FullScreenContentCallback<RewardedAd>(
      onAdShowedFullScreenContent: (_) => _guard.markShown(),
      onAdDismissedFullScreenContent: (shownAd) {
        shownAd.dispose();
        if (!completer.isCompleted) {
          completer.complete(
            RewardedDownloadAdResult(
              earned
                  ? RewardedDownloadAdStatus.earned
                  : RewardedDownloadAdStatus.dismissed,
              rewardEventId: earned ? _newRewardEventId() : null,
            ),
          );
        }
      },
      onAdFailedToShowFullScreenContent: (shownAd, _) {
        shownAd.dispose();
        if (!completer.isCompleted) {
          completer.complete(
            const RewardedDownloadAdResult(
              RewardedDownloadAdStatus.unavailable,
            ),
          );
        }
      },
    );
    ad.show(onUserEarnedReward: (_, reward) => earned = true);
    return completer.future;
  }

  String _newRewardEventId() {
    _eventSequence++;
    return 'admob-${DateTime.now().microsecondsSinceEpoch}-$_eventSequence';
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _disposeCachedAd();
    _availability = RewardedDownloadAdAvailability.unavailable;
    super.dispose();
  }
}
