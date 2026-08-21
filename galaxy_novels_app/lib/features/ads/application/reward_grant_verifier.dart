import 'package:flutter/foundation.dart';

const downloadChaptersRewardType = 'download_chapters_v1';

@immutable
class RewardGrantClaim {
  const RewardGrantClaim({
    required this.rewardEventId,
    required this.rewardType,
  });

  final String rewardEventId;
  final String rewardType;
}

abstract interface class RewardGrantVerifier {
  Future<bool> verify(RewardGrantClaim claim);
}

class LocalRewardGrantVerifier implements RewardGrantVerifier {
  const LocalRewardGrantVerifier();

  @override
  Future<bool> verify(RewardGrantClaim claim) async {
    return claim.rewardEventId.trim().isNotEmpty &&
        claim.rewardType == downloadChaptersRewardType;
  }
}
