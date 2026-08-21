import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/app/app_dependencies.dart';
import 'package:galaxy_novels_app/app/app_theme.dart';
import 'package:galaxy_novels_app/core/analytics/app_screen_names.dart';
import 'package:galaxy_novels_app/core/config/app_config.dart';
import 'package:galaxy_novels_app/data/models/novel_details_data.dart';
import 'package:galaxy_novels_app/data/models/reader_content_data.dart';
import 'package:galaxy_novels_app/data/models/reading_progress.dart';
import 'package:galaxy_novels_app/data/repositories/fake_catalog_repository.dart';
import 'package:galaxy_novels_app/data/repositories/fake_home_repository.dart';
import 'package:galaxy_novels_app/data/repositories/fake_rankings_repository.dart';
import 'package:galaxy_novels_app/data/repositories/fake_search_repository.dart';
import 'package:galaxy_novels_app/data/repositories/novel_repository.dart';
import 'package:galaxy_novels_app/data/repositories/reader_repository.dart';
import 'package:galaxy_novels_app/data/repositories/reading_history_repository.dart';
import 'package:galaxy_novels_app/features/account/domain/auth_session.dart';
import 'package:galaxy_novels_app/features/comments/application/comments_repository.dart';
import 'package:galaxy_novels_app/features/comments/domain/comments_page.dart';
import 'package:galaxy_novels_app/features/comments/domain/public_comment.dart';
import 'package:galaxy_novels_app/features/downloads/application/download_repository.dart';
import 'package:galaxy_novels_app/features/downloads/domain/download_models.dart';
import 'package:galaxy_novels_app/features/novel_engagement/domain/novel_user_state.dart';
import 'package:galaxy_novels_app/features/novel_details/presentation/novel_details_screen.dart';
import 'package:galaxy_novels_app/features/vip/domain/vip_chapter.dart';

import '../../helpers/fake_reader_preferences_repository.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_comments_repository.dart';
import '../../helpers/fake_favorites_repository.dart';
import '../../helpers/fake_novel_engagement_repository.dart';
import '../../helpers/fake_vip_repository.dart';

void main() {
  testWidgets('shows feedback when starting a chapter download fails', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      _TestApp(
        repository: _LongNovelRepository(),
        downloadRepository: const _FailingDownloadRepository(),
      ),
    );
    await tester.pumpAndSettle();
    await _openChaptersTab(tester);

    final downloadButton = find.byKey(
      const ValueKey('chapter-download-public:1'),
    );
    await tester.scrollUntilVisible(
      downloadButton,
      300,
      scrollable: _verticalScrollable(),
    );
    await tester.tap(downloadButton);
    await tester.pump();

    expect(find.text('تعذر بدء التنزيل الآن. حاول مرة أخرى.'), findsOneWidget);
  });

  testWidgets('single chapter feedback exposes download operations', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final downloads = _MutableDownloadRepository();
    addTearDown(downloads.dispose);
    await tester.pumpWidget(
      _TestApp(
        repository: _LongNovelRepository(),
        downloadRepository: downloads,
      ),
    );
    await tester.pumpAndSettle();
    await _openChaptersTab(tester);

    final action = find.byKey(const ValueKey('chapter-download-public:1'));
    await tester.scrollUntilVisible(
      action,
      300,
      scrollable: _verticalScrollable(),
    );
    await tester.tap(action);
    await tester.pump();

    expect(find.text('تمت إضافة الفصل إلى التنزيلات'), findsOneWidget);
    expect(find.text('عرض العمليات'), findsOneWidget);
  });

  testWidgets('download Snackbar action survives closing the details route', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final downloads = _MutableDownloadRepository();
    final observer = _RecordingNavigatorObserver();
    addTearDown(downloads.dispose);
    await tester.pumpWidget(
      _TestApp(
        repository: _LongNovelRepository(),
        downloadRepository: downloads,
        routed: true,
        navigatorObserver: observer,
      ),
    );
    await tester.tap(find.byKey(const ValueKey('open-novel-details')));
    await tester.pumpAndSettle();
    await _openChaptersTab(tester);
    final action = find.byKey(const ValueKey('chapter-download-public:1'));
    await tester.scrollUntilVisible(
      action,
      300,
      scrollable: _verticalScrollable(),
    );
    await tester.tap(action);
    await tester.pump();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.text('عرض العمليات'));

    expect(tester.takeException(), isNull);
    expect(observer.pushedNames.last, AppScreenNames.downloads);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('account Snackbar action survives closing the details route', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final observer = _RecordingNavigatorObserver();
    await tester.pumpWidget(
      _TestApp(
        repository: _LongNovelRepository(),
        routed: true,
        navigatorObserver: observer,
      ),
    );
    await tester.tap(find.byKey(const ValueKey('open-novel-details')));
    await tester.pumpAndSettle();
    await tester.drag(_verticalScrollable(), const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('novel-favorite-toggle')));
    await tester.pump();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.text('حسابي'));

    expect(tester.takeException(), isNull);
    expect(observer.pushedNames.last, AppScreenNames.account);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('shows fifty chapters in details and opens paginated full list', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final repository = _LongNovelRepository();
    await tester.pumpWidget(_TestApp(repository: repository));
    await tester.pumpAndSettle();
    await _openChaptersTab(tester);

    final showAllButton = find.byKey(const ValueKey('show-all-chapters'));
    await tester.scrollUntilVisible(
      showAllButton,
      400,
      scrollable: _verticalScrollable(),
    );
    await tester.pumpAndSettle();

    expect(find.text('الفصل 50'), findsOneWidget);
    expect(find.text('الفصل 51'), findsNothing);

    await tester.tap(showAllButton);
    await tester.pumpAndSettle();

    expect(find.text('كل الفصول'), findsOneWidget);
    expect(find.byKey(const ValueKey('chapter-page-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('chapter-page-6')), findsOneWidget);
    expect(find.byKey(const ValueKey('chapter-page-previous')), findsOneWidget);
    expect(find.byKey(const ValueKey('chapter-page-next')), findsOneWidget);
    expect(find.text('الفصل 51'), findsNothing);

    final nextCenter = tester.getCenter(
      find.byKey(const ValueKey('chapter-page-next')),
    );
    final previousCenter = tester.getCenter(
      find.byKey(const ValueKey('chapter-page-previous')),
    );
    expect(nextCenter.dx, greaterThan(previousCenter.dx));

    await tester.scrollUntilVisible(
      find.text('الفصل 50'),
      320,
      scrollable: _verticalScrollable(),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('chapter-page-next')));
    await tester.pumpAndSettle();

    expect(find.text('الفصل 51'), findsOneWidget);
    expect(find.text('الفصل 100'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('الفصل 100'),
      320,
      scrollable: _verticalScrollable(),
    );
    await tester.pumpAndSettle();

    expect(find.text('الفصل 100'), findsOneWidget);
    expect(find.text('الفصل 101'), findsNothing);
    expect(repository.loadCalls, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('opens the selected chapter from later full-list pages', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final readerRepository = _RecordingReaderRepository();
    await tester.pumpWidget(
      _TestApp(
        repository: _LongNovelRepository(),
        readerRepository: readerRepository,
      ),
    );
    await tester.pumpAndSettle();
    await _openChaptersTab(tester);

    final showAllButton = find.byKey(const ValueKey('show-all-chapters'));
    await tester.scrollUntilVisible(
      showAllButton,
      400,
      scrollable: _verticalScrollable(),
    );
    await tester.pumpAndSettle();
    await tester.tap(showAllButton);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('chapter-page-next')));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('الفصل 51'),
      320,
      scrollable: _verticalScrollable(),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('الفصل 51'));
    await tester.pumpAndSettle();

    expect(readerRepository.loadedApis, contains('/chapters/51'));
    expect(readerRepository.loadedApis, isNot(contains('/chapters/1')));
  });

  testWidgets('filters the full chapter list by chapter number', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(_TestApp(repository: _LongNovelRepository()));
    await tester.pumpAndSettle();
    await _openChaptersTab(tester);

    final showAllButton = find.byKey(const ValueKey('show-all-chapters'));
    await tester.scrollUntilVisible(
      showAllButton,
      400,
      scrollable: _verticalScrollable(),
    );
    await tester.pumpAndSettle();
    await tester.tap(showAllButton);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('chapter-search-field')),
      '275',
    );
    await tester.pumpAndSettle();

    expect(find.text('الفصل 275'), findsOneWidget);
    expect(find.text('الفصل 274'), findsNothing);
    expect(find.text('الفصل 1'), findsNothing);
  });

  testWidgets('filters and reverses chapters inside novel details', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(_TestApp(repository: _LongNovelRepository()));
    await tester.pumpAndSettle();
    await _openChaptersTab(tester);

    final search = find.byKey(const ValueKey('novel-chapter-search-field'));
    await tester.scrollUntilVisible(
      search,
      300,
      scrollable: _verticalScrollable(),
    );
    await tester.enterText(search, '275');
    await tester.pump();

    expect(find.text('الفصل 275'), findsOneWidget);
    expect(find.text('الفصل 274'), findsNothing);

    await tester.enterText(search, '');
    await tester.pump();
    final orderToggle = find.byKey(
      const ValueKey('novel-chapter-order-toggle'),
    );
    await _revealAboveBottomBar(tester, orderToggle);
    await tester.tap(orderToggle);
    await tester.pump();

    expect(find.text('الفصل 300'), findsOneWidget);
    expect(find.text('الفصل 1'), findsNothing);
    expect(find.byIcon(Icons.download_outlined), findsNothing);
    expect(find.byIcon(Icons.download_rounded), findsWidgets);
  });

  testWidgets('loads novel comments only when their tab is opened', (
    tester,
  ) async {
    final commentsRepository = FakeCommentsRepository(
      handler: (target, sort, page) async => CommentsPage(
        version: 2,
        target: target,
        sort: sort,
        page: page,
        perPage: 20,
        totalComments: 1,
        totalRoots: 1,
        totalPages: 1,
        generated: 1,
        reactions: const {},
        comments: [_comment('تعليق الرواية')],
      ),
    );
    await tester.pumpWidget(
      _TestApp(
        repository: _LongNovelRepository(),
        commentsRepository: commentsRepository,
      ),
    );
    await tester.pumpAndSettle();

    expect(commentsRepository.calls, isEmpty);
    final commentsTab = find.byKey(const ValueKey('novel-section-comments'));
    await _revealAboveBottomBar(tester, commentsTab);
    await tester.tap(commentsTab);
    await tester.pumpAndSettle();

    expect(find.text('تعليق الرواية'), findsOneWidget);
    expect(commentsRepository.calls, hasLength(1));

    await tester.tap(find.byKey(const ValueKey('novel-section-chapters')));
    await tester.pump();
    await tester.tap(commentsTab);
    await tester.pump();

    expect(commentsRepository.calls, hasLength(1));
  });

  testWidgets('comment failure does not hide the read action', (tester) async {
    final commentsRepository = FakeCommentsRepository(
      handler: (_, _, _) => Future.error(Exception('offline')),
    );
    await tester.pumpWidget(
      _TestApp(
        repository: _LongNovelRepository(),
        commentsRepository: commentsRepository,
      ),
    );
    await tester.pumpAndSettle();

    final commentsTab = find.byKey(const ValueKey('novel-section-comments'));
    await _revealAboveBottomBar(tester, commentsTab);
    await tester.tap(commentsTab);
    await tester.pumpAndSettle();

    expect(find.text('تعذر تحميل التعليقات الآن.'), findsOneWidget);
    expect(find.text('ابدأ القراءة'), findsOneWidget);
  });

  testWidgets('read action updates when reading progress changes', (
    tester,
  ) async {
    final historyRepository = _MutableReadingHistoryRepository();
    addTearDown(historyRepository.dispose);
    await tester.pumpWidget(
      _TestApp(
        repository: _LongNovelRepository(),
        readingHistoryRepository: historyRepository,
      ),
    );
    await tester.pumpAndSettle();

    final readAction = find.byKey(const ValueKey('novel-details-read-action'));
    await tester.scrollUntilVisible(
      readAction,
      300,
      scrollable: _verticalScrollable(),
    );
    await tester.pumpAndSettle();

    expect(find.text('ابدأ القراءة'), findsOneWidget);

    await historyRepository.record(
      ReadingProgress(
        novelId: 500,
        novelTitle: 'رواية طويلة',
        chapterId: 8,
        chapterTitle: 'الفصل 8',
        contentApi: '/chapters/8',
        updatedAt: DateTime.utc(2026, 7, 20),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('متابعة الفصل 8'), findsOneWidget);
    expect(find.text('ابدأ القراءة'), findsNothing);
  });

  testWidgets('keeps VIP chapters inside the chapters section, not a tab', (
    tester,
  ) async {
    await tester.pumpWidget(
      _TestApp(repository: _LongNovelRepository(hasVipSchedule: true)),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('novel-section-chapters')),
      300,
      scrollable: _verticalScrollable(),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('novel-section-vip')), findsNothing);
    expect(find.text('الفصول'), findsWidgets);
  });

  testWidgets('VIP access adds private chapters to visible chapter counts', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      _TestApp(
        repository: _LongNovelRepository(hasVipSchedule: true),
        authRepository: FakeAuthRepository(
          initialState: const AuthSessionState.authenticated(_vipUser),
        ),
        engagementRepository: FakeNovelEngagementRepository(
          state: _vipUserState(novelId: 500),
        ),
        vipRepository: FakeVipRepository(
          page: VipChapterPage(
            items: List.generate(50, (index) => _vipChapter(301 + index)),
            hasMore: true,
            nextCursorOrder: '350.000000',
            nextCursorId: 350,
            totalAvailable: 60,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('360 فصل'), findsOneWidget);
    await _openChaptersTab(tester);

    final showAllButton = find.byKey(const ValueKey('show-all-chapters'));
    await tester.scrollUntilVisible(
      showAllButton,
      400,
      scrollable: _verticalScrollable(),
    );
    await tester.pumpAndSettle();

    expect(find.text('عرض كل الفصول (360)'), findsOneWidget);
  });

  testWidgets('VIP chapters open through the direct private content endpoint', (
    tester,
  ) async {
    final readerRepository = _RecordingReaderRepository();
    await tester.pumpWidget(
      _TestApp(
        repository: _LongNovelRepository(
          hasVipSchedule: true,
          publicChapterCount: 1,
        ),
        authRepository: FakeAuthRepository(
          initialState: const AuthSessionState.authenticated(_vipUser),
        ),
        engagementRepository: FakeNovelEngagementRepository(
          state: _vipUserState(novelId: 500),
        ),
        vipRepository: FakeVipRepository(
          page: VipChapterPage(
            items: [_vipChapter(2)],
            hasMore: false,
            nextCursorOrder: '',
            nextCursorId: 0,
            totalAvailable: 1,
          ),
        ),
        readerRepository: readerRepository,
      ),
    );
    await tester.pumpAndSettle();
    await _openChaptersTab(tester);

    await tester.scrollUntilVisible(
      find.text('الفصل 2'),
      300,
      scrollable: _verticalScrollable(),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('الفصل 2'));
    await tester.pumpAndSettle();

    expect(
      readerRepository.loadedApis,
      contains('/wp-json/wor-reader-app/v1/vip/chapters/2'),
    );
  });

  testWidgets('details exposes bulk download and opens the planner', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(_TestApp(repository: _LongNovelRepository()));
    await tester.pumpAndSettle();
    await _openChaptersTab(tester);

    final bulkDownload = find.byKey(
      const ValueKey('novel-details-bulk-download'),
    );
    expect(bulkDownload, findsOneWidget);
    await tester.scrollUntilVisible(
      bulkDownload,
      300,
      scrollable: _verticalScrollable(),
    );
    await tester.tap(bulkDownload);
    await tester.pumpAndSettle();

    expect(find.text('اختر الفصول للتنزيل'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('download-planner-submit')),
      findsOneWidget,
    );
  });

  testWidgets('bulk download accepts and enqueues an inclusive chapter range', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final downloads = _MutableDownloadRepository();
    addTearDown(downloads.dispose);

    await tester.pumpWidget(
      _TestApp(
        repository: _LongNovelRepository(),
        downloadRepository: downloads,
      ),
    );
    await tester.pumpAndSettle();
    await _openChaptersTab(tester);
    final bulkDownload = find.byKey(
      const ValueKey('novel-details-bulk-download'),
    );
    await tester.scrollUntilVisible(
      bulkDownload,
      300,
      scrollable: _verticalScrollable(),
    );
    await tester.tap(bulkDownload);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('download-planner-range')));
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('download-planner-range-start')),
      '11',
    );
    await tester.enterText(
      find.byKey(const ValueKey('download-planner-range-end')),
      '50',
    );
    await tester.pump();
    expect(find.text('ابدأ تنزيل 40 فصلًا'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('download-planner-submit')));
    await tester.pumpAndSettle();

    expect(downloads.enqueuedChapterKeys, hasLength(40));
    expect(downloads.enqueuedChapterKeys.first, 'public:11');
    expect(downloads.enqueuedChapterKeys.last, 'public:50');
  });

  testWidgets(
    'advanced selection returns chosen chapters to the planner before enqueue',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final downloads = _MutableDownloadRepository();
      addTearDown(downloads.dispose);

      await tester.pumpWidget(
        _TestApp(
          repository: _LongNovelRepository(),
          downloadRepository: downloads,
        ),
      );
      await tester.pumpAndSettle();
      await _openChaptersTab(tester);

      final bulkDownload = find.byKey(
        const ValueKey('novel-details-bulk-download'),
      );
      await tester.scrollUntilVisible(
        bulkDownload,
        300,
        scrollable: _verticalScrollable(),
      );
      await tester.tap(bulkDownload);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('download-planner-manual')));
      await tester.pumpAndSettle();
      expect(find.text('اختر الفصول'), findsOneWidget);

      await tester.tap(find.text('الفصل 3'));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('chapters-use-selection')));
      await tester.pumpAndSettle();

      expect(find.text('اختر الفصول للتنزيل'), findsOneWidget);
      expect(find.text('ابدأ تنزيل فصل واحد'), findsOneWidget);
      expect(downloads.enqueuedChapterKeys, isEmpty);

      await tester.tap(find.byKey(const ValueKey('download-planner-submit')));
      await tester.pumpAndSettle();
      expect(downloads.enqueuedChapterKeys, ['public:3']);
    },
  );

  testWidgets(
    'chapter action follows repository updates and retries failures',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final downloads = _MutableDownloadRepository();
      addTearDown(downloads.dispose);

      await tester.pumpWidget(
        _TestApp(
          repository: _LongNovelRepository(),
          downloadRepository: downloads,
        ),
      );
      await tester.pumpAndSettle();
      await _openChaptersTab(tester);
      final action = find.byKey(const ValueKey('chapter-download-public:1'));
      await tester.scrollUntilVisible(
        action,
        300,
        scrollable: _verticalScrollable(),
      );

      downloads.publish(
        _downloadDashboard(jobStatus: DownloadJobStatus.queued),
      );
      await tester.pump();
      expect(
        find.descendant(
          of: action,
          matching: find.byIcon(Icons.schedule_rounded),
        ),
        findsOneWidget,
      );

      downloads.publish(_downloadDashboard(downloaded: true));
      await tester.pump();
      expect(
        find.descendant(
          of: action,
          matching: find.byIcon(Icons.download_done_rounded),
        ),
        findsOneWidget,
      );

      downloads.publish(
        _downloadDashboard(jobStatus: DownloadJobStatus.failed),
      );
      await tester.pump();
      expect(
        find.descendant(
          of: action,
          matching: find.byIcon(Icons.refresh_rounded),
        ),
        findsOneWidget,
      );
      await tester.tap(action);
      expect(downloads.retriedJobIds, ['job-1']);
    },
  );
}

Finder _verticalScrollable() {
  return find.byWidgetPredicate(
    (widget) =>
        widget is Scrollable && widget.axisDirection == AxisDirection.down,
  );
}

Future<void> _openChaptersTab(WidgetTester tester) async {
  final chaptersTab = find.byKey(const ValueKey('novel-section-chapters'));
  await _revealAboveBottomBar(tester, chaptersTab);
  await tester.tap(chaptersTab);
  await tester.pumpAndSettle();
}

Future<void> _revealAboveBottomBar(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    300,
    scrollable: _verticalScrollable(),
  );
  await Scrollable.ensureVisible(
    tester.element(finder),
    alignment: 0.38,
    duration: Duration.zero,
  );
  await tester.pumpAndSettle();
}

class _TestApp extends StatelessWidget {
  const _TestApp({
    required this.repository,
    this.commentsRepository,
    this.authRepository,
    this.engagementRepository,
    this.vipRepository,
    this.readerRepository,
    this.downloadRepository,
    this.readingHistoryRepository,
    this.routed = false,
    this.navigatorObserver,
  });

  final NovelRepository repository;
  final CommentsRepository? commentsRepository;
  final FakeAuthRepository? authRepository;
  final FakeNovelEngagementRepository? engagementRepository;
  final FakeVipRepository? vipRepository;
  final ReaderRepository? readerRepository;
  final DownloadRepository? downloadRepository;
  final ReadingHistoryRepository? readingHistoryRepository;
  final bool routed;
  final NavigatorObserver? navigatorObserver;

  @override
  Widget build(BuildContext context) {
    return AppDependencies(
      config: const AppConfig(),
      homeRepository: const FakeHomeRepository(),
      catalogRepository: const FakeCatalogRepository(),
      novelRepository: repository,
      readerRepository: readerRepository ?? const _TestReaderRepository(),
      rankingsRepository: const FakeRankingsRepository(),
      searchRepository: const FakeSearchRepository(),
      readingHistoryRepository:
          readingHistoryRepository ?? const _TestReadingHistoryRepository(),
      readerPreferencesRepository: FakeReaderPreferencesRepository(),
      authRepository: authRepository ?? FakeAuthRepository(),
      commentsRepository: commentsRepository ?? FakeCommentsRepository.empty(),
      favoritesRepository: FakeFavoritesRepository(),
      novelEngagementRepository:
          engagementRepository ?? FakeNovelEngagementRepository(),
      vipRepository: vipRepository ?? const FakeVipRepository(),
      downloadRepository: downloadRepository ?? const NoopDownloadRepository(),
      child: MaterialApp(
        locale: const Locale('ar'),
        theme: AppTheme.light(),
        navigatorObservers: [?navigatorObserver],
        home: routed
            ? Builder(
                builder: (context) => Scaffold(
                  body: Center(
                    child: FilledButton(
                      key: const ValueKey('open-novel-details'),
                      onPressed: () => Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) => const Directionality(
                            textDirection: TextDirection.rtl,
                            child: NovelDetailsScreen(
                              manifestPath: '/novel-long.json',
                            ),
                          ),
                        ),
                      ),
                      child: const Text('فتح التفاصيل'),
                    ),
                  ),
                ),
              )
            : const Directionality(
                textDirection: TextDirection.rtl,
                child: NovelDetailsScreen(manifestPath: '/novel-long.json'),
              ),
      ),
    );
  }
}

class _RecordingNavigatorObserver extends NavigatorObserver {
  final List<String?> pushedNames = [];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushedNames.add(route.settings.name);
  }
}

class _FailingDownloadRepository extends NoopDownloadRepository {
  const _FailingDownloadRepository();

  @override
  Future<DownloadEnqueueResult> enqueue({
    required DownloadNovelRequest novel,
    required List<DownloadChapterRequest> chapters,
  }) {
    throw const DownloadUnavailableException();
  }
}

class _MutableDownloadRepository extends ChangeNotifier
    implements DownloadRepository {
  DownloadsDashboard _dashboard = NoopDownloadRepository.emptyDashboard;
  final List<String> retriedJobIds = [];
  List<String> enqueuedChapterKeys = const [];

  @override
  DownloadsDashboard get value => _dashboard;

  void publish(DownloadsDashboard dashboard) {
    _dashboard = dashboard;
    notifyListeners();
  }

  @override
  Future<DownloadEnqueueResult> enqueue({
    required DownloadNovelRequest novel,
    required List<DownloadChapterRequest> chapters,
  }) async {
    enqueuedChapterKeys = chapters
        .map((chapter) => chapter.chapterKey)
        .toList(growable: false);
    return DownloadEnqueueResult(
      groupId: 'group-enqueued',
      acceptedChapterKeys: chapters
          .map((chapter) => chapter.chapterKey)
          .toList(growable: false),
      skippedChapterKeys: const [],
    );
  }

  @override
  Future<void> retryJob(String jobId) async => retriedJobIds.add(jobId);

  @override
  Future<void> cancelGroup(String groupId) async {}

  @override
  Future<void> deleteChapters(Set<String> chapterKeys) async {}

  @override
  Future<void> grantReward({required String rewardEventId}) async {}

  @override
  Future<void> initialize() async {}

  @override
  Future<ReaderChapterContent> loadOffline(String offlineUri) {
    throw UnimplementedError();
  }

  @override
  Future<void> pauseGroup(String groupId) async {}

  @override
  Future<void> refreshMembership(AuthSessionState state) async {}

  @override
  Future<void> resumeGroup(String groupId) async {}

  @override
  Future<void> setWifiOnly(bool enabled) async {}
}

DownloadsDashboard _downloadDashboard({
  bool downloaded = false,
  DownloadJobStatus? jobStatus,
}) {
  return DownloadsDashboard(
    allowance: NoopDownloadRepository.emptyDashboard.allowance,
    groups: jobStatus == null
        ? const []
        : [
            DownloadGroup(
              groupId: 'group-1',
              novelId: 500,
              status: DownloadGroupStatus.running,
              stopReason: null,
              createdAtUtcMs: 1,
              updatedAtUtcMs: 2,
              jobs: [
                DownloadJob(
                  jobId: 'job-1',
                  groupId: 'group-1',
                  chapterKey: 'public:1',
                  chapterId: 1,
                  label: 'الفصل 1',
                  contentApi: '/chapters/1',
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
              novelId: 500,
              title: 'رواية طويلة',
              coverUrl: '',
              coverPath: '',
              totalBytes: 120,
              chapters: [
                DownloadedChapter(
                  chapterKey: 'public:1',
                  novelId: 500,
                  chapterId: 1,
                  label: 'الفصل 1',
                  contentApi: '/chapters/1',
                  isVip: false,
                  filePath: '/downloads/1.gnchapter',
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

PublicComment _comment(String content) {
  return PublicComment(
    id: 71,
    parentId: 0,
    rootId: 0,
    depth: 0,
    authorName: 'قارئ تجريبي',
    authorRank: '',
    avatarUrl: '',
    replyToName: '',
    content: content,
    isSpoiler: false,
    likeCount: 0,
    dislikeCount: 0,
    repliesCount: 0,
    score: 0,
    isPinned: false,
    createdLabel: 'الآن',
    createdAt: null,
    replies: const [],
  );
}

NovelUserState _vipUserState({required int novelId}) {
  return NovelUserState(
    novelId: novelId,
    favorite: false,
    myRating: 0,
    lastRead: const NovelLastRead(
      chapterId: 0,
      chapterUrl: '',
      progress: 0,
      updatedAt: null,
    ),
    vip: const NovelVipAccess(active: true, canReadPrivate: true),
  );
}

VipChapter _vipChapter(int number) {
  return VipChapter(
    id: number,
    number: '$number',
    position: number,
    order: '$number.000000',
    title: 'فصل خاص $number',
    url: '',
    publicAt: '',
    views: 0,
    comments: 0,
    contentApi: '/wp-json/wor-reader-app/v1/vip/chapters/$number',
  );
}

const _vipUser = AuthUser(
  id: 77,
  displayName: 'قارئ VIP',
  avatar: null,
  vip: AuthVip(active: true, tier: 'gold', label: 'VIP', expiresAt: null),
  xp: AuthXp(
    total: 0,
    today: 0,
    secondsTotal: 0,
    chaptersTotal: 0,
    rank: AuthRank(level: 1, display: 'قارئ'),
  ),
);

class _LongNovelRepository implements NovelRepository {
  _LongNovelRepository({
    this.hasVipSchedule = false,
    this.publicChapterCount = 300,
  });

  final bool hasVipSchedule;
  final int publicChapterCount;
  int loadCalls = 0;

  @override
  Future<NovelDetailsLoadResult> loadNovel(String manifestPath) async {
    loadCalls++;
    return NovelDetailsLoadResult(
      details: NovelDetails(
        id: 500,
        title: 'رواية طويلة',
        originalTitle: '',
        url: '/novel/long/',
        coverThumbnail: '',
        coverMedium: '',
        coverLarge: '',
        statusKey: 'ongoing',
        statusLabel: 'مستمرة',
        country: '',
        author: 'كاتب الاختبار',
        translator: '',
        genres: [],
        chaptersCount: publicChapterCount,
        firstChapterId: 1,
        firstChapterUrl: '/chapter-1/',
        ratingAverage: 4.5,
        ratingCount: 10,
        views: 1000,
        updatedAt: null,
        summary: '',
        chaptersManifest: '/chapters.json',
        vipScheduleManifest: hasVipSchedule ? '/vip-schedule.json' : '',
        manifest: '/novel-long.json',
      ),
      chapters: List.generate(publicChapterCount, (index) {
        final number = index + 1;
        return NovelChapter(
          id: number,
          position: number,
          number: '$number',
          label: 'الفصل $number',
          title: 'عنوان الفصل $number',
          url: '/chapter-$number/',
          contentApi: '/chapters/$number',
          dateLabel: 'اليوم',
          dateIso: null,
          views: 0,
          comments: 0,
          search: 'الفصل $number عنوان الفصل $number',
        );
      }),
    );
  }
}

class _TestReaderRepository implements ReaderRepository {
  const _TestReaderRepository();

  @override
  Future<ReaderChapterContent> loadChapter(String contentApi) {
    throw UnimplementedError();
  }
}

class _RecordingReaderRepository implements ReaderRepository {
  final loadedApis = <String>[];

  @override
  Future<ReaderChapterContent> loadChapter(String contentApi) async {
    loadedApis.add(contentApi);
    return const ReaderChapterContent(
      id: 2,
      novelId: 500,
      label: 'الفصل 2',
      title: 'VIP',
      displayTitle: 'الفصل 2',
      position: 2,
      total: 2,
      contentHtml: '<p>خاص</p>',
      navigation: ReaderChapterNavigation(
        previousApi: '',
        nextApi: '',
        previousId: 0,
        nextId: 0,
      ),
    );
  }
}

class _TestReadingHistoryRepository implements ReadingHistoryRepository {
  const _TestReadingHistoryRepository();

  @override
  void addListener(VoidCallback listener) {}

  @override
  Future<List<ReadingProgress>> load() async => const [];

  @override
  Future<void> record(ReadingProgress progress) async {}

  @override
  void removeListener(VoidCallback listener) {}
}

class _MutableReadingHistoryRepository extends ChangeNotifier
    implements ReadingHistoryRepository {
  List<ReadingProgress> _items = const [];

  @override
  Future<List<ReadingProgress>> load() async => _items;

  @override
  Future<void> record(ReadingProgress progress) async {
    _items = [
      progress,
      for (final item in _items)
        if (item.novelId != progress.novelId) item,
    ];
    notifyListeners();
  }
}
