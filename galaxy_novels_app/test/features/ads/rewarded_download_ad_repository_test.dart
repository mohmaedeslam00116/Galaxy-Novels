import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/features/ads/application/rewarded_download_ad_repository.dart';

void main() {
  test('noop repository exposes unavailable lifecycle safely', () async {
    const repository = NoopRewardedDownloadAdRepository();

    expect(repository.availability, RewardedDownloadAdAvailability.unavailable);
    await repository.preload();
    expect(repository.availability, RewardedDownloadAdAvailability.unavailable);
    expect(
      (await repository.show()).status,
      RewardedDownloadAdStatus.unavailable,
    );
    repository.dispose();
  });
}
