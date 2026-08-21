import '../../../core/analytics/app_analytics.dart';

enum AdAnalyticsFormat { native, interstitial, appOpen }

enum ReaderInterstitialDeferralReason {
  notReady,
  fullScreenSpacing,
  guardBusy,
  showFailure,
}

extension on ReaderInterstitialDeferralReason {
  String get analyticsName => switch (this) {
    ReaderInterstitialDeferralReason.notReady => 'not_ready',
    ReaderInterstitialDeferralReason.fullScreenSpacing => 'full_screen_spacing',
    ReaderInterstitialDeferralReason.guardBusy => 'guard_busy',
    ReaderInterstitialDeferralReason.showFailure => 'show_failure',
  };
}

enum AdAnalyticsPlacement {
  home,
  novelDetails,
  library,
  rankings,
  readerJourney,
  reader,
  browse,
  appOpen,
}

extension on AdAnalyticsPlacement {
  String get analyticsName => switch (this) {
    AdAnalyticsPlacement.novelDetails => 'novel_details',
    AdAnalyticsPlacement.readerJourney => 'reader_journey',
    AdAnalyticsPlacement.appOpen => 'app_open',
    _ => name,
  };
}

class AdAnalyticsEvent {
  const AdAnalyticsEvent._(this.name, this.parameters);

  factory AdAnalyticsEvent.loadRequested({
    required AdAnalyticsFormat format,
    required AdAnalyticsPlacement placement,
  }) => _create('galaxy_ad_load_request', format, placement);

  factory AdAnalyticsEvent.loadSuccess({
    required AdAnalyticsFormat format,
    required AdAnalyticsPlacement placement,
  }) => _create('galaxy_ad_load_success', format, placement);

  factory AdAnalyticsEvent.loadFailure({
    required AdAnalyticsFormat format,
    required AdAnalyticsPlacement placement,
    required int errorCode,
  }) => _create(
    'galaxy_ad_load_failure',
    format,
    placement,
    errorCode: errorCode,
  );

  factory AdAnalyticsEvent.impression({
    required AdAnalyticsFormat format,
    required AdAnalyticsPlacement placement,
  }) => _create('galaxy_ad_impression', format, placement);

  factory AdAnalyticsEvent.click({
    required AdAnalyticsFormat format,
    required AdAnalyticsPlacement placement,
  }) => _create('galaxy_ad_click', format, placement);

  factory AdAnalyticsEvent.due({
    required AdAnalyticsFormat format,
    required AdAnalyticsPlacement placement,
    int? intervalChapters,
    int? transitionsSinceLastAd,
  }) => _create(
    'galaxy_ad_due',
    format,
    placement,
    extraParameters: {
      'interval_chapters': ?intervalChapters,
      'transitions_since_last_ad': ?transitionsSinceLastAd,
    },
  );

  factory AdAnalyticsEvent.show({
    required AdAnalyticsFormat format,
    required AdAnalyticsPlacement placement,
  }) => _create('galaxy_ad_show', format, placement);

  factory AdAnalyticsEvent.dismiss({
    required AdAnalyticsFormat format,
    required AdAnalyticsPlacement placement,
  }) => _create('galaxy_ad_dismiss', format, placement);

  factory AdAnalyticsEvent.showFailure({
    required AdAnalyticsFormat format,
    required AdAnalyticsPlacement placement,
    required int errorCode,
  }) => _create(
    'galaxy_ad_show_failure',
    format,
    placement,
    errorCode: errorCode,
  );

  factory AdAnalyticsEvent.readerInterstitialScheduled({
    required int intervalChapters,
  }) => AdAnalyticsEvent._(
    'galaxy_reader_ad_scheduled',
    Map.unmodifiable({
      'format': AdAnalyticsFormat.interstitial.name,
      'placement': AdAnalyticsPlacement.reader.analyticsName,
      'interval_chapters': intervalChapters,
    }),
  );

  factory AdAnalyticsEvent.readerInterstitialDeferred({
    required ReaderInterstitialDeferralReason reason,
    required int transitionsSinceLastAd,
    required int targetTransitions,
  }) => AdAnalyticsEvent._(
    'galaxy_reader_ad_deferred',
    Map.unmodifiable({
      'format': AdAnalyticsFormat.interstitial.name,
      'placement': AdAnalyticsPlacement.reader.analyticsName,
      'reason': reason.analyticsName,
      'transitions_since_last_ad': transitionsSinceLastAd,
      'target_transitions': targetTransitions,
    }),
  );

  static AdAnalyticsEvent _create(
    String name,
    AdAnalyticsFormat format,
    AdAnalyticsPlacement placement, {
    int? errorCode,
    Map<String, Object> extraParameters = const {},
  }) {
    return AdAnalyticsEvent._(
      name,
      Map.unmodifiable({
        'format': format.name,
        'placement': placement.analyticsName,
        'error_code': ?errorCode,
        ...extraParameters,
      }),
    );
  }

  final String name;
  final Map<String, Object> parameters;
}

class AdAnalytics {
  const AdAnalytics(this._analytics);
  const AdAnalytics.noop() : _analytics = const NoopAppAnalytics();

  final AppAnalytics _analytics;

  Future<void> record(AdAnalyticsEvent event) async {
    try {
      await _analytics.logEvent(event.name, parameters: event.parameters);
    } on Exception {
      // Measurement must never interrupt ad delivery or navigation.
    }
  }
}

class AdAnalyticsSession {
  AdAnalyticsSession({
    required AdAnalytics analytics,
    required this.format,
    required this.placement,
  }) : _analytics = analytics;

  final AdAnalytics _analytics;
  final AdAnalyticsFormat format;
  final AdAnalyticsPlacement placement;
  final Set<String> _recorded = <String>{};

  Future<void> loadRequested() => _once(
    'load_request',
    AdAnalyticsEvent.loadRequested(format: format, placement: placement),
  );

  Future<void> loadSuccess() => _once(
    'load_success',
    AdAnalyticsEvent.loadSuccess(format: format, placement: placement),
  );

  Future<void> loadFailure(int errorCode) => _once(
    'load_failure',
    AdAnalyticsEvent.loadFailure(
      format: format,
      placement: placement,
      errorCode: errorCode,
    ),
  );

  Future<void> impression() => _once(
    'impression',
    AdAnalyticsEvent.impression(format: format, placement: placement),
  );

  Future<void> click() => _once(
    'click',
    AdAnalyticsEvent.click(format: format, placement: placement),
  );

  Future<void> due({int? intervalChapters, int? transitionsSinceLastAd}) =>
      _once(
        'due',
        AdAnalyticsEvent.due(
          format: format,
          placement: placement,
          intervalChapters: intervalChapters,
          transitionsSinceLastAd: transitionsSinceLastAd,
        ),
      );

  Future<void> show() => _once(
    'show',
    AdAnalyticsEvent.show(format: format, placement: placement),
  );

  Future<void> dismiss() => _once(
    'dismiss',
    AdAnalyticsEvent.dismiss(format: format, placement: placement),
  );

  Future<void> showFailure(int errorCode) => _once(
    'show_failure',
    AdAnalyticsEvent.showFailure(
      format: format,
      placement: placement,
      errorCode: errorCode,
    ),
  );

  Future<void> _once(String key, AdAnalyticsEvent event) async {
    if (!_recorded.add(key)) return;
    await _analytics.record(event);
  }
}
