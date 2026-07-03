import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/features/rewards/data/stored_reader_rewards_repository.dart';

void main() {
  test('grants 25 points for each rewarded video up to 6 per day', () {
    final repository = StoredReaderRewardsRepository.memory(
      now: () => DateTime(2026, 7, 3, 12),
    );

    for (var i = 0; i < 6; i++) {
      repository.grantRewardedAdPoints();
    }

    expect(repository.state.value.points, 150);
    expect(repository.state.value.rewardedAdsWatchedToday, 6);
    expect(repository.state.value.remainingRewardedAdsToday, 0);
    expect(
      repository.grantRewardedAdPoints,
      throwsA(isA<RewardedAdDailyLimitException>()),
    );
  });

  test('resets the rewarded video daily counter on the next local day', () {
    var now = DateTime(2026, 7, 3, 12);
    final repository = StoredReaderRewardsRepository.memory(now: () => now);

    repository.grantRewardedAdPoints();
    now = DateTime(2026, 7, 4, 8);
    repository.grantRewardedAdPoints();

    expect(repository.state.value.points, 50);
    expect(repository.state.value.rewardedAdsWatchedToday, 1);
    expect(repository.state.value.remainingRewardedAdsToday, 5);
  });

  test('spends one point per downloaded chapter and refunds failed chapters', () {
    final repository = StoredReaderRewardsRepository.memory(
      initialPoints: 30,
      now: () => DateTime(2026, 7, 3, 12),
    );

    repository.spendForDownload(12);
    repository.refundDownloadPoints(2);

    expect(repository.state.value.points, 20);
  });

  test('throws when download points are insufficient', () {
    final repository = StoredReaderRewardsRepository.memory(
      initialPoints: 2,
      now: () => DateTime(2026, 7, 3, 12),
    );

    expect(
      () => repository.spendForDownload(3),
      throwsA(isA<InsufficientDownloadPointsException>()),
    );
    expect(repository.state.value.points, 2);
  });
}
