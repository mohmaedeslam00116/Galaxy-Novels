import '../../downloads/domain/download_models.dart';

enum ChapterDownloadStatus {
  available,
  queued,
  downloading,
  paused,
  downloaded,
  failed,
}

class ChapterDownloadState {
  const ChapterDownloadState(this.status, {this.retryJobId});

  static const available = ChapterDownloadState(
    ChapterDownloadStatus.available,
  );
  static const queued = ChapterDownloadState(ChapterDownloadStatus.queued);
  static const downloading = ChapterDownloadState(
    ChapterDownloadStatus.downloading,
  );
  static const paused = ChapterDownloadState(ChapterDownloadStatus.paused);
  static const downloaded = ChapterDownloadState(
    ChapterDownloadStatus.downloaded,
  );

  final ChapterDownloadStatus status;
  final String? retryJobId;
}

ChapterDownloadState resolveChapterDownloadState(
  DownloadsDashboard dashboard,
  String chapterKey,
) {
  for (final novel in dashboard.novels) {
    if (novel.chapters.any((chapter) => chapter.chapterKey == chapterKey)) {
      return ChapterDownloadState.downloaded;
    }
  }

  String? failedJobId;
  for (final group in dashboard.groups) {
    for (final job in group.jobs) {
      if (job.chapterKey != chapterKey) continue;
      final activeState = _activeDownloadState(job.status);
      if (activeState != null) return activeState;
      if (job.status == DownloadJobStatus.failed) failedJobId = job.jobId;
    }
  }
  return failedJobId == null
      ? ChapterDownloadState.available
      : ChapterDownloadState(
          ChapterDownloadStatus.failed,
          retryJobId: failedJobId,
        );
}

ChapterDownloadState? _activeDownloadState(DownloadJobStatus status) =>
    switch (status) {
      DownloadJobStatus.queued ||
      DownloadJobStatus.reserved => ChapterDownloadState.queued,
      DownloadJobStatus.transferring ||
      DownloadJobStatus.processing => ChapterDownloadState.downloading,
      DownloadJobStatus.paused => ChapterDownloadState.paused,
      DownloadJobStatus.completed ||
      DownloadJobStatus.failed ||
      DownloadJobStatus.canceled => null,
    };
