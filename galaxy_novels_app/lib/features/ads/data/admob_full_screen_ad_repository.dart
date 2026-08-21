import 'dart:async';

import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../application/full_screen_ad_cadence.dart';
import '../application/full_screen_ad_repository.dart';
import '../application/ad_analytics.dart';
import '../application/reader_interstitial_policy_repository.dart';
import '../domain/reader_interstitial_policy.dart';
import 'admob_ad_units.dart';
import 'admob_full_screen_ad_guard.dart';
import 'admob_initialization_coordinator.dart';
import 'shared_preferences_full_screen_ad_cadence_store.dart';

class AdMobFullScreenAdRepository implements FullScreenAdRepository {
  AdMobFullScreenAdRepository({
    String? appOpenAdUnitId,
    String? browseInterstitialAdUnitId,
    String? readerInterstitialAdUnitId,
    AdMobInitializationCoordinator? coordinator,
    FullScreenAdCadence? cadence,
    AdMobFullScreenAdGuard? guard,
    ReaderInterstitialPolicyRepository? readerPolicyRepository,
    this.analytics = const AdAnalytics.noop(),
  }) : _appOpenAdUnitId =
           appOpenAdUnitId ?? AdMobAdUnits.current.androidAppOpenId,
       _browseInterstitialAdUnitId =
           browseInterstitialAdUnitId ??
           AdMobAdUnits.current.androidBrowseInterstitialId,
       _readerInterstitialAdUnitId =
           readerInterstitialAdUnitId ??
           AdMobAdUnits.current.androidReaderInterstitialId,
       _coordinator = coordinator ?? AdMobInitializationCoordinator.shared,
       _cadence =
           cadence ??
           FullScreenAdCadence(
             store: SharedPreferencesFullScreenAdCadenceStore(),
           ),
       _guard = guard ?? AdMobFullScreenAdGuard.shared,
       _readerPolicyRepository =
           readerPolicyRepository ?? NoopReaderInterstitialPolicyRepository();

  static const _appOpenLoadTimeout = Duration(seconds: 4);

  final String _appOpenAdUnitId;
  final String _browseInterstitialAdUnitId;
  final String _readerInterstitialAdUnitId;
  final AdMobInitializationCoordinator _coordinator;
  final FullScreenAdCadence _cadence;
  final AdMobFullScreenAdGuard _guard;
  final ReaderInterstitialPolicyRepository _readerPolicyRepository;
  final AdAnalytics analytics;
  bool _disposed = false;
  InterstitialAd? _browseInterstitialAd;
  Future<InterstitialAd?>? _browseInterstitialLoad;
  AdAnalyticsSession? _browseInterstitialMeasurement;
  InterstitialAd? _readerInterstitialAd;
  Future<InterstitialAd?>? _readerInterstitialLoad;
  AdAnalyticsSession? _readerInterstitialMeasurement;
  bool _readerPolicyStarted = false;

  @override
  bool get isSupported => _coordinator.isSupported;

  @override
  Future<void> initialize() async {
    await _prepareReaderPolicy();
    await _coordinator.initialize();
  }

  @override
  Future<bool> showAppOpenOnColdStart({required bool canShow}) async {
    final due = await _cadence.registerColdLaunchAndIsAppOpenDue();
    if (!canShow ||
        !due ||
        !_guard.hasElapsed(FullScreenAdCadence.fullScreenSpacing)) {
      return false;
    }
    return _loadAndShowAppOpen();
  }

  @override
  Future<bool> showAppOpenOnForeground({required bool canShow}) async {
    if (!canShow ||
        !await _cadence.isForegroundAppOpenDue() ||
        !_guard.hasElapsed(FullScreenAdCadence.fullScreenSpacing)) {
      return false;
    }
    return _loadAndShowAppOpen();
  }

  @override
  Future<bool> showBrowseInterstitial({required bool canShow}) async {
    if (!canShow || _disposed) return false;
    final decision = await _cadence.registerNovelDetailsOpen();
    if (!decision.isDue) {
      if (decision.shouldPreload) {
        unawaited(_ensureBrowseInterstitialLoaded());
      }
      return false;
    }
    final measurement = _browseMeasurement();
    unawaited(measurement.due());
    if (!_guard.hasElapsed(FullScreenAdCadence.fullScreenSpacing)) {
      unawaited(_ensureBrowseInterstitialLoaded());
      return false;
    }
    return _loadAndShowBrowseInterstitial();
  }

  @override
  Future<bool> showReaderInterstitialIfDue({required bool canShow}) async {
    if (!canShow || _disposed) return false;
    await _prepareReaderPolicy();
    final policy = _readerPolicyRepository.value;
    if (!policy.enabled) return false;
    final decision = await _cadence.registerReaderForwardTransition(policy);
    if (decision.transitionsSinceLastAd == 1 &&
        decision.targetTransitions > 0) {
      unawaited(
        analytics.record(
          AdAnalyticsEvent.readerInterstitialScheduled(
            intervalChapters: decision.targetTransitions,
          ),
        ),
      );
    }
    if (decision.shouldPreload && !decision.thresholdReached) {
      unawaited(_ensureReaderInterstitialLoaded());
    }
    if (!decision.thresholdReached) return false;

    final measurement = _readerMeasurement();
    unawaited(
      measurement.due(
        intervalChapters: decision.targetTransitions,
        transitionsSinceLastAd: decision.transitionsSinceLastAd,
      ),
    );
    if (decision.blockedByFullScreenSpacing ||
        !_guard.hasElapsed(FullScreenAdCadence.fullScreenSpacing)) {
      await _deferReaderInterstitial(
        ReaderInterstitialDeferralReason.fullScreenSpacing,
        decision,
      );
      unawaited(_ensureReaderInterstitialLoaded());
      return false;
    }

    final ad = _readerInterstitialAd;
    if (ad == null) {
      await _deferReaderInterstitial(
        ReaderInterstitialDeferralReason.notReady,
        decision,
      );
      unawaited(_ensureReaderInterstitialLoaded());
      return false;
    }
    _readerInterstitialAd = null;
    if (!_guard.tryAcquire()) {
      _readerInterstitialAd = ad;
      await _deferReaderInterstitial(
        ReaderInterstitialDeferralReason.guardBusy,
        decision,
      );
      return false;
    }
    return _presentReaderInterstitial(ad, measurement, policy, decision);
  }

  Future<void> _deferReaderInterstitial(
    ReaderInterstitialDeferralReason reason,
    ReaderInterstitialDecision decision,
  ) async {
    await _cadence.deferReaderInterstitial();
    unawaited(
      analytics.record(
        AdAnalyticsEvent.readerInterstitialDeferred(
          reason: reason,
          transitionsSinceLastAd: decision.transitionsSinceLastAd,
          targetTransitions: decision.targetTransitions,
        ),
      ),
    );
  }

  Future<void> _prepareReaderPolicy() async {
    if (_readerPolicyStarted) return;
    _readerPolicyStarted = true;
    try {
      await _readerPolicyRepository.loadCached();
      _readerPolicyRepository.startRealtimeUpdates();
      unawaited(
        _readerPolicyRepository.refresh().catchError((Object _) {
          // The bundled or cached policy remains active when Firebase fails.
        }),
      );
    } on Exception {
      // Reader navigation must not depend on Remote Config availability.
    }
  }

  Future<bool> _loadAndShowAppOpen() async {
    if (_disposed || !await _coordinator.initialize()) {
      return false;
    }
    final ad = await _loadAppOpenAd();
    if (ad == null || _disposed) {
      ad?.dispose();
      return false;
    }
    if (!_guard.tryAcquire()) {
      ad.dispose();
      return false;
    }
    return _presentAppOpen(ad);
  }

  Future<AppOpenAd?> _loadAppOpenAd() async {
    final completer = Completer<AppOpenAd?>();
    var accepting = true;
    try {
      unawaited(
        AppOpenAd.load(
          adUnitId: _appOpenAdUnitId,
          request: const AdRequest(),
          adLoadCallback: AppOpenAdLoadCallback(
            onAdLoaded: (ad) {
              if (!accepting || completer.isCompleted || _disposed) {
                ad.dispose();
                return;
              }
              completer.complete(ad);
            },
            onAdFailedToLoad: (_) {
              if (accepting && !completer.isCompleted) {
                completer.complete(null);
              }
            },
          ),
        ).catchError((Object _) {
          if (accepting && !completer.isCompleted) {
            completer.complete(null);
          }
        }),
      );
      return await completer.future.timeout(
        _appOpenLoadTimeout,
        onTimeout: () => null,
      );
    } on PlatformException {
      return null;
    } finally {
      accepting = false;
    }
  }

  Future<bool> _loadAndShowBrowseInterstitial() async {
    if (_disposed || !await _coordinator.initialize()) return false;
    final ad = await _takeBrowseInterstitial();
    if (ad == null || _disposed) {
      ad?.dispose();
      return false;
    }
    if (!_guard.tryAcquire()) {
      _browseInterstitialAd = ad;
      return false;
    }
    return _presentBrowseInterstitial(ad, _browseMeasurement());
  }

  Future<InterstitialAd?> _takeBrowseInterstitial() async {
    final cached = _browseInterstitialAd;
    if (cached != null) {
      _browseInterstitialAd = null;
      return cached;
    }
    final loaded = await _ensureBrowseInterstitialLoaded();
    if (identical(_browseInterstitialAd, loaded)) {
      _browseInterstitialAd = null;
    }
    return loaded;
  }

  Future<InterstitialAd?> _ensureBrowseInterstitialLoaded() async {
    if (_disposed) return null;
    final cached = _browseInterstitialAd;
    if (cached != null) return cached;
    if (!await _coordinator.initialize()) return null;
    final measurement = _browseMeasurement();
    final load = _browseInterstitialLoad ??= _loadBrowseInterstitial(
      measurement,
    ).whenComplete(() => _browseInterstitialLoad = null);
    final ad = await load;
    if (ad == null) _clearBrowseMeasurement(measurement);
    return ad;
  }

  Future<InterstitialAd?> _ensureReaderInterstitialLoaded() async {
    if (_disposed) return null;
    final cached = _readerInterstitialAd;
    if (cached != null) return cached;
    if (!await _coordinator.initialize()) return null;
    final measurement = _readerMeasurement();
    final load = _readerInterstitialLoad ??= _loadReaderInterstitial(
      measurement,
    ).whenComplete(() => _readerInterstitialLoad = null);
    final ad = await load;
    if (ad == null) _clearReaderMeasurement(measurement);
    return ad;
  }

  Future<InterstitialAd?> _loadReaderInterstitial(
    AdAnalyticsSession measurement,
  ) async {
    await measurement.loadRequested();
    final completer = Completer<InterstitialAd?>();
    var accepting = true;
    try {
      unawaited(
        InterstitialAd.load(
          adUnitId: _readerInterstitialAdUnitId,
          request: const AdRequest(),
          adLoadCallback: InterstitialAdLoadCallback(
            onAdLoaded: (ad) {
              if (!accepting || completer.isCompleted || _disposed) {
                ad.dispose();
                return;
              }
              unawaited(measurement.loadSuccess());
              _readerInterstitialAd = ad;
              completer.complete(ad);
            },
            onAdFailedToLoad: (error) {
              if (accepting && !completer.isCompleted) {
                unawaited(measurement.loadFailure(error.code));
                completer.complete(null);
              }
            },
          ),
        ).catchError((Object _) {
          unawaited(measurement.loadFailure(-1));
          if (accepting && !completer.isCompleted) completer.complete(null);
        }),
      );
      return await completer.future.timeout(
        _appOpenLoadTimeout,
        onTimeout: () {
          unawaited(measurement.loadFailure(-2));
          return null;
        },
      );
    } on PlatformException {
      unawaited(measurement.loadFailure(-1));
      return null;
    } finally {
      accepting = false;
    }
  }

  Future<InterstitialAd?> _loadBrowseInterstitial(
    AdAnalyticsSession measurement,
  ) async {
    await measurement.loadRequested();
    final completer = Completer<InterstitialAd?>();
    var accepting = true;
    try {
      unawaited(
        InterstitialAd.load(
          adUnitId: _browseInterstitialAdUnitId,
          request: const AdRequest(),
          adLoadCallback: InterstitialAdLoadCallback(
            onAdLoaded: (ad) {
              if (!accepting || completer.isCompleted || _disposed) {
                ad.dispose();
                return;
              }
              unawaited(measurement.loadSuccess());
              _browseInterstitialAd = ad;
              completer.complete(ad);
            },
            onAdFailedToLoad: (error) {
              if (accepting && !completer.isCompleted) {
                unawaited(measurement.loadFailure(error.code));
                completer.complete(null);
              }
            },
          ),
        ).catchError((Object _) {
          unawaited(measurement.loadFailure(-1));
          if (accepting && !completer.isCompleted) {
            completer.complete(null);
          }
        }),
      );
      return await completer.future.timeout(
        _appOpenLoadTimeout,
        onTimeout: () {
          unawaited(measurement.loadFailure(-2));
          return null;
        },
      );
    } on PlatformException {
      unawaited(measurement.loadFailure(-1));
      return null;
    } finally {
      accepting = false;
    }
  }

  Future<bool> _presentBrowseInterstitial(
    InterstitialAd ad,
    AdAnalyticsSession measurement,
  ) {
    final completer = Completer<bool>();
    var didShow = false;
    ad.fullScreenContentCallback = FullScreenContentCallback<InterstitialAd>(
      onAdShowedFullScreenContent: (_) {
        didShow = true;
        _guard.markShown();
        unawaited(measurement.show());
      },
      onAdImpression: (_) {
        unawaited(measurement.impression());
      },
      onAdClicked: (_) {
        unawaited(measurement.click());
      },
      onAdDismissedFullScreenContent: (shownAd) {
        shownAd.dispose();
        unawaited(measurement.dismiss());
        unawaited(_finishBrowseInterstitial(completer, didShow, measurement));
      },
      onAdFailedToShowFullScreenContent: (shownAd, error) {
        unawaited(measurement.showFailure(error.code));
        shownAd.dispose();
        _guard.release();
        _clearBrowseMeasurement(measurement);
        if (!completer.isCompleted) completer.complete(false);
      },
    );
    unawaited(
      ad.show().catchError((Object _) {
        unawaited(measurement.showFailure(-1));
        ad.dispose();
        _guard.release();
        _clearBrowseMeasurement(measurement);
        if (!completer.isCompleted) completer.complete(false);
      }),
    );
    return completer.future;
  }

  Future<bool> _presentReaderInterstitial(
    InterstitialAd ad,
    AdAnalyticsSession measurement,
    ReaderInterstitialPolicy policy,
    ReaderInterstitialDecision decision,
  ) {
    final completer = Completer<bool>();
    var didShow = false;
    var finalizing = false;

    void finishDismissed(InterstitialAd shownAd) {
      if (finalizing) return;
      finalizing = true;
      shownAd.dispose();
      unawaited(
        _finishReaderInterstitial(
          completer: completer,
          didShow: didShow,
          measurement: measurement,
          policy: policy,
        ),
      );
    }

    void finishFailed(InterstitialAd failedAd, int errorCode) {
      if (finalizing) return;
      finalizing = true;
      failedAd.dispose();
      unawaited(measurement.showFailure(errorCode));
      unawaited(
        _finishFailedReaderInterstitial(
          completer: completer,
          measurement: measurement,
          decision: decision,
        ),
      );
    }

    ad.fullScreenContentCallback = FullScreenContentCallback<InterstitialAd>(
      onAdShowedFullScreenContent: (_) {
        didShow = true;
        _guard.markShown();
        unawaited(measurement.show());
      },
      onAdImpression: (_) => unawaited(measurement.impression()),
      onAdClicked: (_) => unawaited(measurement.click()),
      onAdDismissedFullScreenContent: finishDismissed,
      onAdFailedToShowFullScreenContent: (shownAd, error) =>
          finishFailed(shownAd, error.code),
    );
    unawaited(
      ad.show().catchError((Object _) {
        finishFailed(ad, -1);
      }),
    );
    return completer.future;
  }

  Future<void> _finishReaderInterstitial({
    required Completer<bool> completer,
    required bool didShow,
    required AdAnalyticsSession measurement,
    required ReaderInterstitialPolicy policy,
  }) async {
    unawaited(measurement.dismiss());
    try {
      if (didShow) await _cadence.markReaderInterstitialShown(policy);
    } on Exception {
      // A local persistence failure must not trap the reader behind an ad.
    } finally {
      _guard.release();
      _clearReaderMeasurement(measurement);
      if (!completer.isCompleted) completer.complete(didShow);
    }
  }

  Future<void> _finishFailedReaderInterstitial({
    required Completer<bool> completer,
    required AdAnalyticsSession measurement,
    required ReaderInterstitialDecision decision,
  }) async {
    try {
      await _deferReaderInterstitial(
        ReaderInterstitialDeferralReason.showFailure,
        decision,
      );
    } on Exception {
      // A local persistence failure must not block the next chapter.
    } finally {
      _guard.release();
      _clearReaderMeasurement(measurement);
      if (!completer.isCompleted) completer.complete(false);
    }
  }

  Future<void> _finishBrowseInterstitial(
    Completer<bool> completer,
    bool didShow,
    AdAnalyticsSession measurement,
  ) async {
    if (didShow) await _cadence.markBrowseInterstitialShown();
    _guard.release();
    _clearBrowseMeasurement(measurement);
    if (!completer.isCompleted) completer.complete(didShow);
  }

  AdAnalyticsSession _browseMeasurement() {
    return _browseInterstitialMeasurement ??= AdAnalyticsSession(
      analytics: analytics,
      format: AdAnalyticsFormat.interstitial,
      placement: AdAnalyticsPlacement.browse,
    );
  }

  AdAnalyticsSession _readerMeasurement() {
    return _readerInterstitialMeasurement ??= AdAnalyticsSession(
      analytics: analytics,
      format: AdAnalyticsFormat.interstitial,
      placement: AdAnalyticsPlacement.reader,
    );
  }

  void _clearBrowseMeasurement(AdAnalyticsSession? measurement) {
    if (identical(_browseInterstitialMeasurement, measurement)) {
      _browseInterstitialMeasurement = null;
    }
  }

  void _clearReaderMeasurement(AdAnalyticsSession? measurement) {
    if (identical(_readerInterstitialMeasurement, measurement)) {
      _readerInterstitialMeasurement = null;
    }
  }

  Future<bool> _presentAppOpen(AppOpenAd ad) {
    final completer = Completer<bool>();
    var didShow = false;
    ad.fullScreenContentCallback = FullScreenContentCallback<AppOpenAd>(
      onAdShowedFullScreenContent: (_) {
        didShow = true;
        _guard.markShown();
      },
      onAdDismissedFullScreenContent: (shownAd) {
        shownAd.dispose();
        unawaited(_finishAppOpen(completer, didShow));
      },
      onAdFailedToShowFullScreenContent: (shownAd, _) {
        shownAd.dispose();
        _guard.release();
        if (!completer.isCompleted) {
          completer.complete(false);
        }
      },
    );
    unawaited(
      ad.show().catchError((Object _) {
        ad.dispose();
        _guard.release();
        if (!completer.isCompleted) {
          completer.complete(false);
        }
      }),
    );
    return completer.future;
  }

  Future<void> _finishAppOpen(Completer<bool> completer, bool didShow) async {
    if (didShow) {
      await _cadence.markAppOpenShown();
    }
    _guard.release();
    if (!completer.isCompleted) {
      completer.complete(didShow);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _browseInterstitialAd?.dispose();
    _browseInterstitialAd = null;
    _browseInterstitialMeasurement = null;
    _readerInterstitialAd?.dispose();
    _readerInterstitialAd = null;
    _readerInterstitialMeasurement = null;
    _readerPolicyRepository.dispose();
  }
}
