import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/core/analytics/app_analytics.dart';
import 'package:galaxy_novels_app/features/ads/application/ad_analytics.dart';

void main() {
  test('native load failure contains only normalized measurement data', () {
    final event = AdAnalyticsEvent.loadFailure(
      format: AdAnalyticsFormat.native,
      placement: AdAnalyticsPlacement.library,
      errorCode: 3,
    );

    expect(event.name, 'galaxy_ad_load_failure');
    expect(event.parameters, {
      'format': 'native',
      'placement': 'library',
      'error_code': 3,
    });
    expect(event.parameters, isNot(contains('error_message')));
    expect(event.parameters, isNot(contains('ad_unit_id')));
  });

  test('reader interstitial uses a distinct analytics placement', () {
    final event = AdAnalyticsEvent.show(
      format: AdAnalyticsFormat.interstitial,
      placement: AdAnalyticsPlacement.reader,
    );

    expect(event.parameters, {'format': 'interstitial', 'placement': 'reader'});
  });

  test('reader cadence analytics contain counts but no content identity', () {
    final scheduled = AdAnalyticsEvent.readerInterstitialScheduled(
      intervalChapters: 12,
    );
    final deferred = AdAnalyticsEvent.readerInterstitialDeferred(
      reason: ReaderInterstitialDeferralReason.notReady,
      transitionsSinceLastAd: 12,
      targetTransitions: 12,
    );
    final due = AdAnalyticsEvent.due(
      format: AdAnalyticsFormat.interstitial,
      placement: AdAnalyticsPlacement.reader,
      intervalChapters: 12,
      transitionsSinceLastAd: 12,
    );

    expect(scheduled.name, 'galaxy_reader_ad_scheduled');
    expect(scheduled.parameters, {
      'format': 'interstitial',
      'placement': 'reader',
      'interval_chapters': 12,
    });
    expect(deferred.name, 'galaxy_reader_ad_deferred');
    expect(deferred.parameters, {
      'format': 'interstitial',
      'placement': 'reader',
      'reason': 'not_ready',
      'transitions_since_last_ad': 12,
      'target_transitions': 12,
    });
    expect(due.parameters, {
      'format': 'interstitial',
      'placement': 'reader',
      'interval_chapters': 12,
      'transitions_since_last_ad': 12,
    });
    for (final event in [scheduled, deferred, due]) {
      expect(event.parameters, isNot(contains('novel_id')));
      expect(event.parameters, isNot(contains('chapter_id')));
      expect(event.parameters, isNot(contains('user_id')));
    }
  });

  test('every lifecycle action has a stable Firebase-safe event name', () {
    final events = [
      AdAnalyticsEvent.loadRequested(
        format: AdAnalyticsFormat.native,
        placement: AdAnalyticsPlacement.home,
      ),
      AdAnalyticsEvent.loadSuccess(
        format: AdAnalyticsFormat.native,
        placement: AdAnalyticsPlacement.home,
      ),
      AdAnalyticsEvent.impression(
        format: AdAnalyticsFormat.native,
        placement: AdAnalyticsPlacement.home,
      ),
      AdAnalyticsEvent.click(
        format: AdAnalyticsFormat.native,
        placement: AdAnalyticsPlacement.home,
      ),
      AdAnalyticsEvent.due(
        format: AdAnalyticsFormat.interstitial,
        placement: AdAnalyticsPlacement.browse,
      ),
      AdAnalyticsEvent.show(
        format: AdAnalyticsFormat.interstitial,
        placement: AdAnalyticsPlacement.browse,
      ),
      AdAnalyticsEvent.dismiss(
        format: AdAnalyticsFormat.interstitial,
        placement: AdAnalyticsPlacement.browse,
      ),
      AdAnalyticsEvent.showFailure(
        format: AdAnalyticsFormat.interstitial,
        placement: AdAnalyticsPlacement.browse,
        errorCode: 1,
      ),
    ];

    expect(events.map((event) => event.name), {
      'galaxy_ad_load_request',
      'galaxy_ad_load_success',
      'galaxy_ad_impression',
      'galaxy_ad_click',
      'galaxy_ad_due',
      'galaxy_ad_show',
      'galaxy_ad_dismiss',
      'galaxy_ad_show_failure',
    });
    for (final event in events) {
      expect(event.name, matches(RegExp(r'^[a-z][a-z0-9_]{0,39}$')));
    }
  });

  test(
    'ad analytics forwards typed events to the app analytics boundary',
    () async {
      final appAnalytics = _RecordingAppAnalytics();
      final analytics = AdAnalytics(appAnalytics);
      final event = AdAnalyticsEvent.impression(
        format: AdAnalyticsFormat.native,
        placement: AdAnalyticsPlacement.readerJourney,
      );

      await analytics.record(event);

      expect(appAnalytics.events, hasLength(1));
      expect(appAnalytics.events.single.name, 'galaxy_ad_impression');
      expect(appAnalytics.events.single.parameters, {
        'format': 'native',
        'placement': 'reader_journey',
      });
    },
  );

  test(
    'measurement session reports each one-shot lifecycle event once',
    () async {
      final appAnalytics = _RecordingAppAnalytics();
      final session = AdAnalyticsSession(
        analytics: AdAnalytics(appAnalytics),
        format: AdAnalyticsFormat.native,
        placement: AdAnalyticsPlacement.rankings,
      );

      await session.loadRequested();
      await session.loadRequested();
      await session.loadSuccess();
      await session.loadSuccess();
      await session.impression();
      await session.impression();
      await session.click();
      await session.click();

      expect(appAnalytics.events.map((event) => event.name), [
        'galaxy_ad_load_request',
        'galaxy_ad_load_success',
        'galaxy_ad_impression',
        'galaxy_ad_click',
      ]);
    },
  );

  test('measurement session preserves only numeric ad error codes', () async {
    final appAnalytics = _RecordingAppAnalytics();
    final session = AdAnalyticsSession(
      analytics: AdAnalytics(appAnalytics),
      format: AdAnalyticsFormat.interstitial,
      placement: AdAnalyticsPlacement.browse,
    );

    await session.loadFailure(3);
    await session.showFailure(1);

    expect(appAnalytics.events[0].parameters, {
      'format': 'interstitial',
      'placement': 'browse',
      'error_code': 3,
    });
    expect(appAnalytics.events[1].parameters, {
      'format': 'interstitial',
      'placement': 'browse',
      'error_code': 1,
    });
  });

  test('measurement failure never interrupts the ad lifecycle', () async {
    final analytics = AdAnalytics(_FailingAppAnalytics());

    await expectLater(
      analytics.record(
        AdAnalyticsEvent.impression(
          format: AdAnalyticsFormat.native,
          placement: AdAnalyticsPlacement.home,
        ),
      ),
      completes,
    );
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

class _FailingAppAnalytics implements AppAnalytics {
  @override
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) {
    throw Exception('analytics unavailable');
  }

  @override
  Future<void> logScreenView(String screenName) async {}
}
