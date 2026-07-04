import 'package:flutter/foundation.dart';

class ReaderRewardsState {
  const ReaderRewardsState({
    this.points = 0,
    this.rewardedAdsWatchedToday = 0,
    this.rewardedAdsDayKey = '',
  });

  static const rewardedAdPoints = 25;
  static const maxRewardedAdsPerDay = 6;
  static const pointsPerChapterDownload = 1;

  final int points;
  final int rewardedAdsWatchedToday;
  final String rewardedAdsDayKey;

  int get clampedRewardedAdsWatchedToday {
    if (rewardedAdsWatchedToday < 0) {
      return 0;
    }
    if (rewardedAdsWatchedToday > maxRewardedAdsPerDay) {
      return maxRewardedAdsPerDay;
    }
    return rewardedAdsWatchedToday;
  }

  int get remainingRewardedAdsToday {
    final remaining = maxRewardedAdsPerDay - clampedRewardedAdsWatchedToday;
    return remaining < 0 ? 0 : remaining;
  }

  bool get canWatchRewardedAd => remainingRewardedAdsToday > 0;

  double get rewardedAdsProgress {
    return clampedRewardedAdsWatchedToday / maxRewardedAdsPerDay;
  }

  bool canSpend(int chapterCount) {
    return chapterCount <= 0 ||
        points >= chapterCount * pointsPerChapterDownload;
  }

  ReaderRewardsState copyWith({
    int? points,
    int? rewardedAdsWatchedToday,
    String? rewardedAdsDayKey,
  }) {
    return ReaderRewardsState(
      points: points ?? this.points,
      rewardedAdsWatchedToday:
          rewardedAdsWatchedToday ?? this.rewardedAdsWatchedToday,
      rewardedAdsDayKey: rewardedAdsDayKey ?? this.rewardedAdsDayKey,
    );
  }
}

class RewardedAdDailyLimitException implements Exception {
  const RewardedAdDailyLimitException();

  @override
  String toString() => 'RewardedAdDailyLimitException';
}

class InsufficientDownloadPointsException implements Exception {
  const InsufficientDownloadPointsException({
    required this.requiredPoints,
    required this.availablePoints,
  });

  final int requiredPoints;
  final int availablePoints;

  @override
  String toString() {
    return 'InsufficientDownloadPointsException: required $requiredPoints, '
        'available $availablePoints';
  }
}

abstract class ReaderRewardsRepository {
  const ReaderRewardsRepository();

  ValueListenable<ReaderRewardsState> get state;

  Future<void> load();

  void grantRewardedAdPoints();

  void spendForDownload(int chapterCount);

  void refundDownloadPoints(int chapterCount);
}

class NoopReaderRewardsRepository implements ReaderRewardsRepository {
  const NoopReaderRewardsRepository();

  static const _state = ReaderRewardsState();
  static final ValueNotifier<ReaderRewardsState> _notifier = ValueNotifier(
    _state,
  );

  @override
  ValueListenable<ReaderRewardsState> get state => _notifier;

  @override
  Future<void> load() async {}

  @override
  void grantRewardedAdPoints() {}

  @override
  void spendForDownload(int chapterCount) {}

  @override
  void refundDownloadPoints(int chapterCount) {}
}
