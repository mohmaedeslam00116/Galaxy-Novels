import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/features/downloads/application/download_analytics.dart';

void main() {
  test('plan event contains aggregate values only', () {
    final event = DownloadAnalyticsEvent.planConfirmed(
      selectionType: 'next',
      chapterCount: 25,
      availableNow: 18,
      rewardCapacity: 7,
      deferredCount: 0,
      skippedCount: 3,
      membershipTier: 'regular',
    );

    expect(event.name, 'download_plan_confirmed');
    expect(event.parameters['chapter_count'], 25);
    expect(
      event.parameters.keys,
      isNot(
        anyOf(contains('novel'), contains('chapter_title'), contains('user')),
      ),
    );
    expect(
      event.parameters.values.whereType<String>(),
      isNot(contains('رواية سرية')),
    );
  });

  test('quota event reports waiting counts without content identifiers', () {
    final event = DownloadAnalyticsEvent.quotaExhausted(
      waitingCount: 7,
      adsRemaining: 4,
      membershipTier: 'vip1',
    );

    expect(event.name, 'download_quota_exhausted');
    expect(event.parameters, {
      'waiting_count': 7,
      'ads_remaining': 4,
      'membership_tier': 'vip1',
    });
  });
}
