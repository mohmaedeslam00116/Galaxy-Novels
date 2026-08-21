import 'package:flutter/foundation.dart';

import '../domain/download_entitlement.dart';

@immutable
class DownloadAnalyticsEvent {
  DownloadAnalyticsEvent._(this.name, Map<String, Object> parameters)
    : parameters = Map.unmodifiable(parameters);

  factory DownloadAnalyticsEvent.plannerOpened({
    required String selectionType,
    required String membershipTier,
  }) => DownloadAnalyticsEvent._('download_planner_opened', {
    'selection_type': selectionType,
    'membership_tier': membershipTier,
  });

  factory DownloadAnalyticsEvent.selectionChanged({
    required String selectionType,
    required int chapterCount,
  }) => DownloadAnalyticsEvent._('download_selection_changed', {
    'selection_type': selectionType,
    'chapter_count': chapterCount,
  });

  factory DownloadAnalyticsEvent.planConfirmed({
    required String selectionType,
    required int chapterCount,
    required int availableNow,
    required int rewardCapacity,
    required int deferredCount,
    required int skippedCount,
    required String membershipTier,
  }) => DownloadAnalyticsEvent._('download_plan_confirmed', {
    'selection_type': selectionType,
    'chapter_count': chapterCount,
    'available_now': availableNow,
    'reward_capacity': rewardCapacity,
    'deferred_count': deferredCount,
    'skipped_count': skippedCount,
    'balance_relation': chapterCount <= availableNow
        ? 'within_balance'
        : deferredCount > 0
        ? 'cross_day'
        : 'needs_reward',
    'membership_tier': membershipTier,
  });

  factory DownloadAnalyticsEvent.groupStarted({
    required int acceptedCount,
    required int skippedCount,
    required String membershipTier,
  }) => DownloadAnalyticsEvent._('download_group_started', {
    'accepted_count': acceptedCount,
    'skipped_count': skippedCount,
    'membership_tier': membershipTier,
  });

  factory DownloadAnalyticsEvent.groupFailed({
    required int chapterCount,
    required String membershipTier,
  }) => DownloadAnalyticsEvent._('download_group_failed', {
    'chapter_count': chapterCount,
    'membership_tier': membershipTier,
  });

  factory DownloadAnalyticsEvent.groupCompleted({
    required int chapterCount,
    required String membershipTier,
  }) => DownloadAnalyticsEvent._('download_group_completed', {
    'chapter_count': chapterCount,
    'membership_tier': membershipTier,
  });

  factory DownloadAnalyticsEvent.quotaExhausted({
    required int waitingCount,
    required int adsRemaining,
    required String membershipTier,
  }) => DownloadAnalyticsEvent._('download_quota_exhausted', {
    'waiting_count': waitingCount,
    'ads_remaining': adsRemaining,
    'membership_tier': membershipTier,
  });

  factory DownloadAnalyticsEvent.reward({
    required String stage,
    required int rewardAmount,
    required int adsRemaining,
    required String membershipTier,
  }) => DownloadAnalyticsEvent._('download_reward_$stage', {
    'reward_amount': rewardAmount,
    'ads_remaining': adsRemaining,
    'membership_tier': membershipTier,
  });

  final String name;
  final Map<String, Object> parameters;
}

abstract interface class DownloadAnalytics {
  Future<void> record(DownloadAnalyticsEvent event);
}

class NoopDownloadAnalytics implements DownloadAnalytics {
  const NoopDownloadAnalytics();

  @override
  Future<void> record(DownloadAnalyticsEvent event) async {}
}

String downloadMembershipLabel(DownloadPlan plan) {
  for (final tier in DownloadMembershipTier.values) {
    final candidate = DownloadPlan.forTier(tier);
    if (candidate.baseChapters == plan.baseChapters &&
        candidate.maxRewardedAds == plan.maxRewardedAds &&
        candidate.rewardPerAd == plan.rewardPerAd) {
      return tier.name;
    }
  }
  return DownloadMembershipTier.regular.name;
}
