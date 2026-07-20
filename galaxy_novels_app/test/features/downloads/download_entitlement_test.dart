import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/features/account/domain/auth_session.dart';
import 'package:galaxy_novels_app/features/downloads/domain/download_entitlement.dart';

void main() {
  group('DownloadPlan', () {
    const cases = [
      (tier: DownloadMembershipTier.regular, base: 100, ads: 4, reward: 20),
      (tier: DownloadMembershipTier.vip1, base: 200, ads: 5, reward: 40),
      (tier: DownloadMembershipTier.vip2, base: 400, ads: 5, reward: 80),
      (tier: DownloadMembershipTier.vip3, base: 600, ads: 5, reward: 100),
      (tier: DownloadMembershipTier.vipMax, base: 1000, ads: 6, reward: 100),
    ];

    for (final value in cases) {
      test('${value.tier} exposes the approved plan', () {
        final plan = DownloadPlan.forTier(value.tier);

        expect(plan.baseChapters, value.base);
        expect(plan.maxRewardedAds, value.ads);
        expect(plan.rewardPerAd, value.reward);
        expect(
          plan.maximumDailyChapters,
          value.base + (value.ads * value.reward),
        );
      });
    }
  });

  group('DownloadMembershipTier.fromVip', () {
    const aliases = {
      'vip1': DownloadMembershipTier.vip1,
      'vip_1': DownloadMembershipTier.vip1,
      'vip2': DownloadMembershipTier.vip2,
      'vip_2': DownloadMembershipTier.vip2,
      'vip3': DownloadMembershipTier.vip3,
      'vip_3': DownloadMembershipTier.vip3,
      'max': DownloadMembershipTier.vipMax,
      'vipmax': DownloadMembershipTier.vipMax,
      'vip_max': DownloadMembershipTier.vipMax,
    };

    for (final entry in aliases.entries) {
      test('maps ${entry.key}', () {
        expect(
          DownloadMembershipTier.fromVip(_vip(active: true, tier: entry.key)),
          entry.value,
        );
      });
    }

    test('normalizes whitespace and letter case', () {
      expect(
        DownloadMembershipTier.fromVip(_vip(active: true, tier: ' VIP_MAX ')),
        DownloadMembershipTier.vipMax,
      );
    });

    test('inactive, missing, and unknown memberships are regular', () {
      expect(
        DownloadMembershipTier.fromVip(null),
        DownloadMembershipTier.regular,
      );
      expect(
        DownloadMembershipTier.fromVip(_vip(active: false, tier: 'vip3')),
        DownloadMembershipTier.regular,
      );
      expect(
        DownloadMembershipTier.fromVip(_vip(active: true, tier: 'gold')),
        DownloadMembershipTier.regular,
      );
    });
  });

  group('DownloadEntitlementPolicy', () {
    const policy = DownloadEntitlementPolicy();

    test('subtracts completed and reserved chapters from the same day', () {
      final now = DateTime(2026, 7, 20, 12);

      final result = policy.evaluate(
        now: now,
        highestLocalDayOrdinal: now.dayOrdinal,
        completed: 60,
        reserved: 2,
        rewardedCredits: 20,
        completedAds: 1,
        tier: DownloadMembershipTier.regular,
      );

      expect(result.shouldReset, isFalse);
      expect(result.effectiveDayOrdinal, now.dayOrdinal);
      expect(result.remaining, 58);
      expect(result.adsRemaining, 3);
      expect(result.canDownload, isTrue);
      expect(result.canWatchRewardedAd, isFalse);
    });

    test('a later local date resets all daily counters', () {
      final yesterday = DateTime(2026, 7, 19);
      final now = DateTime(2026, 7, 20, 0, 1);

      final result = policy.evaluate(
        now: now,
        highestLocalDayOrdinal: yesterday.dayOrdinal,
        completed: 100,
        reserved: 4,
        rewardedCredits: 80,
        completedAds: 4,
        tier: DownloadMembershipTier.regular,
      );

      expect(result.shouldReset, isTrue);
      expect(result.effectiveDayOrdinal, now.dayOrdinal);
      expect(result.remaining, 100);
      expect(result.adsRemaining, 4);
    });

    test('clock rollback never creates a new day', () {
      final highestDay = DateTime(2026, 7, 20).dayOrdinal;

      final result = policy.evaluate(
        now: DateTime(2026, 7, 19, 23),
        highestLocalDayOrdinal: highestDay,
        completed: 100,
        reserved: 0,
        rewardedCredits: 0,
        completedAds: 0,
        tier: DownloadMembershipTier.regular,
      );

      expect(result.shouldReset, isFalse);
      expect(result.effectiveDayOrdinal, highestDay);
      expect(result.remaining, 0);
      expect(result.canWatchRewardedAd, isTrue);
    });

    test('same-day upgrade adds only the base-plan difference', () {
      final now = DateTime(2026, 7, 20);

      final result = policy.evaluate(
        now: now,
        highestLocalDayOrdinal: now.dayOrdinal,
        completed: 100,
        reserved: 0,
        rewardedCredits: 20,
        completedAds: 1,
        tier: DownloadMembershipTier.vip1,
      );

      expect(result.remaining, 120);
      expect(result.adsRemaining, 4);
    });

    test('same-day downgrade clamps the balance to zero', () {
      final now = DateTime(2026, 7, 20);

      final result = policy.evaluate(
        now: now,
        highestLocalDayOrdinal: now.dayOrdinal,
        completed: 250,
        reserved: 3,
        rewardedCredits: 40,
        completedAds: 1,
        tier: DownloadMembershipTier.regular,
      );

      expect(result.remaining, 0);
      expect(result.adsRemaining, 3);
    });
  });
}

AuthVip _vip({required bool active, required String tier}) {
  return AuthVip(active: active, tier: tier, label: tier, expiresAt: null);
}
