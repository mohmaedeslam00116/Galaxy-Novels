import '../domain/download_entitlement.dart';
import '../domain/download_models.dart';

abstract interface class DownloadStore {
  Future<DownloadEnqueueResult> enqueue({
    required DownloadNovelRequest novel,
    required List<DownloadChapterRequest> chapters,
  });

  Future<DownloadReservation?> reserveNext({
    required DownloadPlan plan,
    required DateTime now,
  });

  Future<void> complete(
    String jobId, {
    required String filePath,
    required int byteSize,
    required int downloadedAtUtcMs,
    int? vipVerifiedAtUtcMs,
    int? vipExpiresAtUtcMs,
  });

  Future<void> release(String jobId, {required DownloadFailure reason});

  Future<DownloadStoreSnapshot> grantReward({
    required String rewardEventId,
    required DownloadPlan plan,
    required DateTime now,
  });

  Future<DownloadStoreSnapshot> snapshot();
  Future<void> saveMembership(DownloadMembershipSnapshot membership);
  Future<void> updateCoverPath(int novelId, String coverPath);
  Future<void> setWifiOnly(bool value);
  Future<void> deleteChapters(Set<String> chapterKeys);
  Future<void> close();
}
