import 'package:flutter/material.dart';

import '../../../app/app_dependencies.dart';
import '../../../app/app_theme.dart';
import '../../../core/analytics/app_screen_names.dart';
import '../../../data/repositories/novel_repository.dart';
import '../../downloads/domain/download_models.dart';
import '../../reader/presentation/reader_screen.dart';
import '../../vip/application/vip_chapters_controller.dart';
import '../../vip/domain/vip_chapter.dart';
import '../application/chapter_download_request.dart';
import '../domain/readable_chapter.dart';
import 'chapter_download_state.dart';
import 'chapter_download_feedback.dart';
import 'chapter_range_download_sheet.dart';
import 'visible_chapter_count.dart';
import 'widgets/readable_chapter_tile.dart';

class AllChaptersScreen extends StatefulWidget {
  const AllChaptersScreen({
    required this.result,
    required this.vipController,
    required this.canReadPrivate,
    required this.isVipDirectContentRouteAvailable,
    super.key,
  }) : _startsSelecting = false,
       _returnsSelection = false;

  const AllChaptersScreen.selecting({
    required this.result,
    required this.vipController,
    required this.canReadPrivate,
    required this.isVipDirectContentRouteAvailable,
    super.key,
  }) : _startsSelecting = true,
       _returnsSelection = false;

  const AllChaptersScreen.picking({
    required this.result,
    required this.vipController,
    required this.canReadPrivate,
    required this.isVipDirectContentRouteAvailable,
    super.key,
  }) : _startsSelecting = true,
       _returnsSelection = true;

  final NovelDetailsLoadResult result;
  final VipChaptersController vipController;
  final bool canReadPrivate;
  final bool isVipDirectContentRouteAvailable;
  final bool _startsSelecting;
  final bool _returnsSelection;

  @override
  State<AllChaptersScreen> createState() => _AllChaptersScreenState();
}

class _AllChaptersScreenState extends State<AllChaptersScreen> {
  final ScrollController _listController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  int _pageIndex = 0;
  String _searchQuery = '';
  late bool _selectionMode;
  final Set<String> _selectedChapterKeys = {};

  @override
  void initState() {
    super.initState();
    _selectionMode = widget._startsSelecting;
    _loadVipIfAllowed();
  }

  @override
  void didUpdateWidget(covariant AllChaptersScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.vipController != widget.vipController ||
        (!oldWidget.canReadPrivate && widget.canReadPrivate)) {
      _loadVipIfAllowed();
    }
  }

  @override
  void dispose() {
    _listController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectionMode ? 'اختر الفصول' : 'كل الفصول'),
        actions: [
          IconButton(
            key: const ValueKey('chapters-select-mode'),
            tooltip: _selectionMode ? 'إنهاء التحديد' : 'تحديد عدة فصول',
            onPressed: widget._returnsSelection
                ? () => Navigator.of(context).pop()
                : _toggleSelectionMode,
            icon: Icon(
              _selectionMode ? Icons.close_rounded : Icons.checklist_rounded,
            ),
          ),
        ],
      ),
      bottomNavigationBar: _selectionMode
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: FilledButton.icon(
                  key: ValueKey(
                    widget._returnsSelection
                        ? 'chapters-use-selection'
                        : 'chapters-download-selected',
                  ),
                  onPressed: _selectedChapterKeys.isEmpty
                      ? null
                      : widget._returnsSelection
                      ? _returnSelected
                      : _downloadSelected,
                  icon: Icon(
                    widget._returnsSelection
                        ? Icons.check_rounded
                        : Icons.download_rounded,
                  ),
                  label: Text(
                    widget._returnsSelection
                        ? 'استخدام المحدد (${_selectedChapterKeys.length})'
                        : 'تنزيل المحدد (${_selectedChapterKeys.length})',
                  ),
                ),
              ),
            )
          : null,
      body: SafeArea(
        child: ValueListenableBuilder<DownloadsDashboard>(
          valueListenable: AppDependencies.of(context).downloadRepository,
          builder: (context, dashboard, _) {
            return ValueListenableBuilder<VipChaptersState>(
              valueListenable: widget.vipController,
              builder: (context, vipState, _) {
                final chapters = mergeReadableChapters(
                  publicChapters: widget.result.chapters,
                  vipChapters: _vipChaptersFor(vipState),
                );
                final filteredChapters = _filteredChapters(chapters);
                final hasSearchQuery = _searchQuery.trim().isNotEmpty;
                final visibleTotalCount = visibleNovelChapterCount(
                  publicChapterCount: widget.result.details.chaptersCount,
                  loadedPublicChapterCount: widget.result.chapters.length,
                  canReadPrivate: widget.canReadPrivate,
                  vipState: vipState,
                );
                final pageCount = chapterPageCount(filteredChapters);
                final pageIndex = pageCount == 0
                    ? 0
                    : _pageIndex.clamp(0, pageCount - 1);
                final pageItems = chapterPageItems(filteredChapters, pageIndex);

                if (chapters.isEmpty) {
                  return const _EmptyChaptersView();
                }

                return Column(
                  children: [
                    _ChapterPager(
                      pageIndex: pageIndex,
                      pageCount: pageCount,
                      totalCount: hasSearchQuery
                          ? filteredChapters.length
                          : visibleTotalCount,
                      isFiltered: hasSearchQuery,
                      onSelected: _selectPage,
                    ),
                    if (_selectionMode && !widget._returnsSelection)
                      _DownloadRangeButton(
                        onPressed: () => _downloadRange(chapters),
                      ),
                    _ChapterSearchField(
                      controller: _searchController,
                      query: _searchQuery,
                      onChanged: _changeSearchQuery,
                      onClear: _clearSearchQuery,
                    ),
                    Expanded(
                      child: pageItems.isEmpty
                          ? _NoChapterSearchResultsView(query: _searchQuery)
                          : ListView.builder(
                              controller: _listController,
                              padding: const EdgeInsets.only(bottom: 16),
                              itemCount:
                                  pageItems.length +
                                  _moreVipButtonCount(vipState),
                              itemBuilder: (context, index) {
                                if (index == pageItems.length) {
                                  return _LoadMoreVipButton(
                                    isLoading: vipState.isLoadingMore,
                                    onPressed: widget.vipController.loadMore,
                                  );
                                }

                                final chapter = pageItems[index];
                                final downloadState =
                                    resolveChapterDownloadState(
                                      dashboard,
                                      chapterDownloadKey(chapter),
                                    );
                                return ReadableChapterTile(
                                  chapter: chapter,
                                  onTap: _chapterOnTap(
                                    filteredChapters,
                                    chapter,
                                  ),
                                  downloadState: downloadState,
                                  onDownload:
                                      downloadState.status ==
                                          ChapterDownloadStatus.available
                                      ? () => _downloadChapters([chapter])
                                      : null,
                                  onRetryDownload:
                                      downloadState.retryJobId == null
                                      ? null
                                      : () => _retryDownload(
                                          downloadState.retryJobId!,
                                        ),
                                  selectionMode: _selectionMode,
                                  selected: _selectedChapterKeys.contains(
                                    chapterDownloadKey(chapter),
                                  ),
                                  onToggleSelection: () =>
                                      _toggleChapterSelection(chapter),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _toggleSelectionMode() {
    setState(() {
      _selectionMode = !_selectionMode;
      if (!_selectionMode) _selectedChapterKeys.clear();
    });
  }

  void _toggleChapterSelection(ReadableChapter chapter) {
    final key = chapterDownloadKey(chapter);
    setState(() {
      if (!_selectedChapterKeys.add(key)) _selectedChapterKeys.remove(key);
    });
  }

  Future<void> _downloadSelected() async {
    final chapters =
        mergeReadableChapters(
          publicChapters: widget.result.chapters,
          vipChapters: _vipChaptersFor(widget.vipController.value),
        ).where(
          (chapter) =>
              _selectedChapterKeys.contains(chapterDownloadKey(chapter)),
        );
    await _downloadChapters(chapters.toList(growable: false));
    if (mounted) _toggleSelectionMode();
  }

  void _returnSelected() {
    final chapters =
        mergeReadableChapters(
              publicChapters: widget.result.chapters,
              vipChapters: _vipChaptersFor(widget.vipController.value),
            )
            .where(
              (chapter) =>
                  _selectedChapterKeys.contains(chapterDownloadKey(chapter)),
            )
            .toList(growable: false);
    Navigator.of(context).pop<List<ReadableChapter>>(chapters);
  }

  Future<void> _downloadChapters(List<ReadableChapter> chapters) async {
    await enqueueChaptersWithFeedback(
      context: context,
      novel: DownloadNovelRequest(
        novelId: widget.result.details.id,
        title: widget.result.details.title,
        coverUrl: widget.result.details.bestCover,
      ),
      chapters: chapters.map(chapterDownloadRequest).toList(growable: false),
      successMessage: (response) => response.acceptedChapterKeys.isEmpty
          ? 'الفصول المحددة محفوظة أو موجودة في الطابور بالفعل'
          : 'تمت إضافة ${response.acceptedChapterKeys.length} فصل إلى التنزيلات',
    );
  }

  Future<void> _downloadRange(List<ReadableChapter> chapters) async {
    final selected = await showChapterRangeDownloadSheet(
      context: context,
      chapters: chapters,
    );
    if (!mounted || selected == null || selected.isEmpty) {
      return;
    }
    await _downloadChapters(selected);
  }

  Future<void> _retryDownload(String jobId) =>
      retryChapterDownloadWithFeedback(context: context, jobId: jobId);

  void _selectPage(int index) {
    if (index == _pageIndex) {
      return;
    }

    setState(() => _pageIndex = index);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_listController.hasClients) {
        return;
      }
      _listController.animateTo(
        0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _changeSearchQuery(String value) {
    setState(() {
      _searchQuery = value;
      _pageIndex = 0;
    });
    _jumpListToTop();
  }

  void _clearSearchQuery() {
    if (_searchQuery.isEmpty) {
      return;
    }
    _searchController.clear();
    _changeSearchQuery('');
  }

  void _jumpListToTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_listController.hasClients) {
        return;
      }
      _listController.jumpTo(0);
    });
  }

  List<ReadableChapter> _filteredChapters(List<ReadableChapter> chapters) {
    return readableChaptersForDisplay(
      chapters,
      query: _searchQuery,
      descending: false,
    );
  }

  List<VipChapter> _vipChaptersFor(VipChaptersState state) {
    if (!widget.canReadPrivate || state.status != VipChaptersStatus.ready) {
      return const [];
    }
    return state.chapters;
  }

  int _moreVipButtonCount(VipChaptersState state) {
    if (!widget.canReadPrivate ||
        state.status != VipChaptersStatus.ready ||
        !state.hasMore) {
      return 0;
    }
    return 1;
  }

  VoidCallback? _chapterOnTap(
    List<ReadableChapter> chapters,
    ReadableChapter chapter,
  ) {
    final index = chapters.indexOf(chapter);
    final contentApi = readableChapterOpenContentApi(
      chapters,
      index,
      directVipChapterRouteAvailable: widget.isVipDirectContentRouteAvailable,
    );
    if (contentApi.isEmpty) {
      return null;
    }
    return () => _openChapter(contentApi, chapter);
  }

  void _openChapter(String contentApi, ReadableChapter chapter) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: AppScreenNames.reader),
        builder: (context) => ReaderScreen(
          contentApi: contentApi,
          chapterTitle: chapter.label,
          novelTitle: widget.result.details.title,
          coverUrl: widget.result.details.bestCover,
        ),
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

class _DownloadRangeButton extends StatelessWidget {
  const _DownloadRangeButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: OutlinedButton.icon(
        key: const ValueKey('chapters-download-range'),
        onPressed: onPressed,
        icon: const Icon(Icons.linear_scale_rounded),
        label: const Text('تنزيل نطاق من–إلى'),
      ),
    );
  }
}

class _ChapterPager extends StatelessWidget {
  const _ChapterPager({
    required this.pageIndex,
    required this.pageCount,
    required this.totalCount,
    required this.isFiltered,
    required this.onSelected,
  });

  final int pageIndex;
  final int pageCount;
  final int totalCount;
  final bool isFiltered;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;
    final startNumber = (pageIndex * chaptersPerPage) + 1;
    final endNumber = (startNumber + chaptersPerPage - 1).clamp(0, totalCount);
    final canGoPrevious = pageIndex > 0;
    final canGoNext = pageIndex < pageCount - 1;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.background,
        border: Border(bottom: BorderSide(color: tokens.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isFiltered
                            ? 'نتائج البحث $startNumber-$endNumber من $totalCount'
                            : 'الفصول $startNumber-$endNumber من $totalCount',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: tokens.textPrimary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'صفحة ${pageIndex + 1} من $pageCount',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: tokens.textSecondary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                _PagerIconButton(
                  key: const ValueKey('chapter-page-previous'),
                  icon: Icons.chevron_right_rounded,
                  tooltip: 'الصفحة السابقة',
                  onPressed: canGoPrevious
                      ? () => onSelected(pageIndex - 1)
                      : null,
                ),
                const SizedBox(width: 8),
                _PagerIconButton(
                  key: const ValueKey('chapter-page-next'),
                  icon: Icons.chevron_left_rounded,
                  tooltip: 'الصفحة التالية',
                  onPressed: canGoNext ? () => onSelected(pageIndex + 1) : null,
                ),
              ],
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (var index = 0; index < pageCount; index++) ...[
                    _PageButton(
                      key: ValueKey('chapter-page-${index + 1}'),
                      label: '${index + 1}',
                      selected: index == pageIndex,
                      onPressed: () => onSelected(index),
                    ),
                    if (index < pageCount - 1) const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChapterSearchField extends StatelessWidget {
  const _ChapterSearchField({
    required this.controller,
    required this.query,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: TextField(
        key: const ValueKey('chapter-search-field'),
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'ابحث برقم الفصل أو العنوان',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: query.isEmpty
              ? null
              : IconButton(
                  tooltip: 'مسح البحث',
                  onPressed: onClear,
                  icon: const Icon(Icons.close_rounded),
                ),
          filled: true,
          fillColor: tokens.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: tokens.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: tokens.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: tokens.primary),
          ),
        ),
      ),
    );
  }
}

class _PageButton extends StatelessWidget {
  const _PageButton({
    required this.label,
    required this.selected,
    required this.onPressed,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;

    return Semantics(
      selected: selected,
      button: true,
      label: 'صفحة $label',
      child: SizedBox(
        width: 48,
        height: 44,
        child: Material(
          color: selected ? tokens.primary : tokens.surfaceRaised,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: selected ? tokens.primary : tokens.border,
              width: selected ? 1.2 : 1,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: selected ? null : onPressed,
            child: Center(
              child: Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: selected ? tokens.background : tokens.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PagerIconButton extends StatelessWidget {
  const _PagerIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;
    final isEnabled = onPressed != null;

    return SizedBox.square(
      dimension: 44,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon),
        style: IconButton.styleFrom(
          backgroundColor: isEnabled ? tokens.surfaceRaised : tokens.surface,
          foregroundColor: isEnabled
              ? tokens.textPrimary
              : tokens.textSecondary.withValues(alpha: 0.45),
          disabledForegroundColor: tokens.textSecondary.withValues(alpha: 0.45),
          disabledBackgroundColor: tokens.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: tokens.border),
          ),
        ),
      ),
    );
  }
}

class _LoadMoreVipButton extends StatelessWidget {
  const _LoadMoreVipButton({required this.isLoading, required this.onPressed});

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
      child: OutlinedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? const SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.workspace_premium_outlined),
        label: const Text('تحميل المزيد من فصول VIP'),
      ),
    );
  }
}

class _NoChapterSearchResultsView extends StatelessWidget {
  const _NoChapterSearchResultsView({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, color: tokens.textSecondary),
            const SizedBox(height: 10),
            Text(
              'لا توجد فصول مطابقة',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall?.copyWith(
                color: tokens.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'جرّب رقم فصل أو كلمة من العنوان.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: tokens.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyChaptersView extends StatelessWidget {
  const _EmptyChaptersView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'لا توجد فصول متاحة الآن',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            color: tokens.textSecondary,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
