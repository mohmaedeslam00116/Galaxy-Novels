import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/features/ads/application/reward_grant_verifier.dart';

void main() {
  test(
    'local verifier accepts only the fixed download reward identity',
    () async {
      const verifier = LocalRewardGrantVerifier();

      expect(
        await verifier.verify(
          const RewardGrantClaim(
            rewardEventId: 'event-1',
            rewardType: downloadChaptersRewardType,
          ),
        ),
        isTrue,
      );
      expect(
        await verifier.verify(
          const RewardGrantClaim(
            rewardEventId: 'event-1',
            rewardType: 'unexpected_reward',
          ),
        ),
        isFalse,
      );
    },
  );
}
