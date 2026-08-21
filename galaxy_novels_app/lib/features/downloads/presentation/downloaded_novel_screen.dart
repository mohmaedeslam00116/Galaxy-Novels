import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../core/analytics/app_screen_names.dart';
import '../../../data/models/reading_progress.dart';
import '../../../data/repositories/reading_history_repository.dart';
import '../../../design_system/galaxy_design_system.dart';
import '../../favorites/domain/favorite_item.dart';
import '../../novel_details/presentation/novel_details_navigation.dart';
import '../../reader/presentation/reader_screen.dart';
import '../application/download_repository.dart';
import '../data/downloaded_chapter_file_store.dart';
import '../domain/download_models.dart';
import 'download_artwork.dart';

enum _DownloadedChapterFilter { all, unread, read }

class DownloadedNovelScreen extends StatefulWidget {
  const DownloadedNovelScreen({
    required this.repository,
    required this.novelId,
    this.readingHistoryRepository,
    super.key,
  });

  final DownloadRepository repository;
  final int novelId;
  final ReadingHistoryRepository? readingHistoryRepository;

  @override
  State<DownloadedNovelScreen> createState() => _DownloadedNovelScreenState();
}

class _DownloadedNovelScreenState extends State<DownloadedNovelScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _chapterScrollController = ScrollController();
  final GlobalKey _chapterToolsKey = GlobalKey();
  final GlobalKey _selectionPanelKey = GlobalKey();
  final Set<String> _selectedChapterKeys = {};

  ReadingProgress? _progress;
  _DownloadedChapterFilter _filter = _DownloadedChapterFilter.all;
  bool _ascending = true;
  bool _deleting = false;
  bool _selectionModeActive = false;
  String? _jumpChapterKey;
  Timer? _jumpHighlightTimer;

  bool get _selectionMode => _selectionModeActive;

  @override
  void initState() {
    super.initState();
    widget.readingHistoryRepository?.addListener(_refreshHistory);
    unawaited(_loadHistory());
  }

  @override
  void didUpdateWidget(covariant DownloadedNovelScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.readingHistoryRepository == widget.readingHistoryRepository) {
      return;
    }
    oldWidget.readingHistoryRepository?.removeListener(_refreshHistory);
    widget.readingHistoryRepository?.addListener(_refreshHistory);
    unawaited(_loadHistory());
  }

  @override
  void dispose() {
    _jumpHighlightTimer?.cancel();
    widget.readingHistoryRepository?.removeListener(_refreshHistory);
    _searchController.dispose();
    _chapterScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final novel = _findNovel(widget.repository.value);
    return PopScope<void>(
      canPop: !_selectionMode,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _selectionMode) _clearSelection();
      },
      child: Scaffold(
        key: const ValueKey('downloaded-novel-screen'),
        appBar: AppBar(
          title: Text(_selectionMode ? 'إدارة الفصول' : 'الفصول المحمّلة'),
          leading: _selectionMode
              ? IconButton(
                  key: const ValueKey('downloaded-selection-close'),
                  tooltip: 'إنهاء التحديد',
                  onPressed: _clearSelection,
                  icon: const Icon(Icons.close_rounded),
                )
              : null,
          actions: _selectionMode && _selectedChapterKeys.isNotEmpty
              ? [
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 12),
                    child: Center(
                      child: GalaxyBadge(
                        label: '${_selectedChapterKeys.length}',
                        icon: Icons.check_rounded,
                        tone: GalaxyBadgeTone.brand,
                      ),
                    ),
                  ),
                ]
              : null,
        ),
        bottomNavigationBar: _selectionMode && novel != null
            ? _SelectionBar(
                selectedCount: _selectedChapterKeys.length,
                selectedBytes: _selectedBytes(novel),
                busy: _deleting,
                onDelete: () => _deleteSelected(novel),
              )
            : null,
        body: SafeArea(
          top: false,
          child: ValueListenableBuilder<DownloadsDashboard>(
            valueListenable: widget.repository,
            builder: (context, dashboard, child) {
              final currentNovel = _findNovel(dashboard);
              if (currentNovel == null) {
                return _RemovedDownloadsView(
                  onBack: () => Navigator.of(context).pop(),
                );
              }

              final chapters = _visibleChapters(currentNovel);
              final continueChapter = _continueChapter(currentNovel);
              final activeGroup = _activeGroupFor(dashboard);
              return CustomScrollView(
                controller: _chapterScrollController,
                key: const PageStorageKey('downloaded-chapter-list'),
                slivers: [
                  SliverToBoxAdapter(
                    child: _DownloadedNovelHeader(
                      novel: currentNovel,
                      progress: _progress,
                      continueChapter: continueChapter,
                      onContinue: continueChapter == null
                          ? null
                          : () => _openChapter(currentNovel, continueChapter),
                      onDownloadMore: () => _openNovelDetails(currentNovel),
                    ),
                  ),
                  if (activeGroup != null)
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        GalaxyAdaptive.horizontalPaddingFor(
                          MediaQuery.sizeOf(context).width,
                        ),
                        0,
                        GalaxyAdaptive.horizontalPaddingFor(
                          MediaQuery.sizeOf(context).width,
                        ),
                        GalaxyMetrics.space12,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: _ActiveNovelDownload(group: activeGroup),
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: _DownloadedChapterTools(
                      key: _chapterToolsKey,
                      controller: _searchController,
                      filter: _filter,
                      ascending: _ascending,
                      resultCount: chapters.length,
                      selectionMode: _selectionMode,
                      busy: _deleting,
                      onQueryChanged: (_) => setState(() {}),
                      onClear: _clearSearch,
                      onFilterChanged: (value) {
                        setState(() => _filter = value);
                      },
                      onToggleOrder: () {
                        setState(() => _ascending = !_ascending);
                      },
                      onJump: () => _showChapterJump(currentNovel),
                      onManage: _toggleSelectionMode,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: AnimatedSwitcher(
                      duration: GalaxyMotion.resolve(
                        context,
                        GalaxyMotion.stateChange,
                      ),
                      switchInCurve: GalaxyMotion.curve,
                      switchOutCurve: GalaxyMotion.curve,
                      child: _selectionMode
                          ? Padding(
                              key: const ValueKey(
                                'downloaded-selection-visible',
                              ),
                              padding: EdgeInsets.fromLTRB(
                                GalaxyAdaptive.horizontalPaddingFor(
                                  MediaQuery.sizeOf(context).width,
                                ),
                                0,
                                GalaxyAdaptive.horizontalPaddingFor(
                                  MediaQuery.sizeOf(context).width,
                                ),
                                GalaxyMetrics.space8,
                              ),
                              child: _ChapterSelectionPanel(
                                key: _selectionPanelKey,
                                visibleCount: chapters.length,
                                totalCount: currentNovel.chapters.length,
                                selectedCount: _selectedChapterKeys.length,
                                allVisibleSelected: _allVisibleSelected(
                                  currentNovel,
                                ),
                                allSelected: _allChaptersSelected(currentNovel),
                                busy: _deleting,
                                onToggleVisible: () =>
                                    _toggleVisibleSelection(currentNovel),
                                onToggleAll: () =>
                                    _toggleAllSelection(currentNovel),
                                onClear: _clearSelectedChapters,
                                onDeleteAll: () => _deleteAll(currentNovel),
                              ),
                            )
                          : const SizedBox.shrink(
                              key: ValueKey('downloaded-selection-hidden'),
                            ),
                    ),
                  ),
                  if (chapters.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _NoDownloadedChapterResults(
                        hasQuery: _searchController.text.trim().isNotEmpty,
                        onReset: _resetFilters,
                      ),
                    )
                  else
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        GalaxyAdaptive.horizontalPaddingFor(
                          MediaQuery.sizeOf(context).width,
                        ),
                        GalaxyMetrics.space8,
                        GalaxyAdaptive.horizontalPaddingFor(
                          MediaQuery.sizeOf(context).width,
                        ),
                        _selectionMode ? 24 : 32,
                      ),
                      sliver: SliverList.separated(
                        itemCount: chapters.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: GalaxyMetrics.space8),
                        itemBuilder: (context, index) {
                          final chapter = chapters[index];
                          return _DownloadedChapterRow(
                            chapter: chapter,
                            position: _chapterPosition(chapter),
                            selected: _selectedChapterKeys.contains(
                              chapter.chapterKey,
                            ),
                            selectionMode: _selectionMode,
                            current: _isCurrentChapter(chapter),
                            highlighted: _jumpChapterKey == chapter.chapterKey,
                            read: _isReadChapter(chapter),
                            onTap: _deleting
                                ? null
                                : () {
                                    if (_selectionMode) {
                                      _toggleSelection(chapter);
                                    } else {
                                      _openChapter(currentNovel, chapter);
                                    }
                                  },
                            onLongPress: _deleting
                                ? null
                                : () => _enterSelection(chapter),
                          );
                        },
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  DownloadedNovel? _findNovel(DownloadsDashboard dashboard) {
    for (final novel in dashboard.novels) {
      if (novel.novelId == widget.novelId) return novel;
    }
    return null;
  }

  DownloadGroup? _activeGroupFor(DownloadsDashboard dashboard) {
    for (final group in dashboard.groups.reversed) {
      if (group.novelId == widget.novelId &&
          group.status != DownloadGroupStatus.completed &&
          group.status != DownloadGroupStatus.canceled) {
        return group;
      }
    }
    return null;
  }

  Future<void> _loadHistory() async {
    final repository = widget.readingHistoryRepository;
    if (repository == null) {
      if (mounted) setState(() => _progress = null);
      return;
    }
    try {
      final history = await repository.load();
      ReadingProgress? next;
      for (final progress in history) {
        if (progress.novelId == widget.novelId) {
          next = progress;
          break;
        }
      }
      if (mounted) setState(() => _progress = next);
    } catch (_) {
      // Offline downloads stay usable when history synchronization fails.
    }
  }

  void _refreshHistory() => unawaited(_loadHistory());

  List<DownloadedChapter> _visibleChapters(DownloadedNovel novel) {
    final query = _normalize(_searchController.text);
    final chapters = novel.chapters
        .where((chapter) {
          final matchesQuery =
              query.isEmpty ||
              _normalize(chapter.label).contains(query) ||
              chapter.chapterId.toString().contains(query);
          if (!matchesQuery) return false;
          return switch (_filter) {
            _DownloadedChapterFilter.all => true,
            _DownloadedChapterFilter.unread => !_isReadChapter(chapter),
            _DownloadedChapterFilter.read => _isReadChapter(chapter),
          };
        })
        .toList(growable: false);
    chapters.sort(_compareChapters);
    return _ascending ? chapters : chapters.reversed.toList(growable: false);
  }

  int _compareChapters(DownloadedChapter first, DownloadedChapter second) {
    final positionOrder = _chapterPosition(
      first,
    ).compareTo(_chapterPosition(second));
    if (positionOrder != 0) return positionOrder;
    return first.downloadedAtUtcMs.compareTo(second.downloadedAtUtcMs);
  }

  int _chapterPosition(DownloadedChapter chapter) {
    final match = RegExp(r'\d+').firstMatch(chapter.label);
    return int.tryParse(match?.group(0) ?? '') ?? chapter.chapterId;
  }

  bool _isCurrentChapter(DownloadedChapter chapter) {
    final progress = _progress;
    if (progress == null) return false;
    return chapter.chapterId == progress.chapterId ||
        chapter.contentApi == progress.contentApi ||
        offlineChapterUri(chapter.chapterKey) == progress.contentApi;
  }

  bool _isReadChapter(DownloadedChapter chapter) {
    final progress = _progress;
    if (progress == null) return false;
    if (progress.chapterPosition > 0) {
      return _chapterPosition(chapter) <= progress.chapterPosition;
    }
    return _isCurrentChapter(chapter);
  }

  DownloadedChapter? _continueChapter(DownloadedNovel novel) {
    if (novel.chapters.isEmpty) return null;
    for (final chapter in novel.chapters) {
      if (_isCurrentChapter(chapter)) return chapter;
    }
    final ordered = [...novel.chapters]..sort(_compareChapters);
    final progressPosition = _progress?.chapterPosition ?? 0;
    if (progressPosition > 0) {
      for (final chapter in ordered) {
        if (_chapterPosition(chapter) >= progressPosition) return chapter;
      }
    }
    return ordered.first;
  }

  void _openChapter(DownloadedNovel novel, DownloadedChapter chapter) {
    Navigator.of(context)
        .push(
          galaxyPageRoute<void>(
            context: context,
            settings: const RouteSettings(name: AppScreenNames.reader),
            builder: (context) => ReaderScreen(
              contentApi: offlineChapterUri(chapter.chapterKey),
              chapterTitle: chapter.label,
              novelTitle: novel.title,
              coverUrl: novel.coverUrl,
            ),
          ),
        )
        .then((_) => _loadHistory());
  }

  void _openNovelDetails(DownloadedNovel novel) {
    unawaited(
      NovelDetailsNavigation.open(
        context,
        manifestPath: favoriteManifestPath(novel.novelId),
      ),
    );
  }

  void _toggleSelectionMode() {
    if (_selectionMode) {
      _clearSelection();
    } else {
      setState(() => _selectionModeActive = true);
    }
  }

  void _enterSelection(DownloadedChapter chapter) {
    setState(() {
      _selectionModeActive = true;
      _selectedChapterKeys.add(chapter.chapterKey);
    });
  }

  void _toggleSelection(DownloadedChapter chapter) {
    setState(() {
      if (!_selectedChapterKeys.add(chapter.chapterKey)) {
        _selectedChapterKeys.remove(chapter.chapterKey);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectionModeActive = false;
      _selectedChapterKeys.clear();
    });
  }

  void _clearSelectedChapters() {
    if (_deleting) return;
    setState(_selectedChapterKeys.clear);
  }

  bool _allVisibleSelected(DownloadedNovel novel) {
    final visible = _visibleChapters(novel);
    return visible.isNotEmpty &&
        visible.every(
          (chapter) => _selectedChapterKeys.contains(chapter.chapterKey),
        );
  }

  bool _allChaptersSelected(DownloadedNovel novel) {
    return novel.chapters.isNotEmpty &&
        novel.chapters.every(
          (chapter) => _selectedChapterKeys.contains(chapter.chapterKey),
        );
  }

  int _selectedBytes(DownloadedNovel novel) {
    return novel.chapters
        .where((chapter) => _selectedChapterKeys.contains(chapter.chapterKey))
        .fold(0, (sum, chapter) => sum + chapter.byteSize);
  }

  void _toggleVisibleSelection(DownloadedNovel novel) {
    if (_deleting) return;
    final visibleKeys = _visibleChapters(
      novel,
    ).map((chapter) => chapter.chapterKey).toSet();
    if (visibleKeys.isEmpty) return;
    final allVisibleSelected = visibleKeys.every(_selectedChapterKeys.contains);
    setState(() {
      _selectionModeActive = true;
      if (allVisibleSelected) {
        _selectedChapterKeys.removeAll(visibleKeys);
      } else {
        _selectedChapterKeys.addAll(visibleKeys);
      }
    });
  }

  void _toggleAllSelection(DownloadedNovel novel) {
    if (_deleting) return;
    final chapterKeys = novel.chapters
        .map((chapter) => chapter.chapterKey)
        .toSet();
    final allSelected = chapterKeys.every(_selectedChapterKeys.contains);
    setState(() {
      if (allSelected) {
        _selectedChapterKeys.removeAll(chapterKeys);
      } else {
        _selectedChapterKeys.addAll(chapterKeys);
      }
    });
  }

  Future<void> _showChapterJump(DownloadedNovel novel) async {
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => const _ChapterJumpDialog(),
    );
    if (!mounted || value == null) return;
    final requested = int.tryParse(value.trim());
    DownloadedChapter? match;
    if (requested != null) {
      for (final chapter in novel.chapters) {
        if (_chapterPosition(chapter) == requested) {
          match = chapter;
          break;
        }
      }
    }
    if (match == null) {
      _showMessage('الفصل ${value.trim()} غير موجود ضمن الفصول المحمّلة.');
      return;
    }

    _searchController.clear();
    setState(() {
      _filter = _DownloadedChapterFilter.all;
      _jumpChapterKey = match!.chapterKey;
    });
    _jumpHighlightTimer?.cancel();
    _jumpHighlightTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _jumpChapterKey = null);
    });
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted || !_chapterScrollController.hasClients) return;
    final visible = _visibleChapters(novel);
    final index = visible.indexWhere(
      (chapter) => chapter.chapterKey == match!.chapterKey,
    );
    if (index < 0) return;
    final leadingExtent =
        _scrollOffsetFor(_chapterToolsKey) +
        _renderedHeight(_chapterToolsKey) +
        (_selectionMode ? _renderedHeight(_selectionPanelKey) : 0);
    final target = (leadingExtent + index * 90.0).clamp(
      0.0,
      _chapterScrollController.position.maxScrollExtent,
    );
    await _chapterScrollController.animateTo(
      target,
      duration: GalaxyMotion.resolve(context, GalaxyMotion.emphasis),
      curve: GalaxyMotion.curve,
    );
  }

  double _renderedHeight(GlobalKey key) {
    final renderObject = key.currentContext?.findRenderObject();
    return renderObject is RenderBox ? renderObject.size.height : 0;
  }

  double _scrollOffsetFor(GlobalKey key) {
    final renderObject = key.currentContext?.findRenderObject();
    if (renderObject == null || !renderObject.attached) return 0;
    return RenderAbstractViewport.of(
      renderObject,
    ).getOffsetToReveal(renderObject, 0).offset;
  }

  Future<void> _deleteSelected(DownloadedNovel novel) async {
    if (_deleting || _selectedChapterKeys.isEmpty) return;
    final selected = novel.chapters
        .where((chapter) => _selectedChapterKeys.contains(chapter.chapterKey))
        .toList(growable: false);
    final confirmed = await _confirmDelete(novel, selected);
    if (!confirmed || !mounted) return;
    await _deleteChapters(novel, selected);
  }

  Future<void> _deleteAll(DownloadedNovel novel) async {
    if (_deleting || novel.chapters.isEmpty) return;
    final confirmed = await _confirmDelete(novel, novel.chapters);
    if (!confirmed || !mounted) return;
    await _deleteChapters(novel, novel.chapters);
  }

  Future<void> _deleteChapters(
    DownloadedNovel novel,
    List<DownloadedChapter> chapters,
  ) async {
    final chapterKeys = chapters.map((chapter) => chapter.chapterKey).toSet();
    final freedBytes = chapters.fold(
      0,
      (sum, chapter) => sum + chapter.byteSize,
    );
    final popWhenEmpty = chapters.length == novel.chapters.length;
    setState(() => _deleting = true);
    try {
      await widget.repository.deleteChapters(chapterKeys);
      if (!mounted) return;
      _showMessage(
        'تم حذف ${_chapterCountLabel(chapters.length)} وتحرير ${_formatBytes(freedBytes)}.',
      );
      if (popWhenEmpty) {
        Navigator.of(context).pop();
        return;
      }
      setState(() {
        _selectionModeActive = false;
        _selectedChapterKeys.clear();
      });
    } catch (_) {
      if (mounted) {
        _showMessage(
          'تعذر حذف الفصول من الجهاز. بقي التحديد محفوظًا، أعد المحاولة.',
        );
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  Future<bool> _confirmDelete(
    DownloadedNovel novel,
    List<DownloadedChapter> chapters,
  ) async {
    final freedBytes = chapters.fold(
      0,
      (sum, chapter) => sum + chapter.byteSize,
    );
    final includesCurrent = chapters.any(_isCurrentChapter);
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => GalaxyDialog(
        title: 'حذف ${chapters.length} فصل؟',
        content: _DeleteConfirmationSummary(
          novelTitle: novel.title,
          chapterCount: chapters.length,
          freedBytes: freedBytes,
          includesCurrentChapter: includesCurrent,
        ),
        actions: [
          GalaxyButton(
            label: 'إبقاء الفصول',
            variant: GalaxyActionVariant.ghost,
            onPressed: () => Navigator.of(dialogContext).pop(false),
          ),
          GalaxyButton(
            key: const ValueKey('downloaded-confirm-delete'),
            label: 'حذف ${chapters.length} فصل',
            variant: GalaxyActionVariant.danger,
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {});
  }

  void _resetFilters() {
    _searchController.clear();
    setState(() => _filter = _DownloadedChapterFilter.all);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _normalize(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '')
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا');
  }
}

class _DownloadedNovelHeader extends StatelessWidget {
  const _DownloadedNovelHeader({
    required this.novel,
    required this.progress,
    required this.continueChapter,
    required this.onContinue,
    required this.onDownloadMore,
  });

  final DownloadedNovel novel;
  final ReadingProgress? progress;
  final DownloadedChapter? continueChapter;
  final VoidCallback? onContinue;
  final VoidCallback onDownloadMore;

  @override
  Widget build(BuildContext context) {
    final metrics = GalaxyAdaptiveMetrics.forWidth(
      MediaQuery.sizeOf(context).width,
    );
    return Padding(
      padding: EdgeInsets.fromLTRB(
        metrics.horizontalPadding,
        GalaxyMetrics.space16,
        metrics.horizontalPadding,
        GalaxyMetrics.space16,
      ),
      child: GalaxySurface(
        variant: GalaxySurfaceVariant.tonal,
        padding: const EdgeInsets.all(GalaxyMetrics.space16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 560;
            final cover = SizedBox(
              width: wide ? 132 : 88,
              child: GalaxyNovelCover(
                artwork: GalaxyNovelArtwork(
                  title: novel.title,
                  image: downloadedNovelArtwork(context, novel),
                ),
                presentation: GalaxyCoverPresentation.tonalFrame,
              ),
            );
            final details = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  novel.title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: GalaxyMetrics.space8),
                Wrap(
                  spacing: GalaxyMetrics.space8,
                  runSpacing: GalaxyMetrics.space8,
                  children: [
                    GalaxyBadge(
                      label: '${novel.chapters.length} فصل',
                      icon: Icons.offline_pin_outlined,
                      tone: GalaxyBadgeTone.success,
                    ),
                    GalaxyBadge(
                      label: _formatBytes(novel.totalBytes),
                      icon: Icons.storage_rounded,
                    ),
                  ],
                ),
                if (progress != null) ...[
                  const SizedBox(height: GalaxyMetrics.space8),
                  Text(
                    'آخر قراءة: ${progress!.displayChapterTitle}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: GalaxyMetrics.space12),
                Wrap(
                  spacing: GalaxyMetrics.space8,
                  runSpacing: GalaxyMetrics.space8,
                  children: [
                    GalaxyButton(
                      key: const ValueKey('downloaded-novel-continue'),
                      label: continueChapter == null
                          ? 'لا توجد فصول متاحة'
                          : 'متابعة القراءة',
                      icon: Icons.menu_book_rounded,
                      onPressed: onContinue,
                    ),
                    GalaxyButton(
                      key: const ValueKey('downloaded-novel-more'),
                      label: 'تنزيل فصول إضافية',
                      icon: Icons.add_rounded,
                      variant: GalaxyActionVariant.secondary,
                      onPressed: onDownloadMore,
                    ),
                  ],
                ),
              ],
            );
            if (wide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  cover,
                  const SizedBox(width: GalaxyMetrics.space20),
                  Expanded(child: details),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                cover,
                const SizedBox(width: GalaxyMetrics.space12),
                Expanded(child: details),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ActiveNovelDownload extends StatelessWidget {
  const _ActiveNovelDownload({required this.group});

  final DownloadGroup group;

  @override
  Widget build(BuildContext context) {
    final completed = group.jobs
        .where((job) => job.status == DownloadJobStatus.completed)
        .length;
    final total = group.jobs.length;
    return GalaxySurface(
      variant: GalaxySurfaceVariant.base,
      padding: const EdgeInsets.all(GalaxyMetrics.space12),
      child: Row(
        children: [
          const Icon(Icons.downloading_rounded),
          const SizedBox(width: GalaxyMetrics.space12),
          Expanded(
            child: Text(
              total == 0
                  ? 'توجد عملية تنزيل لهذه الرواية'
                  : 'جارٍ تنزيل الفصول · $completed من $total',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          if (total > 0)
            SizedBox(
              width: 48,
              child: LinearProgressIndicator(value: completed / total),
            ),
        ],
      ),
    );
  }
}

class _DownloadedChapterTools extends StatelessWidget {
  const _DownloadedChapterTools({
    required this.controller,
    required this.filter,
    required this.ascending,
    required this.resultCount,
    required this.selectionMode,
    required this.busy,
    required this.onQueryChanged,
    required this.onClear,
    required this.onFilterChanged,
    required this.onToggleOrder,
    required this.onJump,
    required this.onManage,
    super.key,
  });

  final TextEditingController controller;
  final _DownloadedChapterFilter filter;
  final bool ascending;
  final int resultCount;
  final bool selectionMode;
  final bool busy;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onClear;
  final ValueChanged<_DownloadedChapterFilter> onFilterChanged;
  final VoidCallback onToggleOrder;
  final VoidCallback onJump;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    final horizontal = GalaxyAdaptive.horizontalPaddingFor(
      MediaQuery.sizeOf(context).width,
    );
    final tokens = GalaxyDesignTokens.of(context);
    return Material(
      color: tokens.canvas,
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          horizontal,
          GalaxyMetrics.space8,
          horizontal,
          GalaxyMetrics.space8,
        ),
        child: Column(
          children: [
            GalaxySearchField(
              key: const ValueKey('downloaded-chapter-search'),
              controller: controller,
              hintText: 'ابحث برقم الفصل أو عنوانه',
              onChanged: onQueryChanged,
              onClear: controller.text.isEmpty ? null : onClear,
              statusText: '$resultCount فصل ظاهر',
            ),
            const SizedBox(height: GalaxyMetrics.space8),
            Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterChip(
                          label: 'الكل',
                          selected: filter == _DownloadedChapterFilter.all,
                          onSelected: () =>
                              onFilterChanged(_DownloadedChapterFilter.all),
                        ),
                        const SizedBox(width: GalaxyMetrics.space8),
                        _FilterChip(
                          label: 'غير المقروء',
                          selected: filter == _DownloadedChapterFilter.unread,
                          onSelected: () =>
                              onFilterChanged(_DownloadedChapterFilter.unread),
                        ),
                        const SizedBox(width: GalaxyMetrics.space8),
                        _FilterChip(
                          label: 'تمت قراءته',
                          selected: filter == _DownloadedChapterFilter.read,
                          onSelected: () =>
                              onFilterChanged(_DownloadedChapterFilter.read),
                        ),
                      ],
                    ),
                  ),
                ),
                if (!selectionMode) ...[
                  const SizedBox(width: GalaxyMetrics.space8),
                  GalaxyIconAction(
                    key: const ValueKey('downloaded-chapter-sort'),
                    tooltip: ascending ? 'الأحدث أولًا' : 'الأقدم أولًا',
                    icon: ascending
                        ? Icons.arrow_downward_rounded
                        : Icons.arrow_upward_rounded,
                    onPressed: onToggleOrder,
                  ),
                  const SizedBox(width: GalaxyMetrics.space8),
                  GalaxyIconAction(
                    key: const ValueKey('downloaded-chapter-jump'),
                    tooltip: 'الانتقال إلى فصل',
                    icon: Icons.pin_drop_outlined,
                    onPressed: onJump,
                  ),
                ],
              ],
            ),
            if (!selectionMode) ...[
              const SizedBox(height: GalaxyMetrics.space8),
              SizedBox(
                width: double.infinity,
                child: GalaxyButton(
                  key: const ValueKey('downloaded-chapter-manage'),
                  label: 'إدارة الفصول',
                  icon: Icons.checklist_rounded,
                  variant: GalaxyActionVariant.secondary,
                  onPressed: busy ? null : onManage,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChapterSelectionPanel extends StatelessWidget {
  const _ChapterSelectionPanel({
    required this.visibleCount,
    required this.totalCount,
    required this.selectedCount,
    required this.allVisibleSelected,
    required this.allSelected,
    required this.busy,
    required this.onToggleVisible,
    required this.onToggleAll,
    required this.onClear,
    required this.onDeleteAll,
    super.key,
  });

  final int visibleCount;
  final int totalCount;
  final int selectedCount;
  final bool allVisibleSelected;
  final bool allSelected;
  final bool busy;
  final VoidCallback onToggleVisible;
  final VoidCallback onToggleAll;
  final VoidCallback onClear;
  final VoidCallback onDeleteAll;

  @override
  Widget build(BuildContext context) {
    final tokens = GalaxyDesignTokens.of(context);
    return AnimatedSwitcher(
      duration: GalaxyMotion.resolve(context, GalaxyMotion.stateChange),
      switchInCurve: GalaxyMotion.curve,
      switchOutCurve: GalaxyMotion.curve,
      child: GalaxySurface(
        key: const ValueKey('downloaded-selection-panel'),
        variant: GalaxySurfaceVariant.tonal,
        padding: const EdgeInsets.all(GalaxyMetrics.space12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final buttonWidth = constraints.maxWidth >= 360
                ? (constraints.maxWidth - GalaxyMetrics.space8) / 2
                : constraints.maxWidth;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  selectedCount == 0
                      ? 'لم تحدد أي فصل بعد'
                      : _selectedCountLabel(selectedCount),
                  key: const ValueKey('downloaded-selection-summary'),
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: GalaxyMetrics.space4),
                Text(
                  'اختر الفصول من القائمة أو استخدم أحد نطاقات التحديد.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: tokens.contentSecondary,
                  ),
                ),
                const SizedBox(height: GalaxyMetrics.space12),
                Wrap(
                  spacing: GalaxyMetrics.space8,
                  runSpacing: GalaxyMetrics.space8,
                  children: [
                    SizedBox(
                      width: buttonWidth,
                      child: GalaxyButton(
                        key: const ValueKey('downloaded-select-visible'),
                        label: allVisibleSelected
                            ? 'إلغاء تحديد النتائج ($visibleCount)'
                            : 'تحديد النتائج الظاهرة ($visibleCount)',
                        variant: GalaxyActionVariant.secondary,
                        onPressed: busy || visibleCount == 0
                            ? null
                            : onToggleVisible,
                      ),
                    ),
                    SizedBox(
                      width: buttonWidth,
                      child: GalaxyButton(
                        key: const ValueKey('downloaded-select-all'),
                        label: allSelected
                            ? 'إلغاء تحديد جميع الفصول'
                            : 'تحديد جميع الفصول ($totalCount)',
                        variant: GalaxyActionVariant.secondary,
                        onPressed: busy || totalCount == 0 ? null : onToggleAll,
                      ),
                    ),
                    if (selectedCount > 0)
                      SizedBox(
                        width: buttonWidth,
                        child: GalaxyButton(
                          key: const ValueKey('downloaded-clear-selection'),
                          label: 'مسح التحديد',
                          variant: GalaxyActionVariant.ghost,
                          onPressed: busy ? null : onClear,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: GalaxyMetrics.space12),
                Divider(color: tokens.outline.withValues(alpha: 0.55)),
                const SizedBox(height: GalaxyMetrics.space4),
                GalaxyButton(
                  key: const ValueKey('downloaded-delete-all'),
                  label: 'حذف جميع تنزيلات الرواية',
                  icon: Icons.delete_sweep_outlined,
                  variant: GalaxyActionVariant.danger,
                  onPressed: busy || totalCount == 0 ? null : onDeleteAll,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _ChapterJumpDialog extends StatefulWidget {
  const _ChapterJumpDialog();

  @override
  State<_ChapterJumpDialog> createState() => _ChapterJumpDialogState();
}

class _ChapterJumpDialogState extends State<_ChapterJumpDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GalaxyDialog(
      title: 'الانتقال إلى فصل',
      content: TextField(
        key: const ValueKey('downloaded-chapter-jump-input'),
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.go,
        decoration: const InputDecoration(
          labelText: 'رقم الفصل',
          hintText: 'مثال: 120',
        ),
        onSubmitted: (value) => Navigator.of(context).pop(value),
      ),
      actions: [
        GalaxyButton(
          label: 'إلغاء',
          variant: GalaxyActionVariant.ghost,
          onPressed: () => Navigator.of(context).pop(),
        ),
        GalaxyButton(
          key: const ValueKey('downloaded-chapter-jump-submit'),
          label: 'انتقال',
          onPressed: () => Navigator.of(context).pop(_controller.text),
        ),
      ],
    );
  }
}

class _DeleteConfirmationSummary extends StatelessWidget {
  const _DeleteConfirmationSummary({
    required this.novelTitle,
    required this.chapterCount,
    required this.freedBytes,
    required this.includesCurrentChapter,
  });

  final String novelTitle;
  final int chapterCount;
  final int freedBytes;
  final bool includesCurrentChapter;

  @override
  Widget build(BuildContext context) {
    final tokens = GalaxyDesignTokens.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'سيتم حذف ${_chapterCountLabel(chapterCount)} من «$novelTitle» وتحرير ${_formatBytes(freedBytes)} من الجهاز.',
        ),
        const SizedBox(height: GalaxyMetrics.space8),
        Text(
          'هذا الإجراء غير قابل للتراجع، ويمكن تنزيل الفصول مجددًا لاحقًا.',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: tokens.contentSecondary),
        ),
        if (includesCurrentChapter) ...[
          const SizedBox(height: GalaxyMetrics.space12),
          GalaxySurface(
            variant: GalaxySurfaceVariant.tonal,
            padding: const EdgeInsets.all(GalaxyMetrics.space12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber_rounded, color: tokens.warning),
                const SizedBox(width: GalaxyMetrics.space8),
                const Expanded(
                  child: Text(
                    'فصل المتابعة الحالي ضمن التحديد. سيبقى تقدم القراءة محفوظًا، لكن الفصل لن يكون متاحًا دون اتصال.',
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _DownloadedChapterRow extends StatelessWidget {
  const _DownloadedChapterRow({
    required this.chapter,
    required this.position,
    required this.selected,
    required this.selectionMode,
    required this.current,
    required this.highlighted,
    required this.read,
    required this.onTap,
    required this.onLongPress,
  });

  final DownloadedChapter chapter;
  final int position;
  final bool selected;
  final bool selectionMode;
  final bool current;
  final bool highlighted;
  final bool read;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final status = current
        ? 'متابعة من هنا'
        : read
        ? 'تمت قراءته'
        : 'متاح دون إنترنت';
    return GalaxyChapterRow(
      key: ValueKey('downloaded-chapter-${chapter.chapterKey}'),
      chapter: GalaxyChapterRowData(
        title: chapter.label,
        leadingLabel: '$position',
        subtitle: '$status · ${_formatBytes(chapter.byteSize)}',
        state: GalaxyChapterState.downloaded,
        isVip: chapter.isVip,
      ),
      selectionMode: selectionMode,
      selected: selected,
      emphasized: current || highlighted,
      showAction: false,
      showNavigationIndicator: !selectionMode,
      onTap: onTap,
      onLongPress: onLongPress,
      onSelectionChanged: onTap == null ? null : (_) => onTap!(),
    );
  }
}

class _SelectionBar extends StatelessWidget {
  const _SelectionBar({
    required this.selectedCount,
    required this.selectedBytes,
    required this.busy,
    required this.onDelete,
  });

  final int selectedCount;
  final int selectedBytes;
  final bool busy;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      key: const ValueKey('downloaded-selection-bottom-bar'),
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(GalaxyMetrics.space8),
        child: GalaxySurface(
          variant: GalaxySurfaceVariant.raised,
          padding: const EdgeInsets.all(GalaxyMetrics.space8),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact =
                  constraints.maxWidth < 520 ||
                  MediaQuery.textScalerOf(context).scale(1) >= 1.5;
              final label = Text(
                selectedCount == 0
                    ? 'لم تحدد أي فصل بعد'
                    : '${_selectedCountLabel(selectedCount)} · ${_formatBytes(selectedBytes)}',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              );
              final delete = GalaxyButton(
                key: const ValueKey('downloaded-delete-selected'),
                label: busy
                    ? 'جارٍ الحذف…'
                    : selectedCount == 0
                    ? 'حدد الفصول أولًا'
                    : 'حذف $selectedCount فصل',
                icon: Icons.delete_outline_rounded,
                variant: GalaxyActionVariant.danger,
                onPressed: busy || selectedCount == 0 ? null : onDelete,
              );
              if (compact) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    label,
                    const SizedBox(height: GalaxyMetrics.space8),
                    delete,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: label),
                  delete,
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _NoDownloadedChapterResults extends StatelessWidget {
  const _NoDownloadedChapterResults({
    required this.hasQuery,
    required this.onReset,
  });

  final bool hasQuery;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(GalaxyMetrics.space24),
        child: GalaxyAsyncState.empty(
          title: hasQuery
              ? 'لا توجد فصول محمّلة تطابق البحث'
              : 'لا توجد فصول ضمن هذا التصنيف',
          message: 'يمكنك العودة إلى عرض كل الفصول المحمّلة.',
          actionLabel: 'عرض كل الفصول',
          onAction: onReset,
        ),
      ),
    );
  }
}

class _RemovedDownloadsView extends StatelessWidget {
  const _RemovedDownloadsView({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(GalaxyMetrics.space24),
        child: GalaxyAsyncState.empty(
          title: 'لم تعد هناك فصول محمّلة لهذه الرواية',
          message: 'ربما حُذفت الفصول أثناء بقاء هذه الصفحة مفتوحة.',
          actionLabel: 'رجوع',
          onAction: onBack,
        ),
      ),
    );
  }
}

String _selectedCountLabel(int count) {
  if (count == 1) return '1 فصل محدد';
  if (count == 2) return 'فصلان محددان';
  return '$count فصول محددة';
}

String _chapterCountLabel(int count) {
  if (count == 1) return 'فصل واحد';
  if (count == 2) return 'فصلين';
  return '$count فصول';
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
