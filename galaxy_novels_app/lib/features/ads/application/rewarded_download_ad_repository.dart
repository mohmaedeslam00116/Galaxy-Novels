import 'package:flutter/foundation.dart';

enum RewardedDownloadAdStatus { earned, dismissed, unavailable, busy }

enum RewardedDownloadAdAvailability {
  idle,
  loading,
  ready,
  showing,
  unavailable,
}

class RewardedDownloadAdResult {
  const RewardedDownloadAdResult(this.status, {this.rewardEventId});

  final RewardedDownloadAdStatus status;
  final String? rewardEventId;
}

abstract interface class RewardedDownloadAdRepository
    implements ValueListenable<RewardedDownloadAdAvailability> {
  RewardedDownloadAdAvailability get availability;
  Future<void> preload();
  Future<RewardedDownloadAdResult> show();
  void dispose();
}

class NoopRewardedDownloadAdRepository implements RewardedDownloadAdRepository {
  const NoopRewardedDownloadAdRepository();

  @override
  RewardedDownloadAdAvailability get availability =>
      RewardedDownloadAdAvailability.unavailable;

  @override
  RewardedDownloadAdAvailability get value => availability;

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}

  @override
  Future<void> preload() async {}

  @override
  Future<RewardedDownloadAdResult> show() async {
    return const RewardedDownloadAdResult(RewardedDownloadAdStatus.unavailable);
  }

  @override
  void dispose() {}
}
