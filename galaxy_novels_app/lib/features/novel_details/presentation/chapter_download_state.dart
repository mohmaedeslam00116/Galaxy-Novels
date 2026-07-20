import '../../downloads/domain/download_models.dart';

enum ChapterDownloadStatus { available, pending, downloaded, failed }

class ChapterDownloadState {
  const ChapterDownloadState(this.status, {this.retryJobId});

  static const available = ChapterDownloadState(
    ChapterDownloadStatus.available,
  );
  static const pending = ChapterDownloadState(ChapterDownloadStatus.pending);
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
      if (_isPending(job.status)) return ChapterDownloadState.pending;
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

bool _isPending(DownloadJobStatus status) => switch (status) {
  DownloadJobStatus.queued ||
  DownloadJobStatus.reserved ||
  DownloadJobStatus.transferring ||
  DownloadJobStatus.processing ||
  DownloadJobStatus.paused => true,
  DownloadJobStatus.completed ||
  DownloadJobStatus.failed ||
  DownloadJobStatus.canceled => false,
};
