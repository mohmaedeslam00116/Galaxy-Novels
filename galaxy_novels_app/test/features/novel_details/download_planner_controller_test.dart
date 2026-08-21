import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/data/models/novel_details_data.dart';
import 'package:galaxy_novels_app/features/downloads/application/download_repository.dart';
import 'package:galaxy_novels_app/features/downloads/application/download_analytics.dart';
import 'package:galaxy_novels_app/features/downloads/domain/download_entitlement.dart';
import 'package:galaxy_novels_app/features/downloads/domain/download_models.dart';
import 'package:galaxy_novels_app/features/novel_details/application/download_planner_controller.dart';
import 'package:galaxy_novels_app/features/novel_details/domain/readable_chapter.dart';

void main() {
  group('DownloadPlannerController', () {
    test('selects twenty five eligible chapters after reading position', () {
      final controller = DownloadPlannerController(
        chapters: _chapters(60),
        dashboard: _dashboard(
          downloadedKeys: {'public:12', 'public:14'},
          queuedKeys: {'public:13'},
        ),
        readingChapterPosition: 10,
      );

      final preview = controller.preview;

      expect(preview.chapters, hasLength(25));
      expect(preview.chapters.first.sortPosition, 11);
      expect(preview.chapters.last.sortPosition, 38);
      expect(preview.skippedDownloaded, 2);
      expect(preview.skippedQueued, 1);
    });

    test('starts from first eligible chapter when history is absent', () {
      final controller = DownloadPlannerController(
        chapters: _chapters(30),
        dashboard: _dashboard(downloadedKeys: {'public:1', 'public:2'}),
      );

      expect(controller.preview.chapters.first.sortPosition, 3);
      expect(controller.preview.chapters, hasLength(25));
    });

    test('range preview excludes existing work and keeps exact boundaries', () {
      final controller = DownloadPlannerController(
        chapters: _chapters(30),
        dashboard: _dashboard(
          downloadedKeys: {'public:12'},
          queuedKeys: {'public:15'},
        ),
      );

      controller.selectRange(start: 10, end: 16);

      expect(
        controller.preview.chapters.map((chapter) => chapter.sortPosition),
        [10, 11, 13, 14, 16],
      );
      expect(controller.preview.skippedDownloaded, 1);
      expect(controller.preview.skippedQueued, 1);
    });

    test('forecasts immediate reward and deferred chapters', () {
      final controller = DownloadPlannerController(
        chapters: _chapters(200),
        dashboard: _dashboard(remaining: 18, adsRemaining: 2),
      );

      controller.selectNext(100);

      expect(controller.preview.availableNow, 18);
      expect(controller.preview.availableThroughRewards, 40);
      expect(controller.preview.rewardAdsNeeded, 2);
      expect(controller.preview.deferredUntilReset, 42);
    });

    test('manual selection is normalized into chapter order', () {
      final controller = DownloadPlannerController(
        chapters: _chapters(20),
        dashboard: _dashboard(),
      );

      controller.selectManual({'public:9', 'public:3', 'public:7'});

      expect(
        controller.preview.chapters.map((chapter) => chapter.sortPosition),
        [3, 7, 9],
      );
    });

    test('manual selection can include chapters loaded by the picker', () {
      final controller = DownloadPlannerController(
        chapters: _chapters(20),
        dashboard: _dashboard(),
      );

      controller.includeAccessibleChapters(_chapters(30).skip(20).toList());
      controller.selectManual({'public:24', 'public:29'});

      expect(
        controller.preview.chapters.map((chapter) => chapter.sortPosition),
        [24, 29],
      );
    });

    test('all selection uses newly supplied accessible catalog', () {
      final controller = DownloadPlannerController(
        chapters: _chapters(50),
        dashboard: _dashboard(),
      );

      controller.replaceAccessibleChapters(_chapters(120));
      controller.selectAll();

      expect(controller.preview.chapters, hasLength(120));
    });

    test(
      'incomplete all-chapters load keeps confirmed catalog and error',
      () async {
        final controller = DownloadPlannerController(
          chapters: _chapters(50),
          dashboard: _dashboard(),
        );

        await controller.loadAllChapters(
          () async => DownloadPlannerCatalogResult(
            chapters: _chapters(70),
            complete: false,
            errorMessage: 'تعذر تحميل بقية الفصول',
          ),
        );

        expect(controller.mode, DownloadPlannerSelectionMode.all);
        expect(controller.preview.chapters, hasLength(70));
        expect(controller.catalogError, 'تعذر تحميل بقية الفصول');
        expect(controller.isLoadingCatalog, isFalse);
      },
    );

    test('successful submission exposes accepted and skipped counts', () async {
      final controller = DownloadPlannerController(
        chapters: _chapters(30),
        dashboard: _dashboard(),
      );

      await controller.submit(
        (chapters) async => DownloadEnqueueResult(
          groupId: 'group-1',
          acceptedChapterKeys: chapters
              .take(20)
              .map((chapter) => 'public:${chapter.id}')
              .toList(),
          skippedChapterKeys: chapters
              .skip(20)
              .map((chapter) => 'public:${chapter.id}')
              .toList(),
        ),
      );

      expect(controller.submission?.acceptedChapterKeys, hasLength(20));
      expect(controller.submission?.skippedChapterKeys, hasLength(5));
      expect(controller.submitError, isNull);
      expect(controller.isSubmitting, isFalse);
    });

    test('submission failure keeps the current draft for retry', () async {
      final controller = DownloadPlannerController(
        chapters: _chapters(30),
        dashboard: _dashboard(),
      );

      await controller.submit(
        (_) => throw const DownloadUnavailableException(),
      );

      expect(controller.preview.chapters, hasLength(25));
      expect(controller.submission, isNull);
      expect(controller.submitError, isNotEmpty);
      expect(controller.isSubmitting, isFalse);
    });

    test('records aggregate planner and queue events', () async {
      final analytics = _RecordingDownloadAnalytics();
      final controller = DownloadPlannerController(
        chapters: _chapters(30),
        dashboard: _dashboard(remaining: 18),
        analytics: analytics,
      );

      controller.selectNext(25);
      await controller.submit(
        (chapters) async => DownloadEnqueueResult(
          groupId: 'private-group-id',
          acceptedChapterKeys: chapters
              .map((chapter) => 'public:${chapter.id}')
              .toList(),
          skippedChapterKeys: const [],
        ),
      );

      expect(
        analytics.events.map((event) => event.name),
        containsAll([
          'download_planner_opened',
          'download_selection_changed',
          'download_plan_confirmed',
          'download_group_started',
        ]),
      );
      expect(
        analytics.events.expand((event) => event.parameters.values),
        isNot(contains('private-group-id')),
      );
    });
  });
}

class _RecordingDownloadAnalytics implements DownloadAnalytics {
  final events = <DownloadAnalyticsEvent>[];

  @override
  Future<void> record(DownloadAnalyticsEvent event) async => events.add(event);
}

List<ReadableChapter> _chapters(int count) => List.generate(
  count,
  (index) => ReadableChapter.public(
    NovelChapter(
      id: index + 1,
      position: index + 1,
      number: '${index + 1}',
      label: 'الفصل ${index + 1}',
      title: '',
      url: '',
      contentApi: '/chapters/${index + 1}',
      dateLabel: '',
      dateIso: null,
      views: 0,
      comments: 0,
      search: '',
    ),
  ),
);

DownloadsDashboard _dashboard({
  Set<String> downloadedKeys = const {},
  Set<String> queuedKeys = const {},
  int remaining = 100,
  int adsRemaining = 4,
}) {
  return DownloadsDashboard(
    allowance: DownloadAllowance(
      plan: const DownloadPlan(
        baseChapters: 100,
        maxRewardedAds: 4,
        rewardPerAd: 20,
      ),
      remaining: remaining,
      adsRemaining: adsRemaining,
      shouldReset: false,
      effectiveDayOrdinal: 1,
    ),
    groups: queuedKeys.isEmpty
        ? const []
        : [
            DownloadGroup(
              groupId: 'queued-group',
              novelId: 500,
              status: DownloadGroupStatus.running,
              stopReason: null,
              createdAtUtcMs: 1,
              updatedAtUtcMs: 1,
              jobs: queuedKeys
                  .map(
                    (key) => DownloadJob(
                      jobId: 'job-$key',
                      groupId: 'queued-group',
                      chapterKey: key,
                      chapterId: int.parse(key.split(':').last),
                      label: key,
                      contentApi: '/$key',
                      isVip: false,
                      status: DownloadJobStatus.queued,
                      sortIndex: 0,
                      reservedDayOrdinal: null,
                      transferTaskId: null,
                      tempPath: null,
                      attempts: 0,
                      lastError: null,
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
    novels: downloadedKeys.isEmpty
        ? const []
        : [
            DownloadedNovel(
              novelId: 500,
              title: 'رواية',
              coverUrl: '',
              coverPath: '',
              totalBytes: 0,
              chapters: downloadedKeys
                  .map(
                    (key) => DownloadedChapter(
                      chapterKey: key,
                      novelId: 500,
                      chapterId: int.parse(key.split(':').last),
                      label: key,
                      contentApi: '/$key',
                      isVip: false,
                      filePath: '/$key',
                      byteSize: 0,
                      downloadedAtUtcMs: 1,
                      vipVerifiedAtUtcMs: null,
                      vipExpiresAtUtcMs: null,
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
    wifiOnly: false,
    totalBytes: 0,
    quotaBlockGeneration: 0,
    isInitializing: false,
  );
}
