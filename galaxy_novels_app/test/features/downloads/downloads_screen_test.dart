import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/data/models/reading_progress.dart';
import 'package:galaxy_novels_app/data/repositories/reading_history_repository.dart';
import 'package:galaxy_novels_app/features/ads/application/rewarded_download_ad_repository.dart';
import 'package:galaxy_novels_app/features/downloads/application/download_repository.dart';
import 'package:galaxy_novels_app/features/downloads/domain/download_entitlement.dart';
import 'package:galaxy_novels_app/features/downloads/domain/download_models.dart';
import 'package:galaxy_novels_app/features/downloads/presentation/downloads_screen.dart';
import 'package:galaxy_novels_app/features/downloads/presentation/downloaded_novel_screen.dart';
import 'package:galaxy_novels_app/features/downloads/presentation/download_quota_prompt_host.dart';
import 'package:galaxy_novels_app/design_system/novel/galaxy_chapter_row.dart';
import 'package:galaxy_novels_app/design_system/novel/galaxy_novel_card.dart';

void main() {
  testWidgets('shows allowance, storage, Wi-Fi setting, and manual help', (
    tester,
  ) async {
    final repository = _FakeDownloadRepository(_dashboard);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        home: DownloadsScreen(
          repository: repository,
          rewardedAds: const NoopRewardedDownloadAdRepository(),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('downloads-screen')), findsOneWidget);
    expect(find.byKey(const ValueKey('downloads-allowance')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('download-queue-section')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('downloaded-novel-7')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('download-storage-usage')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<LinearProgressIndicator>(
            find.byKey(const ValueKey('downloads-allowance-progress')),
          )
          .value,
      0.73,
    );

    await tester.tap(find.byKey(const ValueKey('downloads-options')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('downloads-wifi-only')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('downloads-help')));
    await tester.pumpAndSettle();
    expect(find.text('1. افتح قائمة فصول الرواية'), findsOneWidget);
    expect(find.text('5. اقرأ الفصل دون اتصال'), findsOneWidget);
  });

  testWidgets('shows rewarded amount when the daily balance is empty', (
    tester,
  ) async {
    final repository = _FakeDownloadRepository(
      _dashboardWith(
        allowance: const DownloadAllowance(
          plan: DownloadPlan(
            baseChapters: 100,
            maxRewardedAds: 4,
            rewardPerAd: 20,
          ),
          remaining: 0,
          adsRemaining: 3,
          shouldReset: false,
          effectiveDayOrdinal: 1,
        ),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: DownloadsScreen(
          repository: repository,
          rewardedAds: const NoopRewardedDownloadAdRepository(),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('downloads-reward')));
    await tester.pumpAndSettle();
    expect(find.text('+20 فصلًا'), findsOneWidget);
    expect(find.text('متبقي 3 من 4 إعلانات اليوم'), findsOneWidget);
  });

  testWidgets('prompts once when queued downloads stop at the daily limit', (
    tester,
  ) async {
    final rewardedAds = _RecordingRewardedDownloadAdRepository();
    final repository = _FakeDownloadRepository(
      _dashboardWith(
        allowance: const DownloadAllowance(
          plan: DownloadPlan(
            baseChapters: 100,
            maxRewardedAds: 4,
            rewardPerAd: 20,
          ),
          remaining: 0,
          adsRemaining: 4,
          shouldReset: false,
          effectiveDayOrdinal: 1,
        ),
        quotaBlockGeneration: 1,
        groups: [
          DownloadGroup(
            groupId: 'quota-group',
            novelId: 7,
            status: DownloadGroupStatus.running,
            stopReason: null,
            createdAtUtcMs: 1,
            updatedAtUtcMs: 2,
            jobs: [
              for (var index = 0; index < 25; index++)
                _job(
                  'quota-$index',
                  index < 18
                      ? DownloadJobStatus.completed
                      : DownloadJobStatus.queued,
                ),
            ],
          ),
        ],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: DownloadQuotaPromptHost(
          repository: repository,
          rewardedAds: rewardedAds,
          child: const Scaffold(body: SizedBox.expand()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('انتهت التنزيلات المجانية لليوم'), findsOneWidget);
    expect(find.text('اكتمل 18 من 25، تبقى 7'), findsOneWidget);
    expect(rewardedAds.preloadCalls, 1);
  });

  testWidgets('keeps the quota explanation when all reward ads are used', (
    tester,
  ) async {
    final rewardedAds = _RecordingRewardedDownloadAdRepository();
    final repository = _FakeDownloadRepository(
      _dashboardWith(
        allowance: const DownloadAllowance(
          plan: DownloadPlan(
            baseChapters: 100,
            maxRewardedAds: 4,
            rewardPerAd: 20,
          ),
          remaining: 0,
          adsRemaining: 0,
          shouldReset: false,
          effectiveDayOrdinal: 1,
        ),
        quotaBlockGeneration: 1,
        groups: [
          DownloadGroup(
            groupId: 'quota-group',
            novelId: 7,
            status: DownloadGroupStatus.waitingForQuota,
            stopReason: null,
            createdAtUtcMs: 1,
            updatedAtUtcMs: 2,
            jobs: [_job('waiting', DownloadJobStatus.queued)],
          ),
        ],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: DownloadQuotaPromptHost(
          repository: repository,
          rewardedAds: rewardedAds,
          child: const Scaffold(body: SizedBox.expand()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('اكتملت إعلانات اليوم'), findsOneWidget);
    expect(find.textContaining('12:00 منتصف الليل'), findsOneWidget);
    expect(find.byIcon(Icons.ondemand_video_rounded), findsNothing);
    expect(rewardedAds.preloadCalls, 0);
  });

  testWidgets('queue shows only valid actions and hides canceled groups', (
    tester,
  ) async {
    final repository = _FakeDownloadRepository(
      _dashboardWith(
        groups: const [
          DownloadGroup(
            groupId: 'paused-group',
            novelId: 7,
            status: DownloadGroupStatus.paused,
            stopReason: null,
            createdAtUtcMs: 1,
            updatedAtUtcMs: 1,
            jobs: [],
          ),
          DownloadGroup(
            groupId: 'canceled-group',
            novelId: 8,
            status: DownloadGroupStatus.canceled,
            stopReason: DownloadFailure.canceled,
            createdAtUtcMs: 2,
            updatedAtUtcMs: 2,
            jobs: [],
          ),
        ],
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: DownloadsScreen(
          repository: repository,
          rewardedAds: const NoopRewardedDownloadAdRepository(),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('download-queue-section')));
    await tester.pumpAndSettle();

    expect(find.text('متوقف مؤقتًا'), findsWidgets);
    expect(find.text('ملغي'), findsNothing);

    await tester.tap(find.byTooltip('إدارة التنزيل'));
    await tester.pumpAndSettle();

    expect(find.text('استئناف'), findsOneWidget);
    expect(find.text('إلغاء'), findsOneWidget);
    expect(find.text('إيقاف مؤقت'), findsNothing);
  });

  testWidgets('queue shows completed chapter progress for each group', (
    tester,
  ) async {
    final repository = _FakeDownloadRepository(
      _dashboardWith(
        groups: [
          DownloadGroup(
            groupId: 'progress-group',
            novelId: 7,
            status: DownloadGroupStatus.running,
            stopReason: null,
            createdAtUtcMs: 1,
            updatedAtUtcMs: 1,
            jobs: [
              _job('completed-job', DownloadJobStatus.completed),
              _job('active-job', DownloadJobStatus.reserved),
            ],
          ),
        ],
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: DownloadsScreen(
          repository: repository,
          rewardedAds: const NoopRewardedDownloadAdRepository(),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('download-queue-section')));
    await tester.pumpAndSettle();

    expect(find.text('1 من 2 مكتمل'), findsWidgets);
    expect(
      tester
          .widget<LinearProgressIndicator>(
            find.byKey(
              const ValueKey('download-group-progress-progress-group'),
            ),
          )
          .value,
      0.5,
    );
  });

  testWidgets('chapter management exposes clear selection scopes', (
    tester,
  ) async {
    final repository = _FakeDownloadRepository(
      _dashboardWith(
        groups: const [],
        novels: [
          _downloadedNovel(
            chapters: [
              _downloadedChapter(71),
              _downloadedChapter(72),
              _downloadedChapter(73),
            ],
          ),
        ],
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: DownloadsScreen(
          repository: repository,
          rewardedAds: const NoopRewardedDownloadAdRepository(),
        ),
      ),
    );

    await tester.tap(find.text('رواية الاختبار'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('downloaded-novel-screen')),
      findsOneWidget,
    );
    expect(find.text('إدارة الفصول'), findsOneWidget);
    expect(find.byKey(const ValueKey('downloaded-novel-menu')), findsNothing);

    await tester.enterText(
      find.byKey(const ValueKey('downloaded-chapter-search')),
      '73',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('downloaded-chapter-manage')));
    await tester.pump();

    expect(find.text('تحديد النتائج الظاهرة (1)'), findsOneWidget);
    expect(find.text('تحديد جميع الفصول (3)'), findsOneWidget);
    expect(find.text('حذف جميع تنزيلات الرواية'), findsOneWidget);

    await _scrollDownloadedContentUntilVisible(
      tester,
      find.byKey(const ValueKey('downloaded-select-visible')),
    );
    await tester.tap(find.byKey(const ValueKey('downloaded-select-visible')));
    await tester.pump();
    expect(find.text('1 فصل محدد'), findsWidgets);
    await tester.tap(find.byKey(const ValueKey('downloaded-select-visible')));
    await tester.pump();
    expect(find.text('لم تحدد أي فصل بعد'), findsWidgets);
    await tester.tap(find.byKey(const ValueKey('downloaded-select-visible')));
    await tester.pump();
    expect(find.text('1 فصل محدد'), findsWidgets);

    await _scrollDownloadedContentToStart(tester);
    await tester.tap(find.byTooltip('مسح البحث'));
    await tester.pump();
    await _scrollDownloadedContentUntilVisible(
      tester,
      find.byKey(const ValueKey('downloaded-chapter-public:73')),
    );
    expect(
      tester
          .widget<GalaxyChapterRow>(
            find.byKey(const ValueKey('downloaded-chapter-public:73')),
          )
          .selected,
      isTrue,
    );

    await _scrollDownloadedContentUntilVisible(
      tester,
      find.byKey(const ValueKey('downloaded-select-all')),
    );
    await tester.tap(find.byKey(const ValueKey('downloaded-select-all')));
    await tester.pump();
    expect(find.text('3 فصول محددة'), findsWidgets);
    await tester.tap(find.byKey(const ValueKey('downloaded-select-all')));
    await tester.pump();
    expect(find.text('لم تحدد أي فصل بعد'), findsWidgets);
    await tester.tap(find.byKey(const ValueKey('downloaded-select-all')));
    await tester.pump();
    expect(find.text('3 فصول محددة'), findsWidgets);

    await _scrollDownloadedContentUntilVisible(
      tester,
      find.byKey(const ValueKey('downloaded-clear-selection')),
    );
    await tester.tap(find.byKey(const ValueKey('downloaded-clear-selection')));
    await tester.pump();
    expect(find.text('لم تحدد أي فصل بعد'), findsWidgets);
  });

  testWidgets('empty chapter selection bar stays compact above the list', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _FakeDownloadRepository(
      _dashboardWith(
        groups: const [],
        novels: [
          _downloadedNovel(
            chapters: [_downloadedChapter(71), _downloadedChapter(72)],
          ),
        ],
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: DownloadsScreen(
          repository: repository,
          rewardedAds: const NoopRewardedDownloadAdRepository(),
        ),
      ),
    );
    await tester.tap(find.text('رواية الاختبار'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('downloaded-chapter-manage')));
    await tester.pumpAndSettle();

    final selectionBar = find.byKey(
      const ValueKey('downloaded-selection-bottom-bar'),
    );
    expect(selectionBar, findsOneWidget);
    expect(tester.getSize(selectionBar).height, lessThan(180));
    await _scrollDownloadedContentUntilVisible(
      tester,
      find.byKey(const ValueKey('downloaded-chapter-public:71')),
    );
  });

  testWidgets('delete confirmation summarizes selection and current chapter', (
    tester,
  ) async {
    final repository = _FakeDownloadRepository(
      _dashboardWith(
        groups: const [],
        novels: [
          _downloadedNovel(
            chapters: [_downloadedChapter(71), _downloadedChapter(72)],
          ),
        ],
      ),
    );
    final history = _FakeReadingHistoryRepository([
      ReadingProgress(
        novelId: 7,
        novelTitle: 'رواية الاختبار',
        chapterId: 72,
        chapterTitle: 'الفصل 72',
        contentApi: '/chapters/72',
        chapterPosition: 72,
        chaptersTotal: 100,
        updatedAt: DateTime.utc(2026, 8, 8),
      ),
    ]);
    await tester.pumpWidget(
      MaterialApp(
        home: DownloadsScreen(
          repository: repository,
          rewardedAds: const NoopRewardedDownloadAdRepository(),
          readingHistoryRepository: history,
        ),
      ),
    );

    await tester.tap(find.text('رواية الاختبار'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('downloaded-chapter-manage')));
    await tester.pump();
    await _scrollDownloadedContentUntilVisible(
      tester,
      find.byKey(const ValueKey('downloaded-chapter-public:72')),
    );
    await tester.tap(
      find.byKey(const ValueKey('downloaded-chapter-public:72')),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('downloaded-delete-selected')));
    await tester.pumpAndSettle();

    expect(find.text('حذف 1 فصل؟'), findsOneWidget);
    expect(find.textContaining('رواية الاختبار'), findsWidgets);
    expect(find.textContaining('2.0 KB'), findsWidgets);
    expect(find.textContaining('غير قابل للتراجع'), findsOneWidget);
    expect(find.textContaining('فصل المتابعة الحالي'), findsOneWidget);
    expect(repository.deletedChapterKeys, isEmpty);

    await tester.tap(find.byKey(const ValueKey('downloaded-confirm-delete')));
    await tester.pumpAndSettle();

    expect(repository.deletedChapterKeys, {'public:72'});
  });

  testWidgets('failed deletion preserves chapter selection for retry', (
    tester,
  ) async {
    final repository = _FakeDownloadRepository(
      _dashboardWith(
        groups: const [],
        novels: [
          _downloadedNovel(chapters: [_downloadedChapter(71)]),
        ],
      ),
      failDeletion: true,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: DownloadsScreen(
          repository: repository,
          rewardedAds: const NoopRewardedDownloadAdRepository(),
        ),
      ),
    );

    await tester.tap(find.text('رواية الاختبار'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('downloaded-chapter-manage')));
    await tester.pump();
    await _scrollDownloadedContentUntilVisible(
      tester,
      find.byKey(const ValueKey('downloaded-chapter-public:71')),
    );
    await tester.tap(
      find.byKey(const ValueKey('downloaded-chapter-public:71')),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('downloaded-delete-selected')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('downloaded-confirm-delete')));
    await tester.pumpAndSettle();

    expect(find.text('إدارة الفصول'), findsOneWidget);
    expect(find.text('1 فصل محدد'), findsWidgets);
    expect(find.textContaining('أعد المحاولة'), findsOneWidget);
    expect(
      tester
          .widget<GalaxyChapterRow>(
            find.byKey(const ValueKey('downloaded-chapter-public:71')),
          )
          .selected,
      isTrue,
    );
  });

  testWidgets('system back exits chapter management before leaving the novel', (
    tester,
  ) async {
    final repository = _FakeDownloadRepository(
      _dashboardWith(
        groups: const [],
        novels: [
          _downloadedNovel(chapters: [_downloadedChapter(71)]),
        ],
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: DownloadsScreen(
          repository: repository,
          rewardedAds: const NoopRewardedDownloadAdRepository(),
        ),
      ),
    );

    await tester.tap(find.text('رواية الاختبار'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('downloaded-chapter-manage')));
    await tester.pump();
    expect(find.text('إدارة الفصول'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(DownloadedNovelScreen), findsOneWidget);
    expect(find.text('الفصول المحمّلة'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('downloaded-selection-visible')),
      findsNothing,
    );
  });

  testWidgets(
    'delete all is a separate management action and returns to downloads',
    (tester) async {
      final repository = _FakeDownloadRepository(
        _dashboardWith(
          groups: const [],
          novels: [
            _downloadedNovel(
              chapters: [_downloadedChapter(71), _downloadedChapter(72)],
            ),
          ],
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: DownloadsScreen(
            repository: repository,
            rewardedAds: const NoopRewardedDownloadAdRepository(),
          ),
        ),
      );

      await tester.tap(find.text('رواية الاختبار'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('downloaded-chapter-manage')));
      await tester.pump();
      await _scrollDownloadedContentUntilVisible(
        tester,
        find.byKey(const ValueKey('downloaded-delete-all')),
      );
      await tester.tap(find.byKey(const ValueKey('downloaded-delete-all')));
      await tester.pumpAndSettle();

      expect(find.text('حذف 2 فصل؟'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('downloaded-confirm-delete')));
      await tester.pumpAndSettle();

      expect(repository.deletedChapterKeys, {'public:71', 'public:72'});
      expect(find.byType(DownloadedNovelScreen), findsNothing);
      expect(find.byType(DownloadsScreen), findsOneWidget);
    },
  );

  testWidgets(
    'downloaded novel opens a dedicated searchable reading-focused screen',
    (tester) async {
      final repository = _FakeDownloadRepository(
        _dashboardWith(
          groups: const [],
          novels: [
            _downloadedNovel(
              chapters: [
                _downloadedChapter(71),
                _downloadedChapter(72),
                _downloadedChapter(73),
              ],
            ),
          ],
        ),
      );
      final history = _FakeReadingHistoryRepository([
        ReadingProgress(
          novelId: 7,
          novelTitle: 'رواية الاختبار',
          chapterId: 72,
          chapterTitle: 'الفصل 72',
          contentApi: '/chapters/72',
          chapterPosition: 72,
          chaptersTotal: 100,
          updatedAt: DateTime.utc(2026, 7, 26),
        ),
      ]);

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ar'),
          home: DownloadsScreen(
            repository: repository,
            rewardedAds: const NoopRewardedDownloadAdRepository(),
            readingHistoryRepository: history,
          ),
        ),
      );

      expect(find.byType(ExpansionTile), findsNothing);
      await tester.tap(find.text('رواية الاختبار'));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('downloaded-novel-screen')),
        findsOneWidget,
      );
      expect(find.text('آخر قراءة: الفصل 72'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('downloaded-novel-continue')),
        findsOneWidget,
      );

      await tester.enterText(
        find.byKey(const ValueKey('downloaded-chapter-search')),
        '73',
      );
      await tester.pump();
      expect(find.text('الفصل 73'), findsOneWidget);
      expect(find.text('الفصل 71'), findsNothing);

      await tester.tap(find.byTooltip('مسح البحث'));
      await tester.pump();
      await tester.tap(find.text('غير المقروء'));
      await tester.pump();

      expect(find.text('الفصل 73'), findsOneWidget);
      expect(find.text('الفصل 72'), findsNothing);
      expect(find.text('الفصل 71'), findsNothing);
    },
  );

  testWidgets('long press selects multiple downloaded chapters for deletion', (
    tester,
  ) async {
    final repository = _FakeDownloadRepository(
      _dashboardWith(
        groups: const [],
        novels: [
          _downloadedNovel(
            chapters: [
              _downloadedChapter(71),
              _downloadedChapter(72),
              _downloadedChapter(73),
            ],
          ),
        ],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: DownloadsScreen(
          repository: repository,
          rewardedAds: const NoopRewardedDownloadAdRepository(),
        ),
      ),
    );
    await tester.tap(find.text('رواية الاختبار'));
    await tester.pumpAndSettle();

    await _scrollDownloadedContentUntilVisible(
      tester,
      find.byKey(const ValueKey('downloaded-chapter-public:71')),
    );
    await tester.longPress(
      find.byKey(const ValueKey('downloaded-chapter-public:71')),
    );
    await tester.pump();
    await _scrollDownloadedContentUntilVisible(
      tester,
      find.byKey(const ValueKey('downloaded-chapter-public:72')),
    );
    await tester.tap(
      find.byKey(const ValueKey('downloaded-chapter-public:72')),
    );
    await tester.pump();

    expect(find.text('فصلان محددان'), findsWidgets);
    await tester.tap(find.byKey(const ValueKey('downloaded-delete-selected')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('downloaded-confirm-delete')));
    await tester.pumpAndSettle();

    expect(repository.deletedChapterKeys, {'public:71', 'public:72'});
  });

  testWidgets('download options save Wi-Fi preference immediately', (
    tester,
  ) async {
    final repository = _FakeDownloadRepository(_dashboard);
    await tester.pumpWidget(
      MaterialApp(
        home: DownloadsScreen(
          repository: repository,
          rewardedAds: const NoopRewardedDownloadAdRepository(),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('downloads-options')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('downloads-wifi-only')));
    await tester.pumpAndSettle();

    expect(repository.value.wifiOnly, isTrue);
  });

  testWidgets('canceling an active group requires confirmation', (
    tester,
  ) async {
    final repository = _FakeDownloadRepository(_dashboard);
    await tester.pumpWidget(
      MaterialApp(
        home: DownloadsScreen(
          repository: repository,
          rewardedAds: const NoopRewardedDownloadAdRepository(),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('download-queue-section')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('إدارة التنزيل'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('إلغاء').last);
    await tester.pumpAndSettle();

    expect(find.text('إلغاء مجموعة التنزيل؟'), findsOneWidget);
    expect(repository.canceledGroupIds, isEmpty);

    await tester.tap(
      find.byKey(const ValueKey('confirm-cancel-download-group')),
    );
    await tester.pumpAndSettle();

    expect(repository.canceledGroupIds, ['group-1']);
  });

  testWidgets('initializing downloads use a structure-matched skeleton', (
    tester,
  ) async {
    final repository = _FakeDownloadRepository(
      DownloadsDashboard(
        allowance: _dashboard.allowance,
        groups: const [],
        novels: const [],
        wifiOnly: false,
        totalBytes: 0,
        quotaBlockGeneration: 0,
        isInitializing: true,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: DownloadsScreen(
          repository: repository,
          rewardedAds: const NoopRewardedDownloadAdRepository(),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('downloads-loading-skeleton')),
      findsOneWidget,
    );
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('downloaded rows prefer an available local cover file', (
    tester,
  ) async {
    final directory = Directory.systemTemp.createTempSync(
      'galaxy-download-cover-',
    );
    addTearDown(() => directory.deleteSync(recursive: true));
    final cover = File('${directory.path}${Platform.pathSeparator}cover.jpg');
    cover.writeAsBytesSync(const [0]);
    final repository = _FakeDownloadRepository(
      _dashboardWith(
        groups: const [],
        novels: [
          DownloadedNovel(
            novelId: 7,
            title: 'رواية محلية',
            coverUrl: 'https://example.com/remote.jpg',
            coverPath: cover.path,
            totalBytes: 0,
            chapters: const [],
          ),
        ],
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: DownloadsScreen(
          repository: repository,
          rewardedAds: const NoopRewardedDownloadAdRepository(),
        ),
      ),
    );

    final card = tester.widget<GalaxyNovelCard>(
      find.byKey(const ValueKey('downloaded-novel-7')),
    );
    expect(card.novel.artwork, isA<FileImage>());
  });

  testWidgets('chapter jump reveals and highlights the requested download', (
    tester,
  ) async {
    final repository = _FakeDownloadRepository(
      _dashboardWith(
        groups: const [],
        novels: [
          _downloadedNovel(
            chapters: [
              _downloadedChapter(71),
              _downloadedChapter(72),
              _downloadedChapter(73),
            ],
          ),
        ],
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: DownloadsScreen(
          repository: repository,
          rewardedAds: const NoopRewardedDownloadAdRepository(),
        ),
      ),
    );
    await tester.tap(find.text('رواية الاختبار'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('downloaded-chapter-jump')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('downloaded-chapter-jump-input')),
      '72',
    );
    await tester.tap(
      find.byKey(const ValueKey('downloaded-chapter-jump-submit')),
    );
    await tester.pumpAndSettle();

    final scrollView = tester.widget<CustomScrollView>(
      find.byKey(const PageStorageKey('downloaded-chapter-list')),
    );
    expect(
      find.byKey(const ValueKey('downloaded-chapter-public:72')),
      findsOneWidget,
      reason:
          'jump offset=${scrollView.controller!.position.pixels}, max=${scrollView.controller!.position.maxScrollExtent}',
    );
    final row = tester.widget<GalaxyChapterRow>(
      find.byKey(const ValueKey('downloaded-chapter-public:72')),
    );
    expect(row.emphasized, isTrue);
  });

  testWidgets('explicit selection selects visible filtered chapters only', (
    tester,
  ) async {
    final repository = _FakeDownloadRepository(
      _dashboardWith(
        groups: const [],
        novels: [
          _downloadedNovel(
            chapters: [
              _downloadedChapter(71),
              _downloadedChapter(72),
              _downloadedChapter(73),
            ],
          ),
        ],
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: DownloadsScreen(
          repository: repository,
          rewardedAds: const NoopRewardedDownloadAdRepository(),
        ),
      ),
    );
    await tester.tap(find.text('رواية الاختبار'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('downloaded-chapter-search')),
      '73',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('downloaded-chapter-manage')));
    await tester.pump();
    await _scrollDownloadedContentUntilVisible(
      tester,
      find.byKey(const ValueKey('downloaded-select-visible')),
    );
    await tester.tap(find.byKey(const ValueKey('downloaded-select-visible')));
    await tester.pump();

    expect(find.text('1 فصل محدد'), findsWidgets);
    expect(
      tester
          .widget<GalaxyChapterRow>(
            find.byKey(const ValueKey('downloaded-chapter-public:73')),
          )
          .selected,
      isTrue,
    );
  });

  testWidgets('missing chapter jump does not open another chapter', (
    tester,
  ) async {
    final repository = _FakeDownloadRepository(
      _dashboardWith(
        groups: const [],
        novels: [
          _downloadedNovel(chapters: [_downloadedChapter(71)]),
        ],
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: DownloadsScreen(
          repository: repository,
          rewardedAds: const NoopRewardedDownloadAdRepository(),
        ),
      ),
    );
    await tester.tap(find.text('رواية الاختبار'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('downloaded-chapter-jump')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('downloaded-chapter-jump-input')),
      '999',
    );
    await tester.tap(
      find.byKey(const ValueKey('downloaded-chapter-jump-submit')),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(
      find.textContaining('غير موجود ضمن الفصول المحمّلة'),
      findsOneWidget,
    );
    expect(find.byType(DownloadedNovelScreen), findsOneWidget);
  });

  testWidgets('download surfaces reflow at 320 pixels and 200 percent text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final repository = _FakeDownloadRepository(
      _dashboardWith(
        groups: const [],
        novels: [
          _downloadedNovel(
            chapters: [_downloadedChapter(71), _downloadedChapter(72)],
          ),
        ],
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: DownloadsScreen(
          repository: repository,
          rewardedAds: const NoopRewardedDownloadAdRepository(),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    await tester.tap(find.text('رواية الاختبار'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await _scrollDownloadedContentUntilVisible(
      tester,
      find.byKey(const ValueKey('downloaded-chapter-manage')),
    );
    await tester.tap(find.byKey(const ValueKey('downloaded-chapter-manage')));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}

Future<void> _scrollDownloadedContentUntilVisible(
  WidgetTester tester,
  Finder target,
) async {
  final scrollView = tester.widget<CustomScrollView>(
    find.byKey(const PageStorageKey('downloaded-chapter-list')),
  );
  final controller = scrollView.controller!;
  while (target.evaluate().isEmpty &&
      controller.position.pixels < controller.position.maxScrollExtent) {
    controller.jumpTo(
      (controller.position.pixels + 180).clamp(
        0,
        controller.position.maxScrollExtent,
      ),
    );
    await tester.pump();
  }
  expect(target, findsAtLeastNWidgets(1));
  await tester.ensureVisible(target.first);
  await tester.pump();
}

Future<void> _scrollDownloadedContentToStart(WidgetTester tester) async {
  final scrollView = tester.widget<CustomScrollView>(
    find.byKey(const PageStorageKey('downloaded-chapter-list')),
  );
  scrollView.controller!.jumpTo(0);
  await tester.pump();
}

class _FakeDownloadRepository extends ChangeNotifier
    implements DownloadRepository {
  _FakeDownloadRepository(this._value, {this.failDeletion = false});
  DownloadsDashboard _value;
  final bool failDeletion;
  final Set<String> deletedChapterKeys = {};
  final List<String> canceledGroupIds = [];
  @override
  DownloadsDashboard get value => _value;
  @override
  Future<void> setWifiOnly(bool enabled) async {
    _value = _dashboardWith(wifiOnly: enabled);
    notifyListeners();
  }

  @override
  Future<void> deleteChapters(Set<String> chapterKeys) async {
    if (failDeletion) throw StateError('delete failed');
    deletedChapterKeys.addAll(chapterKeys);
  }

  @override
  Future<void> cancelGroup(String groupId) async {
    canceledGroupIds.add(groupId);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeReadingHistoryRepository extends ChangeNotifier
    implements ReadingHistoryRepository {
  _FakeReadingHistoryRepository(this.history);

  final List<ReadingProgress> history;

  @override
  Future<List<ReadingProgress>> load() async => history;

  @override
  Future<void> record(ReadingProgress progress) async {}
}

const _dashboard = DownloadsDashboard(
  allowance: DownloadAllowance(
    plan: DownloadPlan(baseChapters: 100, maxRewardedAds: 4, rewardPerAd: 20),
    remaining: 73,
    adsRemaining: 4,
    shouldReset: false,
    effectiveDayOrdinal: 1,
  ),
  groups: [
    DownloadGroup(
      groupId: 'group-1',
      novelId: 7,
      status: DownloadGroupStatus.running,
      stopReason: null,
      createdAtUtcMs: 1,
      updatedAtUtcMs: 1,
      jobs: [],
    ),
  ],
  novels: [
    DownloadedNovel(
      novelId: 7,
      title: 'رواية الاختبار',
      coverUrl: '',
      coverPath: '',
      totalBytes: 2048,
      chapters: [],
    ),
  ],
  wifiOnly: false,
  totalBytes: 2048,
  quotaBlockGeneration: 0,
  isInitializing: false,
);

DownloadsDashboard _dashboardWith({
  DownloadAllowance? allowance,
  bool? wifiOnly,
  int? quotaBlockGeneration,
  List<DownloadGroup>? groups,
  List<DownloadedNovel>? novels,
}) {
  return DownloadsDashboard(
    allowance: allowance ?? _dashboard.allowance,
    groups: groups ?? _dashboard.groups,
    novels: novels ?? _dashboard.novels,
    wifiOnly: wifiOnly ?? _dashboard.wifiOnly,
    totalBytes: _dashboard.totalBytes,
    quotaBlockGeneration:
        quotaBlockGeneration ?? _dashboard.quotaBlockGeneration,
    isInitializing: false,
  );
}

DownloadJob _job(String jobId, DownloadJobStatus status) {
  return DownloadJob(
    jobId: jobId,
    groupId: 'progress-group',
    chapterKey: 'public:$jobId',
    chapterId: jobId.hashCode,
    label: jobId,
    contentApi: '/chapters/$jobId',
    isVip: false,
    status: status,
    sortIndex: 0,
    reservedDayOrdinal: status == DownloadJobStatus.reserved ? 1 : null,
    transferTaskId: null,
    tempPath: null,
    attempts: 0,
    lastError: null,
  );
}

DownloadedNovel _downloadedNovel({required List<DownloadedChapter> chapters}) {
  return DownloadedNovel(
    novelId: 7,
    title: 'رواية الاختبار',
    coverUrl: '',
    coverPath: '',
    totalBytes: chapters.fold(0, (sum, chapter) => sum + chapter.byteSize),
    chapters: chapters,
  );
}

DownloadedChapter _downloadedChapter(int chapterId) {
  return DownloadedChapter(
    chapterKey: 'public:$chapterId',
    novelId: 7,
    chapterId: chapterId,
    label: 'الفصل $chapterId',
    contentApi: '/chapters/$chapterId',
    isVip: false,
    filePath: '/downloads/$chapterId.json',
    byteSize: 2048,
    downloadedAtUtcMs: chapterId,
    vipVerifiedAtUtcMs: null,
    vipExpiresAtUtcMs: null,
  );
}

class _RecordingRewardedDownloadAdRepository
    implements RewardedDownloadAdRepository {
  int preloadCalls = 0;

  @override
  RewardedDownloadAdAvailability get availability =>
      RewardedDownloadAdAvailability.ready;

  @override
  RewardedDownloadAdAvailability get value => availability;

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}

  @override
  Future<void> preload() async => preloadCalls++;

  @override
  Future<RewardedDownloadAdResult> show() async =>
      const RewardedDownloadAdResult(RewardedDownloadAdStatus.unavailable);

  @override
  void dispose() {}
}
