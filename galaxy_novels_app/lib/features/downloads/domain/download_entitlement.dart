import 'dart:math' as math;

import '../../account/domain/auth_session.dart';

enum DownloadMembershipTier {
  regular,
  vip1,
  vip2,
  vip3,
  vipMax;

  static DownloadMembershipTier fromVip(AuthVip? vip) {
    if (vip == null || !vip.active) {
      return DownloadMembershipTier.regular;
    }

    return switch (vip.tier.trim().toLowerCase()) {
      'vip1' || 'vip_1' => DownloadMembershipTier.vip1,
      'vip2' || 'vip_2' => DownloadMembershipTier.vip2,
      'vip3' || 'vip_3' => DownloadMembershipTier.vip3,
      'max' || 'vipmax' || 'vip_max' => DownloadMembershipTier.vipMax,
      _ => DownloadMembershipTier.regular,
    };
  }
}

class DownloadPlan {
  const DownloadPlan({
    required this.baseChapters,
    required this.maxRewardedAds,
    required this.rewardPerAd,
  });

  final int baseChapters;
  final int maxRewardedAds;
  final int rewardPerAd;

  int get maximumDailyChapters => baseChapters + (maxRewardedAds * rewardPerAd);

  static DownloadPlan forTier(DownloadMembershipTier tier) {
    return switch (tier) {
      DownloadMembershipTier.regular => const DownloadPlan(
        baseChapters: 100,
        maxRewardedAds: 4,
        rewardPerAd: 20,
      ),
      DownloadMembershipTier.vip1 => const DownloadPlan(
        baseChapters: 200,
        maxRewardedAds: 5,
        rewardPerAd: 40,
      ),
      DownloadMembershipTier.vip2 => const DownloadPlan(
        baseChapters: 400,
        maxRewardedAds: 5,
        rewardPerAd: 80,
      ),
      DownloadMembershipTier.vip3 => const DownloadPlan(
        baseChapters: 600,
        maxRewardedAds: 5,
        rewardPerAd: 100,
      ),
      DownloadMembershipTier.vipMax => const DownloadPlan(
        baseChapters: 1000,
        maxRewardedAds: 6,
        rewardPerAd: 100,
      ),
    };
  }
}

class DownloadAllowance {
  const DownloadAllowance({
    required this.plan,
    required this.remaining,
    required this.adsRemaining,
    required this.shouldReset,
    required this.effectiveDayOrdinal,
  });

  final DownloadPlan plan;
  final int remaining;
  final int adsRemaining;
  final bool shouldReset;
  final int effectiveDayOrdinal;

  bool get canDownload => remaining > 0;
  bool get canWatchRewardedAd => remaining == 0 && adsRemaining > 0;
}

class DownloadEntitlementPolicy {
  const DownloadEntitlementPolicy();

  DownloadAllowance evaluate({
    required DateTime now,
    required int highestLocalDayOrdinal,
    required int completed,
    required int reserved,
    required int rewardedCredits,
    required int completedAds,
    required DownloadMembershipTier tier,
  }) {
    final plan = DownloadPlan.forTier(tier);
    final currentDayOrdinal = now.dayOrdinal;
    final shouldReset = currentDayOrdinal > highestLocalDayOrdinal;

    if (shouldReset) {
      return DownloadAllowance(
        plan: plan,
        remaining: plan.baseChapters,
        adsRemaining: plan.maxRewardedAds,
        shouldReset: true,
        effectiveDayOrdinal: currentDayOrdinal,
      );
    }

    return DownloadAllowance(
      plan: plan,
      remaining: math.max(
        0,
        plan.baseChapters + rewardedCredits - completed - reserved,
      ),
      adsRemaining: math.max(0, plan.maxRewardedAds - completedAds),
      shouldReset: false,
      effectiveDayOrdinal: highestLocalDayOrdinal,
    );
  }
}

extension LocalDownloadDay on DateTime {
  int get dayOrdinal =>
      DateTime(year, month, day).millisecondsSinceEpoch ~/
      Duration.millisecondsPerDay;
}
