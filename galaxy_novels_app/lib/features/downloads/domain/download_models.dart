import 'download_entitlement.dart';

enum DownloadJobStatus {
  queued,
  reserved,
  transferring,
  processing,
  paused,
  completed,
  failed,
  canceled,
}

enum DownloadGroupStatus {
  queued,
  running,
  paused,
  waitingForQuota,
  waitingForWifi,
  waitingForNetwork,
  storageFull,
  completed,
  canceled,
}

enum DownloadFailure {
  network,
  wifiRequired,
  storageFull,
  unauthorized,
  vipRequired,
  invalidContent,
  canceled,
  unknown,
}

class DownloadChapterRequest {
  const DownloadChapterRequest({
    required this.chapterKey,
    required this.chapterId,
    required this.label,
    required this.contentApi,
    required this.isVip,
  });

  final String chapterKey;
  final int chapterId;
  final String label;
  final String contentApi;
  final bool isVip;
}

class DownloadNovelRequest {
  const DownloadNovelRequest({
    required this.novelId,
    required this.title,
    required this.coverUrl,
  });

  final int novelId;
  final String title;
  final String coverUrl;
}

class DownloadJob {
  const DownloadJob({
    required this.jobId,
    required this.groupId,
    required this.chapterKey,
    required this.chapterId,
    required this.label,
    required this.contentApi,
    required this.isVip,
    required this.status,
    required this.sortIndex,
    required this.reservedDayOrdinal,
    required this.transferTaskId,
    required this.tempPath,
    required this.attempts,
    required this.lastError,
  });

  final String jobId;
  final String groupId;
  final String chapterKey;
  final int chapterId;
  final String label;
  final String contentApi;
  final bool isVip;
  final DownloadJobStatus status;
  final int sortIndex;
  final int? reservedDayOrdinal;
  final String? transferTaskId;
  final String? tempPath;
  final int attempts;
  final DownloadFailure? lastError;
}

class DownloadGroup {
  const DownloadGroup({
    required this.groupId,
    required this.novelId,
    required this.status,
    required this.stopReason,
    required this.createdAtUtcMs,
    required this.updatedAtUtcMs,
    required this.jobs,
  });

  final String groupId;
  final int novelId;
  final DownloadGroupStatus status;
  final DownloadFailure? stopReason;
  final int createdAtUtcMs;
  final int updatedAtUtcMs;
  final List<DownloadJob> jobs;
}

class DownloadedChapter {
  const DownloadedChapter({
    required this.chapterKey,
    required this.novelId,
    required this.chapterId,
    required this.label,
    required this.contentApi,
    required this.isVip,
    required this.filePath,
    required this.byteSize,
    required this.downloadedAtUtcMs,
    required this.vipVerifiedAtUtcMs,
    required this.vipExpiresAtUtcMs,
  });

  final String chapterKey;
  final int novelId;
  final int chapterId;
  final String label;
  final String contentApi;
  final bool isVip;
  final String filePath;
  final int byteSize;
  final int downloadedAtUtcMs;
  final int? vipVerifiedAtUtcMs;
  final int? vipExpiresAtUtcMs;
}

class DownloadedNovel {
  const DownloadedNovel({
    required this.novelId,
    required this.title,
    required this.coverUrl,
    required this.coverPath,
    required this.totalBytes,
    required this.chapters,
  });

  final int novelId;
  final String title;
  final String coverUrl;
  final String coverPath;
  final int totalBytes;
  final List<DownloadedChapter> chapters;
}

class DownloadReservation {
  const DownloadReservation({
    required this.jobId,
    required this.groupId,
    required this.novelId,
    required this.chapterKey,
    required this.chapterId,
    required this.label,
    required this.contentApi,
    required this.isVip,
    required this.reservedDayOrdinal,
  });

  final String jobId;
  final String groupId;
  final int novelId;
  final String chapterKey;
  final int chapterId;
  final String label;
  final String contentApi;
  final bool isVip;
  final int reservedDayOrdinal;
}

class DownloadEnqueueResult {
  const DownloadEnqueueResult({
    required this.groupId,
    required this.acceptedChapterKeys,
    required this.skippedChapterKeys,
  });

  final String? groupId;
  final List<String> acceptedChapterKeys;
  final List<String> skippedChapterKeys;
}

class DownloadMembershipSnapshot {
  const DownloadMembershipSnapshot({
    required this.userId,
    required this.active,
    required this.tier,
    required this.verifiedAtUtcMs,
    required this.expiresAtUtcMs,
  });

  const DownloadMembershipSnapshot.regular()
    : userId = null,
      active = false,
      tier = DownloadMembershipTier.regular,
      verifiedAtUtcMs = 0,
      expiresAtUtcMs = null;

  final int? userId;
  final bool active;
  final DownloadMembershipTier tier;
  final int verifiedAtUtcMs;
  final int? expiresAtUtcMs;
}

class DownloadStoreSnapshot {
  const DownloadStoreSnapshot({
    required this.groups,
    required this.novels,
    required this.membership,
    required this.completedToday,
    required this.reservedCount,
    required this.rewardedCredits,
    required this.completedAds,
    required this.highestSeenDayOrdinal,
    required this.wifiOnly,
    required this.totalBytes,
  });

  final List<DownloadGroup> groups;
  final List<DownloadedNovel> novels;
  final DownloadMembershipSnapshot membership;
  final int completedToday;
  final int reservedCount;
  final int rewardedCredits;
  final int completedAds;
  final int highestSeenDayOrdinal;
  final bool wifiOnly;
  final int totalBytes;
}

class DownloadsDashboard {
  const DownloadsDashboard({
    required this.allowance,
    required this.groups,
    required this.novels,
    required this.wifiOnly,
    required this.totalBytes,
    required this.quotaBlockGeneration,
    required this.isInitializing,
  });

  final DownloadAllowance allowance;
  final List<DownloadGroup> groups;
  final List<DownloadedNovel> novels;
  final bool wifiOnly;
  final int totalBytes;
  final int quotaBlockGeneration;
  final bool isInitializing;
}
