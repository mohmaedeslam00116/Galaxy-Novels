import 'dart:math';

import '../domain/reader_interstitial_policy.dart';

class FullScreenAdCadenceState {
  const FullScreenAdCadenceState({
    this.appLaunches = 0,
    this.lastAppOpenShownAt,
    this.novelDetailOpensSinceBrowseAd = 0,
    this.lastFullScreenShownAt,
    this.readerForwardTransitionsSinceInterstitial = 0,
    this.readerInterstitialTarget = 0,
    this.readerInterstitialRetryAtTransition = 0,
  });

  final int appLaunches;
  final DateTime? lastAppOpenShownAt;
  final int novelDetailOpensSinceBrowseAd;
  final DateTime? lastFullScreenShownAt;
  final int readerForwardTransitionsSinceInterstitial;
  final int readerInterstitialTarget;
  final int readerInterstitialRetryAtTransition;

  FullScreenAdCadenceState copyWith({
    int? appLaunches,
    DateTime? lastAppOpenShownAt,
    int? novelDetailOpensSinceBrowseAd,
    DateTime? lastFullScreenShownAt,
    int? readerForwardTransitionsSinceInterstitial,
    int? readerInterstitialTarget,
    int? readerInterstitialRetryAtTransition,
  }) {
    return FullScreenAdCadenceState(
      appLaunches: appLaunches ?? this.appLaunches,
      lastAppOpenShownAt: lastAppOpenShownAt ?? this.lastAppOpenShownAt,
      novelDetailOpensSinceBrowseAd:
          novelDetailOpensSinceBrowseAd ?? this.novelDetailOpensSinceBrowseAd,
      lastFullScreenShownAt:
          lastFullScreenShownAt ?? this.lastFullScreenShownAt,
      readerForwardTransitionsSinceInterstitial:
          readerForwardTransitionsSinceInterstitial ??
          this.readerForwardTransitionsSinceInterstitial,
      readerInterstitialTarget:
          readerInterstitialTarget ?? this.readerInterstitialTarget,
      readerInterstitialRetryAtTransition:
          readerInterstitialRetryAtTransition ??
          this.readerInterstitialRetryAtTransition,
    );
  }
}

class BrowseInterstitialDecision {
  const BrowseInterstitialDecision({
    required this.opensSinceLastBrowseAd,
    required this.isDue,
    required this.shouldPreload,
  });

  final int opensSinceLastBrowseAd;
  final bool isDue;
  final bool shouldPreload;
}

class ReaderInterstitialDecision {
  const ReaderInterstitialDecision({
    required this.enabled,
    required this.transitionsSinceLastAd,
    required this.targetTransitions,
    required this.thresholdReached,
    required this.isDue,
    required this.shouldPreload,
    required this.blockedByFullScreenSpacing,
  });

  final bool enabled;
  final int transitionsSinceLastAd;
  final int targetTransitions;
  final bool thresholdReached;
  final bool isDue;
  final bool shouldPreload;
  final bool blockedByFullScreenSpacing;
}

typedef ReaderInterstitialTargetPicker = int Function(int minimum, int maximum);

abstract class FullScreenAdCadenceStore {
  Future<FullScreenAdCadenceState> read();

  Future<void> write(FullScreenAdCadenceState state);
}

class FullScreenAdCadence {
  FullScreenAdCadence({
    required FullScreenAdCadenceStore store,
    DateTime Function()? now,
    ReaderInterstitialTargetPicker? readerTargetPicker,
  }) : _store = store,
       _now = now ?? DateTime.now,
       _readerTargetPicker =
           readerTargetPicker ??
           ((minimum, maximum) =>
               minimum + Random().nextInt(maximum - minimum + 1));

  static const launchesBeforeFirstAppOpen = 3;
  static const appOpenCooldown = Duration(hours: 4);
  static const novelDetailsOpensPerInterstitial = 5;
  static const fullScreenSpacing = Duration(minutes: 5);

  final FullScreenAdCadenceStore _store;
  final DateTime Function() _now;
  final ReaderInterstitialTargetPicker _readerTargetPicker;
  FullScreenAdCadenceState? _state;

  Future<bool> registerColdLaunchAndIsAppOpenDue() async {
    final state = await _load();
    _state = state.copyWith(appLaunches: state.appLaunches + 1);
    await _save();
    return _isAppOpenDue(_state!);
  }

  Future<bool> isForegroundAppOpenDue() async {
    return _isAppOpenDue(await _load());
  }

  Future<void> markAppOpenShown() async {
    final state = await _load();
    final shownAt = _now().toUtc();
    _state = FullScreenAdCadenceState(
      appLaunches: state.appLaunches,
      lastAppOpenShownAt: shownAt,
      novelDetailOpensSinceBrowseAd: state.novelDetailOpensSinceBrowseAd,
      lastFullScreenShownAt: shownAt,
      readerForwardTransitionsSinceInterstitial:
          state.readerForwardTransitionsSinceInterstitial,
      readerInterstitialTarget: state.readerInterstitialTarget,
      readerInterstitialRetryAtTransition:
          state.readerInterstitialRetryAtTransition,
    );
    await _save();
  }

  Future<BrowseInterstitialDecision> registerNovelDetailsOpen() async {
    final state = await _load();
    _state = state.copyWith(
      novelDetailOpensSinceBrowseAd: state.novelDetailOpensSinceBrowseAd + 1,
    );
    await _save();
    return _browseDecision(_state!);
  }

  Future<BrowseInterstitialDecision> peekBrowseInterstitialDecision() async {
    return _browseDecision(await _load());
  }

  Future<void> markBrowseInterstitialShown() async {
    final state = await _load();
    _state = FullScreenAdCadenceState(
      appLaunches: state.appLaunches,
      lastAppOpenShownAt: state.lastAppOpenShownAt,
      lastFullScreenShownAt: _now().toUtc(),
      readerForwardTransitionsSinceInterstitial:
          state.readerForwardTransitionsSinceInterstitial,
      readerInterstitialTarget: state.readerInterstitialTarget,
      readerInterstitialRetryAtTransition:
          state.readerInterstitialRetryAtTransition,
    );
    await _save();
  }

  Future<ReaderInterstitialDecision> registerReaderForwardTransition(
    ReaderInterstitialPolicy policy,
  ) async {
    final state = await _load();
    if (!policy.enabled) return _readerDecision(state, policy);
    final target = state.readerInterstitialTarget > 0
        ? state.readerInterstitialTarget
        : _pickReaderTarget(policy);
    _state = state.copyWith(
      readerForwardTransitionsSinceInterstitial:
          state.readerForwardTransitionsSinceInterstitial + 1,
      readerInterstitialTarget: target,
    );
    await _save();
    return _readerDecision(_state!, policy);
  }

  Future<ReaderInterstitialDecision> peekReaderInterstitialDecision(
    ReaderInterstitialPolicy policy,
  ) async {
    return _readerDecision(await _load(), policy);
  }

  Future<void> deferReaderInterstitial({int transitions = 2}) async {
    final state = await _load();
    if (state.readerInterstitialTarget <= 0) return;
    _state = state.copyWith(
      readerInterstitialRetryAtTransition:
          state.readerForwardTransitionsSinceInterstitial +
          transitions.clamp(1, 100),
    );
    await _save();
  }

  Future<void> markReaderInterstitialShown(
    ReaderInterstitialPolicy policy,
  ) async {
    final state = await _load();
    _state = FullScreenAdCadenceState(
      appLaunches: state.appLaunches,
      lastAppOpenShownAt: state.lastAppOpenShownAt,
      novelDetailOpensSinceBrowseAd: state.novelDetailOpensSinceBrowseAd,
      lastFullScreenShownAt: _now().toUtc(),
      readerInterstitialTarget: _pickReaderTarget(policy),
    );
    await _save();
  }

  Future<FullScreenAdCadenceState> _load() async {
    return _state ??= await _store.read();
  }

  Future<void> _save() async {
    await _store.write(_state!);
  }

  bool _isAppOpenDue(FullScreenAdCadenceState state) {
    if (state.appLaunches <= launchesBeforeFirstAppOpen) {
      return false;
    }
    final lastShownAt = state.lastAppOpenShownAt;
    final now = _now().toUtc();
    final appOpenReady =
        lastShownAt == null ||
        now.difference(lastShownAt.toUtc()) >= appOpenCooldown;
    return appOpenReady && _hasFullScreenSpacing(state, now);
  }

  BrowseInterstitialDecision _browseDecision(FullScreenAdCadenceState state) {
    final opens = state.novelDetailOpensSinceBrowseAd;
    return BrowseInterstitialDecision(
      opensSinceLastBrowseAd: opens,
      isDue:
          opens >= novelDetailsOpensPerInterstitial &&
          _hasFullScreenSpacing(state, _now().toUtc()),
      shouldPreload: opens >= novelDetailsOpensPerInterstitial - 1,
    );
  }

  ReaderInterstitialDecision _readerDecision(
    FullScreenAdCadenceState state,
    ReaderInterstitialPolicy policy,
  ) {
    final transitions = state.readerForwardTransitionsSinceInterstitial;
    final scheduledTarget = state.readerInterstitialTarget;
    final retryTarget = state.readerInterstitialRetryAtTransition;
    final effectiveTarget = retryTarget > 0 ? retryTarget : scheduledTarget;
    final thresholdReached =
        policy.enabled && effectiveTarget > 0 && transitions >= effectiveTarget;
    final spacingSatisfied = _hasFullScreenSpacing(state, _now().toUtc());
    return ReaderInterstitialDecision(
      enabled: policy.enabled,
      transitionsSinceLastAd: transitions,
      targetTransitions: effectiveTarget,
      thresholdReached: thresholdReached,
      isDue: thresholdReached && spacingSatisfied,
      shouldPreload:
          policy.enabled &&
          effectiveTarget > 0 &&
          effectiveTarget - transitions <= 2,
      blockedByFullScreenSpacing: thresholdReached && !spacingSatisfied,
    );
  }

  int _pickReaderTarget(ReaderInterstitialPolicy policy) {
    return _readerTargetPicker(
      policy.minimumChapters,
      policy.maximumChapters,
    ).clamp(policy.minimumChapters, policy.maximumChapters);
  }

  bool _hasFullScreenSpacing(FullScreenAdCadenceState state, DateTime now) {
    final lastShownAt = state.lastFullScreenShownAt;
    return lastShownAt == null ||
        now.difference(lastShownAt.toUtc()) >= fullScreenSpacing;
  }
}
