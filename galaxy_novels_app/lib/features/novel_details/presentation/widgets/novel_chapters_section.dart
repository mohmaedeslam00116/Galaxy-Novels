import 'package:flutter/material.dart';

import '../../../../app/app_dependencies.dart';
import '../../../../core/analytics/app_screen_names.dart';
import '../../../../data/models/novel_details_data.dart';
import '../../../../data/models/reading_progress.dart';
import '../../../../data/repositories/novel_repository.dart';
import '../../../../design_system/foundation/galaxy_route.dart';
import '../../../downloads/domain/download_models.dart';
import '../../../downloads/presentation/downloads_screen.dart';
import '../../../vip/application/vip_chapters_controller.dart';
import '../../../vip/domain/vip_chapter.dart';
import '../../../vip/presentation/vip_access_notice.dart';
import '../../application/chapter_download_request.dart';
import '../../application/download_planner_controller.dart';
import '../../domain/readable_chapter.dart';
import '../all_chapters_screen.dart';
import '../chapter_download_state.dart';
import '../chapter_download_feedback.dart';
import '../download_planner_sheet.dart';
import '../novel_details_visual_tokens.dart';
import '../visible_chapter_count.dart';
import 'readable_chapter_tile.dart';

class NovelChaptersSection extends StatefulWidget {
  const NovelChaptersSection({
    required this.result,
    required this.vipController,
    required this.canReadPrivate,
    required this.isAuthenticated,
    required this.isVipDirectContentRouteAvailable,
    this.readingProgress,
    required this.onRead,
    required this.onOpenVipChapter,
    required this.onSignIn,
    super.key,
  });

  final NovelDetailsLoadResult result;
  final VipChaptersController vipController;
  final bool canReadPrivate;
  final bool isAuthenticated;
  final bool isVipDirectContentRouteAvailable;
  final ReadingProgress? readingProgress;
  final void Function(NovelChapter chapter, String novelTitle) onRead;
  final void Function(String contentApi, String title) onOpenVipChapter;
  final VoidCallback onSignIn;

  @override
  State<NovelChaptersSection> createState() => _NovelChaptersSectionState();
}

class _NovelChaptersSectionState extends State<NovelChaptersSection> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  bool _descending = false;

  @override
  void initState() {
    super.initState();
    _loadVipIfAllowed();
  }

  @override
  void didUpdateWidget(covariant NovelChaptersSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.vipController != widget.vipController ||
        (!oldWidget.canReadPrivate && widget.canReadPrivate) ||
        oldWidget.result.details.id != widget.result.details.id) {
      _loadVipIfAllowed();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<VipChaptersState>(
      valueListenable: widget.vipController,
      builder: (context, vipState, _) {
        final chapters = mergeReadableChapters(
          publicChapters: widget.result.chapters,
          vipChapters: _vipChaptersFor(vipState),
        );
        final visibleTotalCount = visibleNovelChapterCount(
          publicChapterCount: widget.result.details.chaptersCount,
          loadedPublicChapterCount: widget.result.chapters.length,
          canReadPrivate: widget.canReadPrivate,
          vipState: vipState,
        );
        final displayedChapters = readableChaptersForDisplay(
          chapters,
          query: _query,
          descending: _descending,
        );
        final hasQuery = _query.trim().isNotEmpty;
        final previewChapters = hasQuery
            ? displayedChapters
            : chapterPageItems(displayedChapters, 0);
        final canShowAll =
            !hasQuery &&
            (chapters.length > chaptersPerPage ||
                (widget.canReadPrivate &&
                    vipState.status == VipChaptersStatus.ready &&
                    vipState.hasMore));

        return SliverMainAxisGroup(
          slivers: [
            if (chapters.isNotEmpty)
              SliverToBoxAdapter(
                child: _BulkDownloadButton(
                  onPressed: () => _openDownloadPlanner(chapters),
                ),
              ),
            SliverToBoxAdapter(
              child: _ChapterDiscoveryControls(
                controller: _searchController,
                query: _query,
                descending: _descending,
                onQueryChanged: (value) => setState(() => _query = value),
                onClear: _clearQuery,
                onToggleOrder: () => setState(() => _descending = !_descending),
              ),
            ),
            if (widget.result.details.vipScheduleManifest.isNotEmpty &&
                !widget.canReadPrivate)
              SliverToBoxAdapter(
                child: VipAccessNotice(
                  title: 'فصول VIP مقفلة',
                  message: !widget.isAuthenticated
                      ? 'سجّل الدخول بحساب يملك اشتراك VIP لقراءة هذه الفصول.'
                      : 'لا يوجد اشتراك VIP فعال. الشراء داخل التطبيق غير متاح حاليًا.',
                  actionLabel: !widget.isAuthenticated ? 'فتح حسابي' : null,
                  onAction: !widget.isAuthenticated ? widget.onSignIn : null,
                ),
              ),
            if (widget.result.chaptersError != null)
              SliverToBoxAdapter(
                child: _InlineMessage(
                  title: 'تعذر تحميل الفصول الآن. أعد المحاولة بعد قليل.',
                ),
              )
            else if (chapters.isEmpty)
              SliverToBoxAdapter(
                child: _InlineMessage(
                  title: 'لا توجد فصول متاحة للعرض الآن',
                  subtitle: widget.result.details.chaptersCount > 0
                      ? 'قد تكون الفصول غير منشورة في الفهرس العام بعد'
                      : null,
                ),
              )
            else if (displayedChapters.isEmpty)
              const SliverToBoxAdapter(
                child: _InlineMessage(
                  key: ValueKey('novel-chapters-empty-search'),
                  title: 'لا توجد فصول مطابقة لبحثك',
                  subtitle: 'جرّب رقم فصل أو كلمة أخرى من العنوان',
                ),
              )
            else ...[
              _PreviewChapterSliverList(
                result: widget.result,
                chapters: previewChapters,
                isVipDirectContentRouteAvailable:
                    widget.isVipDirectContentRouteAvailable,
                onRead: widget.onRead,
                onOpenVipChapter: widget.onOpenVipChapter,
              ),
              if (canShowAll)
                SliverToBoxAdapter(
                  child: _ShowAllChaptersButton(
                    totalCount: visibleTotalCount,
                    onPressed: _openAllChapters,
                  ),
                ),
            ],
          ],
        );
      },
    );
  }

  void _clearQuery() {
    if (_query.isEmpty) return;
    _searchController.clear();
    setState(() => _query = '');
  }

  List<VipChapter> _vipChaptersFor(VipChaptersState state) {
    if (!widget.canReadPrivate || state.status != VipChaptersStatus.ready) {
      return const [];
    }
    return state.chapters;
  }

  void _openAllChapters() {
    _pushAllChapters(
      AllChaptersScreen(
        result: widget.result,
        vipController: widget.vipController,
        canReadPrivate: widget.canReadPrivate,
        isVipDirectContentRouteAvailable:
            widget.isVipDirectContentRouteAvailable,
      ),
    );
  }

  Future<void> _openDownloadPlanner(List<ReadableChapter> chapters) async {
    final dependencies = AppDependencies.of(context);
    final controller = DownloadPlannerController(
      chapters: chapters,
      dashboard: dependencies.downloadRepository.value,
      readingChapterPosition: widget.readingProgress?.chapterPosition,
      analytics: dependencies.downloadAnalytics,
    );
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => FractionallySizedBox(
        heightFactor: 0.92,
        child: NovelDownloadPlannerSheet(
          controller: controller,
          novel: DownloadNovelRequest(
            novelId: widget.result.details.id,
            title: widget.result.details.title,
            coverUrl: widget.result.details.bestCover,
          ),
          repository: dependencies.downloadRepository,
          actions: DownloadPlannerActions(
            loadAllChapters: _loadAllDownloadableChapters,
            selectManualChapters: _pickDownloadChapters,
            preloadRewardedAd:
                dependencies.rewardedDownloadAdRepository.preload,
            close: () => Navigator.of(sheetContext).pop(),
            openOperations: () {
              Navigator.of(sheetContext).pop();
              Navigator.of(context).push(
                galaxyPageRoute<void>(
                  context: context,
                  settings: const RouteSettings(name: AppScreenNames.downloads),
                  builder: (_) => DownloadsScreen(
                    repository: dependencies.downloadRepository,
                    rewardedAds: dependencies.rewardedDownloadAdRepository,
                    downloadAnalytics: dependencies.downloadAnalytics,
                    readingHistoryRepository:
                        dependencies.readingHistoryRepository,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
    controller.dispose();
  }

  Future<DownloadPlannerCatalogResult> _loadAllDownloadableChapters() async {
    var complete = true;
    if (widget.canReadPrivate &&
        widget.result.details.vipScheduleManifest.isNotEmpty) {
      complete = await widget.vipController.loadAll();
    }
    final state = widget.vipController.value;
    return DownloadPlannerCatalogResult(
      chapters: mergeReadableChapters(
        publicChapters: widget.result.chapters,
        vipChapters: _vipChaptersFor(state),
      ),
      complete: complete,
      errorMessage: complete
          ? null
          : state.errorMessage ??
                'تعذر تأكيد كل صفحات الفهرس. يمكنك الاكتفاء بالفصول الظاهرة.',
    );
  }

  Future<List<ReadableChapter>?> _pickDownloadChapters() {
    return Navigator.of(context).push<List<ReadableChapter>>(
      galaxyPageRoute<List<ReadableChapter>>(
        context: context,
        settings: const RouteSettings(name: AppScreenNames.allChapters),
        builder: (_) => AllChaptersScreen.picking(
          result: widget.result,
          vipController: widget.vipController,
          canReadPrivate: widget.canReadPrivate,
          isVipDirectContentRouteAvailable:
              widget.isVipDirectContentRouteAvailable,
        ),
      ),
    );
  }

  void _pushAllChapters(AllChaptersScreen screen) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: AppScreenNames.allChapters),
        builder: (context) => screen,
      ),
    );
  }

  void _loadVipIfAllowed() {
    if (widget.canReadPrivate &&
        widget.result.details.vipScheduleManifest.isNotEmpty) {
      widget.vipController.loadInitial();
    }
  }
}

class _ChapterDiscoveryControls extends StatelessWidget {
  const _ChapterDiscoveryControls({
    required this.controller,
    required this.query,
    required this.descending,
    required this.onQueryChanged,
    required this.onClear,
    required this.onToggleOrder,
  });

  final TextEditingController controller;
  final String query;
  final bool descending;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onClear;
  final VoidCallback onToggleOrder;

  @override
  Widget build(BuildContext context) {
    final tokens = NovelDetailsVisualTokens.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              key: const ValueKey('novel-chapter-search-field'),
              controller: controller,
              onChanged: onQueryChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'البحث عن فصل...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'مسح البحث',
                        onPressed: onClear,
                        icon: const Icon(Icons.close_rounded),
                      ),
                filled: true,
                fillColor: tokens.surfaceHigh,
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(999)),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox.square(
            dimension: 48,
            child: IconButton(
              key: const ValueKey('novel-chapter-order-toggle'),
              tooltip: descending ? 'ترتيب تصاعدي' : 'ترتيب تنازلي',
              onPressed: onToggleOrder,
              icon: Icon(
                descending ? Icons.south_rounded : Icons.swap_vert_rounded,
              ),
              style: IconButton.styleFrom(
                foregroundColor: tokens.textPrimary,
                backgroundColor: tokens.surface,
                side: BorderSide(color: tokens.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BulkDownloadButton extends StatelessWidget {
  const _BulkDownloadButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = NovelDetailsVisualTokens.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: OutlinedButton.icon(
        key: const ValueKey('novel-details-bulk-download'),
        onPressed: onPressed,
        icon: const Icon(Icons.download_for_offline_outlined),
        label: const Text('تنزيل عدة فصول'),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          alignment: AlignmentDirectional.centerStart,
          foregroundColor: tokens.primary,
          side: BorderSide(color: tokens.primary.withValues(alpha: 0.36)),
          textStyle: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _PreviewChapterSliverList extends StatelessWidget {
  const _PreviewChapterSliverList({
    required this.result,
    required this.chapters,
    required this.isVipDirectContentRouteAvailable,
    required this.onRead,
    required this.onOpenVipChapter,
  });

  final NovelDetailsLoadResult result;
  final List<ReadableChapter> chapters;
  final bool isVipDirectContentRouteAvailable;
  final void Function(NovelChapter chapter, String novelTitle) onRead;
  final void Function(String contentApi, String title) onOpenVipChapter;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<DownloadsDashboard>(
      valueListenable: AppDependencies.of(context).downloadRepository,
      builder: (context, dashboard, _) => SliverList(
        key: const ValueKey('novel-chapters-list-surface'),
        delegate: SliverChildBuilderDelegate(
          (context, index) => _chapterTile(context, dashboard, index),
          childCount: chapters.length,
          addAutomaticKeepAlives: false,
        ),
      ),
    );
  }

  Widget _chapterTile(
    BuildContext context,
    DownloadsDashboard dashboard,
    int index,
  ) {
    final chapter = chapters[index];
    final downloadState = resolveChapterDownloadState(
      dashboard,
      chapterDownloadKey(chapter),
    );
    return ReadableChapterTile(
      chapter: chapter,
      onTap: _chapterOnTap(index),
      downloadState: downloadState,
      onDownload: downloadState.status == ChapterDownloadStatus.available
          ? () => _downloadChapter(context, chapter)
          : null,
      onRetryDownload: downloadState.retryJobId == null
          ? null
          : () => _retryDownload(context, downloadState.retryJobId!),
    );
  }

  Future<void> _downloadChapter(
    BuildContext context,
    ReadableChapter chapter,
  ) async {
    final dependencies = AppDependencies.of(context);
    final navigator = Navigator.of(context);
    final operationsRoute = galaxyPageRoute<void>(
      context: context,
      settings: const RouteSettings(name: AppScreenNames.downloads),
      builder: (_) => DownloadsScreen(
        repository: dependencies.downloadRepository,
        rewardedAds: dependencies.rewardedDownloadAdRepository,
        readingHistoryRepository: dependencies.readingHistoryRepository,
        downloadAnalytics: dependencies.downloadAnalytics,
      ),
    );
    await enqueueChaptersWithFeedback(
      context: context,
      novel: DownloadNovelRequest(
        novelId: result.details.id,
        title: result.details.title,
        coverUrl: result.details.bestCover,
      ),
      chapters: [chapterDownloadRequest(chapter)],
      successMessage: (response) => response.acceptedChapterKeys.isEmpty
          ? 'الفصل محفوظ أو موجود في الطابور بالفعل'
          : 'تمت إضافة الفصل إلى التنزيلات',
      onOpenOperations: () =>
          _openDownloadOperations(navigator, operationsRoute),
    );
  }

  void _openDownloadOperations(
    NavigatorState navigator,
    Route<void> operationsRoute,
  ) {
    if (!navigator.mounted) return;
    navigator.push(operationsRoute);
  }

  Future<void> _retryDownload(BuildContext context, String jobId) =>
      retryChapterDownloadWithFeedback(context: context, jobId: jobId);

  VoidCallback? _chapterOnTap(int index) {
    final chapter = chapters[index];
    if (chapter.isVip) {
      final contentApi = readableChapterOpenContentApi(
        chapters,
        index,
        directVipChapterRouteAvailable: isVipDirectContentRouteAvailable,
      );
      if (contentApi.isEmpty) {
        return null;
      }
      return () => onOpenVipChapter(contentApi, chapter.label);
    }
    final publicChapter = chapter.publicChapter;
    if (publicChapter != null && publicChapter.effectiveContentApi.isNotEmpty) {
      return () => onRead(publicChapter, result.details.title);
    }
    return null;
  }
}

class _ShowAllChaptersButton extends StatelessWidget {
  const _ShowAllChaptersButton({
    required this.totalCount,
    required this.onPressed,
  });

  final int totalCount;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = NovelDetailsVisualTokens.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 18),
      child: OutlinedButton.icon(
        key: const ValueKey('show-all-chapters'),
        onPressed: onPressed,
        icon: const Icon(Icons.format_list_numbered_rtl_rounded),
        label: Text('عرض كل الفصول ($totalCount)'),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          foregroundColor: tokens.primary,
          side: BorderSide(color: tokens.primary.withValues(alpha: 0.36)),
          textStyle: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _InlineMessage extends StatelessWidget {
  const _InlineMessage({required this.title, this.subtitle, super.key});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = NovelDetailsVisualTokens.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tokens.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: tokens.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 6),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: tokens.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
