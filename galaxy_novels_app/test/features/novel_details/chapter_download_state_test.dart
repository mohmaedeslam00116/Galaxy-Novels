import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/features/downloads/application/download_repository.dart';
import 'package:galaxy_novels_app/features/downloads/domain/download_models.dart';
import 'package:galaxy_novels_app/features/novel_details/presentation/chapter_download_state.dart';

void main() {
  test('downloaded chapter wins over historical jobs', () {
    final state = resolveChapterDownloadState(
      _dashboardWith(downloaded: true, jobStatus: DownloadJobStatus.failed),
      'public:71',
    );

    expect(state.status, ChapterDownloadStatus.downloaded);
    expect(state.retryJobId, isNull);
  });

  test('active jobs are pending', () {
    for (final status in [
      DownloadJobStatus.queued,
      DownloadJobStatus.reserved,
      DownloadJobStatus.transferring,
      DownloadJobStatus.processing,
      DownloadJobStatus.paused,
    ]) {
      expect(
        resolveChapterDownloadState(
          _dashboardWith(jobStatus: status),
          'public:71',
        ).status,
        ChapterDownloadStatus.pending,
        reason: '$status should remain visibly pending',
      );
    }
  });

  test('failed job exposes its retry id', () {
    final state = resolveChapterDownloadState(
      _dashboardWith(jobStatus: DownloadJobStatus.failed),
      'public:71',
    );

    expect(state.status, ChapterDownloadStatus.failed);
    expect(state.retryJobId, 'job-71');
  });

  test('canceled and unrelated jobs leave the chapter available', () {
    expect(
      resolveChapterDownloadState(
        _dashboardWith(jobStatus: DownloadJobStatus.canceled),
        'public:71',
      ).status,
      ChapterDownloadStatus.available,
    );
    expect(
      resolveChapterDownloadState(
        _dashboardWith(jobStatus: DownloadJobStatus.transferring),
        'public:72',
      ).status,
      ChapterDownloadStatus.available,
    );
  });
}

DownloadsDashboard _dashboardWith({
  bool downloaded = false,
  DownloadJobStatus? jobStatus,
}) {
  return DownloadsDashboard(
    allowance: NoopDownloadRepository.emptyDashboard.allowance,
    groups: jobStatus == null
        ? const []
        : [
            DownloadGroup(
              groupId: 'group-71',
              novelId: 7,
              status: DownloadGroupStatus.running,
              stopReason: null,
              createdAtUtcMs: 1,
              updatedAtUtcMs: 2,
              jobs: [
                DownloadJob(
                  jobId: 'job-71',
                  groupId: 'group-71',
                  chapterKey: 'public:71',
                  chapterId: 71,
                  label: 'الفصل 71',
                  contentApi: '/chapter/71',
                  isVip: false,
                  status: jobStatus,
                  sortIndex: 0,
                  reservedDayOrdinal: null,
                  transferTaskId: null,
                  tempPath: null,
                  attempts: 0,
                  lastError: jobStatus == DownloadJobStatus.failed
                      ? DownloadFailure.network
                      : null,
                ),
              ],
            ),
          ],
    novels: downloaded
        ? const [
            DownloadedNovel(
              novelId: 7,
              title: 'رواية الاختبار',
              coverUrl: '',
              coverPath: '',
              totalBytes: 120,
              chapters: [
                DownloadedChapter(
                  chapterKey: 'public:71',
                  novelId: 7,
                  chapterId: 71,
                  label: 'الفصل 71',
                  contentApi: '/chapter/71',
                  isVip: false,
                  filePath: '/downloads/71.gnchapter',
                  byteSize: 120,
                  downloadedAtUtcMs: 3,
                  vipVerifiedAtUtcMs: null,
                  vipExpiresAtUtcMs: null,
                ),
              ],
            ),
          ]
        : const [],
    wifiOnly: false,
    totalBytes: downloaded ? 120 : 0,
    quotaBlockGeneration: 0,
    isInitializing: false,
  );
}
