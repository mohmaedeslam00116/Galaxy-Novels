enum RewardedAdOutcome { earnedReward, unavailable, dismissed, failed }

abstract class RewardedAdRepository {
  const RewardedAdRepository();

  Future<void> initialize();

  Future<RewardedAdOutcome> showRewardedAd();
}

class NoopRewardedAdRepository implements RewardedAdRepository {
  const NoopRewardedAdRepository();

  @override
  Future<void> initialize() async {}

  @override
  Future<RewardedAdOutcome> showRewardedAd() async {
    return RewardedAdOutcome.unavailable;
  }
}
