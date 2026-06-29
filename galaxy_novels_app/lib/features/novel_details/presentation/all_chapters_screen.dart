import 'package:flutter/material.dart';

import '../../../app/app_dependencies.dart';
import '../../../app/app_theme.dart';
import '../../../data/models/novel_details_data.dart';
import '../../../data/repositories/downloads_repository.dart';
import '../../../data/repositories/novel_repository.dart';
import '../../downloads/application/download_manager.dart';
import '../../downloads/presentation/chapter_download_button.dart';
import '../../reader/presentation/reader_screen.dart';
import '../../vip/application/vip_chapters_controller.dart';
import '../../vip/domain/vip_chapter.dart';
import '../domain/readable_chapter.dart';
import 'widgets/readable_chapter_tile.dart';

class AllChaptersScreen extends StatefulWidget {
  const AllChaptersScreen({
    required this.result,
    required this.vipController,
    required this.canReadPrivate,
    super.key,
  });

  final NovelDetailsLoadResult result;
  final VipChaptersController vipController;
  final bool canReadPrivate;

  @override
  State<AllChaptersScreen> createState() => _AllChaptersScreenState();
}

class _AllChaptersScreenState extends State<AllChaptersScreen> {
  final ScrollController _listController = ScrollController();
  int _pageIndex = 0;

  @override
  void initState() {
    super.initState();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dependencies = AppDependencies.of(context);
    final downloadsRepository = dependencies.downloadsRepository;
    final downloadManager = dependencies.downloadManager;

    return Scaffold(
      appBar: AppBar(title: const Text('كل الفصول')),
      body: SafeArea(
        child: ValueListenableBuilder<VipChaptersState>(
          valueListenable: widget.vipController,
          builder: (context, vipState, _) {
            final chapters = mergeReadableChapters(
              publicChapters: widget.result.chapters,
              vipChapters: _vipChaptersFor(vipState),
            );
            final pageCount = chapterPageCount(chapters);
            final pageIndex = pageCount == 0
                ? 0
                : _pageIndex.clamp(0, pageCount - 1);
            final pageItems = chapterPageItems(chapters, pageIndex);

            return ValueListenableBuilder<DownloadsState>(
              valueListenable: downloadsRepository.state,
              builder: (context, downloadsState, _) {
                if (chapters.isEmpty) {
                  return const _EmptyChaptersView();
                }

                return Column(
                  children: [
                    _ChapterPager(
                      pageIndex: pageIndex,
                      pageCount: pageCount,
                      totalCount: chapters.length,
                      onSelected: _selectPage,
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: _listController,
                        padding: const EdgeInsets.only(bottom: 16),
                        itemCount:
                            pageItems.length + _moreVipButtonCount(vipState),
                        itemBuilder: (context, index) {
                          if (index == pageItems.length) {
                            return _LoadMoreVipButton(
                              isLoading: vipState.isLoadingMore,
                              onPressed: widget.vipController.loadMore,
                            );
                          }

                          final chapter = pageItems[index];
                          return ReadableChapterTile(
                            chapter: chapter,
                            trailingAction: chapter.isVip
                                ? null
                                : _downloadAction(
                                    context,
                                    downloadsState,
                                    downloadManager,
                                    chapter,
                                  ),
                            onTap: () => _openChapter(chapter),
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

  Widget _downloadAction(
    BuildContext context,
    DownloadsState downloadsState,
    DownloadManager downloadManager,
    ReadableChapter chapter,
  ) {
    final publicChapter = chapter.publicChapter;
    if (publicChapter == null) {
      return const SizedBox.shrink();
    }
    return ChapterDownloadButton(
      isDownloaded: downloadsState.contains(publicChapter.effectiveContentApi),
      isEnabled: publicChapter.effectiveContentApi.isNotEmpty,
      onPressed: () =>
          _downloadChapter(context, downloadManager, publicChapter),
    );
  }

  Future<void> _downloadChapter(
    BuildContext context,
    DownloadManager manager,
    NovelChapter chapter,
  ) async {
    try {
      await manager.downloadChapter(
        ChapterDownloadRequest(
          novelId: widget.result.details.id,
          novelTitle: widget.result.details.title,
          novelCover: widget.result.details.bestCover,
          chapter: chapter,
        ),
      );
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم تحميل الفصل')));
      }
    } on DownloadJobInProgressException {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('يوجد تنزيل جار بالفعل')));
      }
    } on DownloadLimitExceededException {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('وصلت إلى حد 100 فصل محمل')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر تحميل الفصل، حاول مجددا')),
        );
      }
    }
  }

  void _openChapter(ReadableChapter chapter) {
    if (chapter.contentApi.isEmpty) {
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ReaderScreen(
          contentApi: chapter.contentApi,
          chapterTitle: chapter.label,
          novelTitle: widget.result.details.title,
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

class _ChapterPager extends StatelessWidget {
  const _ChapterPager({
    required this.pageIndex,
    required this.pageCount,
    required this.totalCount,
    required this.onSelected,
  });

  final int pageIndex;
  final int pageCount;
  final int totalCount;
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
                        'الفصول $startNumber-$endNumber من $totalCount',
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
