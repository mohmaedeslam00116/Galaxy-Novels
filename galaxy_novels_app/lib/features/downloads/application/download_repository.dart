import 'package:flutter/foundation.dart';

import '../../../core/crash_reporting/app_recoverable_exception.dart';
import '../../../data/models/reader_content_data.dart';
import '../../account/domain/auth_session.dart';
import '../domain/download_entitlement.dart';
import '../domain/download_models.dart';

abstract interface class DownloadRepository
    implements ValueListenable<DownloadsDashboard> {
  Future<void> initialize();
  Future<DownloadEnqueueResult> enqueue({
    required DownloadNovelRequest novel,
    required List<DownloadChapterRequest> chapters,
  });
  Future<void> pauseGroup(String groupId);
  Future<void> resumeGroup(String groupId);
  Future<void> cancelGroup(String groupId);
  Future<void> retryJob(String jobId);
  Future<void> grantReward({required String rewardEventId});
  Future<void> setWifiOnly(bool enabled);
  Future<void> deleteChapters(Set<String> chapterKeys);
  Future<ReaderChapterContent> loadOffline(String offlineUri);
  Future<void> refreshMembership(AuthSessionState state);
  void dispose();
}

enum DownloadVipLockReason { signedOut, expired, verificationRequired }

class DownloadVipLockedException implements Exception {
  const DownloadVipLockedException(this.reason);
  final DownloadVipLockReason reason;
}

class DownloadUnavailableException implements AppRecoverableException {
  const DownloadUnavailableException();
}

class NoopDownloadRepository implements DownloadRepository {
  const NoopDownloadRepository();

  static const emptyDashboard = DownloadsDashboard(
    allowance: DownloadAllowance(
      plan: DownloadPlan(baseChapters: 100, maxRewardedAds: 4, rewardPerAd: 20),
      remaining: 100,
      adsRemaining: 4,
      shouldReset: false,
      effectiveDayOrdinal: 0,
    ),
    groups: [],
    novels: [],
    wifiOnly: false,
    totalBytes: 0,
    quotaBlockGeneration: 0,
    isInitializing: false,
  );

  @override
  DownloadsDashboard get value => emptyDashboard;
  @override
  void addListener(VoidCallback listener) {}
  @override
  void removeListener(VoidCallback listener) {}
  @override
  Future<void> initialize() async {}
  @override
  Future<DownloadEnqueueResult> enqueue({
    required DownloadNovelRequest novel,
    required List<DownloadChapterRequest> chapters,
  }) async => DownloadEnqueueResult(
    groupId: null,
    acceptedChapterKeys: const [],
    skippedChapterKeys: chapters
        .map((chapter) => chapter.chapterKey)
        .toList(growable: false),
  );
  @override
  Future<void> pauseGroup(String groupId) async {}
  @override
  Future<void> resumeGroup(String groupId) async {}
  @override
  Future<void> cancelGroup(String groupId) async {}
  @override
  Future<void> retryJob(String jobId) async {}
  @override
  Future<void> grantReward({required String rewardEventId}) async {}
  @override
  Future<void> setWifiOnly(bool enabled) async {}
  @override
  Future<void> deleteChapters(Set<String> chapterKeys) async {}
  @override
  Future<ReaderChapterContent> loadOffline(String offlineUri) {
    throw StateError('Offline downloads are not configured.');
  }

  @override
  Future<void> refreshMembership(AuthSessionState state) async {}
  @override
  void dispose() {}
}

class UnavailableDownloadRepository implements DownloadRepository {
  const UnavailableDownloadRepository({this.isInitializing = false});

  final bool isInitializing;

  @override
  DownloadsDashboard get value {
    const empty = NoopDownloadRepository.emptyDashboard;
    return DownloadsDashboard(
      allowance: empty.allowance,
      groups: empty.groups,
      novels: empty.novels,
      wifiOnly: empty.wifiOnly,
      totalBytes: empty.totalBytes,
      quotaBlockGeneration: empty.quotaBlockGeneration,
      isInitializing: isInitializing,
    );
  }

  @override
  Future<DownloadEnqueueResult> enqueue({
    required DownloadNovelRequest novel,
    required List<DownloadChapterRequest> chapters,
  }) async {
    throw const DownloadUnavailableException();
  }

  @override
  void addListener(VoidCallback listener) {}
  @override
  void removeListener(VoidCallback listener) {}
  @override
  Future<void> initialize() async {}
  @override
  Future<void> pauseGroup(String groupId) async {}
  @override
  Future<void> resumeGroup(String groupId) async {}
  @override
  Future<void> cancelGroup(String groupId) async {}
  @override
  Future<void> retryJob(String jobId) async {}
  @override
  Future<void> grantReward({required String rewardEventId}) async {}
  @override
  Future<void> setWifiOnly(bool enabled) async {}
  @override
  Future<void> deleteChapters(Set<String> chapterKeys) async {}
  @override
  Future<ReaderChapterContent> loadOffline(String offlineUri) async {
    throw const DownloadUnavailableException();
  }

  @override
  Future<void> refreshMembership(AuthSessionState state) async {}
  @override
  void dispose() {}
}
