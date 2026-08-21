import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/data/models/novel_details_data.dart';
import 'package:galaxy_novels_app/data/models/reader_content_data.dart';
import 'package:galaxy_novels_app/features/account/domain/auth_session.dart';
import 'package:galaxy_novels_app/features/downloads/application/download_repository.dart';
import 'package:galaxy_novels_app/features/downloads/domain/download_entitlement.dart';
import 'package:galaxy_novels_app/features/downloads/domain/download_models.dart';
import 'package:galaxy_novels_app/features/novel_details/application/download_planner_controller.dart';
import 'package:galaxy_novels_app/features/novel_details/domain/readable_chapter.dart';
import 'package:galaxy_novels_app/features/novel_details/presentation/download_planner_sheet.dart';

void main() {
  testWidgets('shows quick choices quota forecast and wifi control', (
    tester,
  ) async {
    final repository = _PlannerDownloadRepository(_dashboard(remaining: 18));
    final controller = DownloadPlannerController(
      chapters: _chapters(120),
      dashboard: repository.value,
      readingChapterPosition: 10,
    );

    await tester.pumpWidget(_TestSheet(controller, repository));

    expect(find.text('اختر الفصول للتنزيل'), findsOneWidget);
    expect(find.byKey(const ValueKey('download-planner-next')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('download-planner-range')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('download-planner-all')), findsOneWidget);
    expect(find.text('25'), findsWidgets);
    expect(find.text('ينزّل الآن'), findsOneWidget);
    expect(find.text('18'), findsWidgets);
    expect(
      find.byKey(const ValueKey('download-planner-wifi-only')),
      findsOneWidget,
    );
    expect(find.text('ابدأ تنزيل 25 فصلًا'), findsOneWidget);
  });

  testWidgets('quick count updates the plan and primary action', (
    tester,
  ) async {
    final repository = _PlannerDownloadRepository(_dashboard());
    final controller = DownloadPlannerController(
      chapters: _chapters(120),
      dashboard: repository.value,
    );
    await tester.pumpWidget(_TestSheet(controller, repository));

    await tester.tap(find.byKey(const ValueKey('download-planner-count-50')));
    await tester.pump();

    expect(controller.quickCount, 50);
    expect(find.text('ابدأ تنزيل 50 فصلًا'), findsOneWidget);
  });

  testWidgets('range selection validates and previews exact chapters', (
    tester,
  ) async {
    final repository = _PlannerDownloadRepository(_dashboard());
    final controller = DownloadPlannerController(
      chapters: _chapters(120),
      dashboard: repository.value,
    );
    await tester.pumpWidget(_TestSheet(controller, repository));

    await tester.tap(find.byKey(const ValueKey('download-planner-range')));
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('download-planner-range-start')),
      '20',
    );
    await tester.enterText(
      find.byKey(const ValueKey('download-planner-range-end')),
      '29',
    );
    await tester.pump();

    expect(controller.preview.chapters, hasLength(10));
    expect(find.text('ابدأ تنزيل 10 فصول'), findsOneWidget);
  });

  testWidgets('successful enqueue replaces editor with a result summary', (
    tester,
  ) async {
    final repository = _PlannerDownloadRepository(_dashboard());
    final controller = DownloadPlannerController(
      chapters: _chapters(30),
      dashboard: repository.value,
    );
    await tester.pumpWidget(_TestSheet(controller, repository));

    await tester.tap(find.byKey(const ValueKey('download-planner-submit')));
    await tester.pumpAndSettle();

    expect(find.text('تمت الإضافة للطابور'), findsOneWidget);
    expect(find.text('25 فصلًا جديدًا'), findsOneWidget);
    expect(find.text('متابعة التصفح'), findsOneWidget);
    expect(find.text('عرض العمليات'), findsOneWidget);
  });

  testWidgets('preloads rewarded ad when the plan exceeds current credit', (
    tester,
  ) async {
    final repository = _PlannerDownloadRepository(_dashboard(remaining: 18));
    final controller = DownloadPlannerController(
      chapters: _chapters(30),
      dashboard: repository.value,
    );
    var preloadCalls = 0;

    await tester.pumpWidget(
      _TestSheet(
        controller,
        repository,
        actions: DownloadPlannerActions(
          preloadRewardedAd: () async => preloadCalls++,
        ),
      ),
    );
    await tester.pump();

    expect(preloadCalls, 1);
  });

  testWidgets('modal planner paints an opaque surface over novel content', (
    tester,
  ) async {
    final repository = _PlannerDownloadRepository(_dashboard());
    final controller = DownloadPlannerController(
      chapters: _chapters(30),
      dashboard: repository.value,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Builder(
          builder: (context) => Scaffold(
            backgroundColor: Colors.red,
            body: Center(
              child: FilledButton(
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => FractionallySizedBox(
                    heightFactor: 0.92,
                    child: NovelDownloadPlannerSheet(
                      controller: controller,
                      novel: const DownloadNovelRequest(
                        novelId: 500,
                        title: 'رواية الاختبار',
                        coverUrl: '',
                      ),
                      repository: repository,
                      actions: const DownloadPlannerActions(),
                    ),
                  ),
                ),
                child: const Text('فتح'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('فتح'));
    await tester.pumpAndSettle();

    final enclosingMaterials = tester.widgetList<Material>(
      find.ancestor(
        of: find.text('اختر الفصول للتنزيل'),
        matching: find.byType(Material),
      ),
    );
    expect(
      enclosingMaterials.any((material) => material.color?.a == 1),
      isTrue,
      reason: 'The planner must hide the novel content behind the modal.',
    );
  });

  testWidgets('remains usable at 320dp with 200 percent text and landscape', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });
    final repository = _PlannerDownloadRepository(_dashboard(remaining: 18));
    final controller = DownloadPlannerController(
      chapters: _chapters(120),
      dashboard: repository.value,
    );

    await tester.pumpWidget(_TestSheet(controller, repository));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('download-planner-submit')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    tester.view.physicalSize = const Size(720, 360);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('download-planner-submit')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

class _TestSheet extends StatelessWidget {
  const _TestSheet(
    this.controller,
    this.repository, {
    this.actions = const DownloadPlannerActions(),
  });

  final DownloadPlannerController controller;
  final DownloadRepository repository;
  final DownloadPlannerActions actions;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          height: 760,
          child: NovelDownloadPlannerSheet(
            controller: controller,
            novel: const DownloadNovelRequest(
              novelId: 500,
              title: 'رواية الاختبار',
              coverUrl: '',
            ),
            repository: repository,
            actions: actions,
          ),
        ),
      ),
    );
  }
}

class _PlannerDownloadRepository extends ChangeNotifier
    implements DownloadRepository {
  _PlannerDownloadRepository(this._dashboard);

  DownloadsDashboard _dashboard;

  @override
  DownloadsDashboard get value => _dashboard;

  @override
  Future<DownloadEnqueueResult> enqueue({
    required DownloadNovelRequest novel,
    required List<DownloadChapterRequest> chapters,
  }) async {
    return DownloadEnqueueResult(
      groupId: 'group-1',
      acceptedChapterKeys: chapters
          .map((chapter) => chapter.chapterKey)
          .toList(growable: false),
      skippedChapterKeys: const [],
    );
  }

  @override
  Future<void> setWifiOnly(bool enabled) async {
    _dashboard = _copyDashboard(_dashboard, wifiOnly: enabled);
    notifyListeners();
  }

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
  Future<void> retryJob(String jobId) async {}
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

DownloadsDashboard _dashboard({int remaining = 100}) => DownloadsDashboard(
  allowance: DownloadAllowance(
    plan: const DownloadPlan(
      baseChapters: 100,
      maxRewardedAds: 4,
      rewardPerAd: 20,
    ),
    remaining: remaining,
    adsRemaining: 4,
    shouldReset: false,
    effectiveDayOrdinal: 1,
  ),
  groups: const [],
  novels: const [],
  wifiOnly: false,
  totalBytes: 0,
  quotaBlockGeneration: 0,
  isInitializing: false,
);

DownloadsDashboard _copyDashboard(
  DownloadsDashboard source, {
  required bool wifiOnly,
}) {
  return DownloadsDashboard(
    allowance: source.allowance,
    groups: source.groups,
    novels: source.novels,
    wifiOnly: wifiOnly,
    totalBytes: source.totalBytes,
    quotaBlockGeneration: source.quotaBlockGeneration,
    isInitializing: source.isInitializing,
  );
}
