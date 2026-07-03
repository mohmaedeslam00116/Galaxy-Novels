import 'package:flutter/material.dart';

import '../../../../app/app_dependencies.dart';
import '../../../../app/app_theme.dart';
import '../../../../data/models/novel_details_data.dart';
import '../../../../data/repositories/downloads_repository.dart';
import '../../../../data/repositories/novel_repository.dart';
import '../../../../shared/widgets/section_title.dart';
import '../../../downloads/application/download_manager.dart';
import '../../../downloads/presentation/chapter_download_button.dart';
import '../../../rewards/application/reader_rewards_repository.dart';
import '../../../vip/application/vip_chapters_controller.dart';
import '../../../vip/domain/vip_chapter.dart';
import '../../domain/readable_chapter.dart';
import '../all_chapters_screen.dart';
import '../visible_chapter_count.dart';
import 'readable_chapter_tile.dart';

class NovelChaptersSection extends StatefulWidget {
  const NovelChaptersSection({
    required this.result,
    required this.vipController,
    required this.canReadPrivate,
    required this.isVipDirectContentRouteAvailable,
    required this.onRead,
    required this.onOpenVipChapter,
    required this.onDownloadChapters,
    super.key,
  });

  final NovelDetailsLoadResult result;
  final VipChaptersController vipController;
  final bool canReadPrivate;
  final bool isVipDirectContentRouteAvailable;
  final void Function(NovelChapter chapter, String novelTitle) onRead;
  final void Function(String contentApi, String title) onOpenVipChapter;
  final VoidCallback onDownloadChapters;

  @override
  State<NovelChaptersSection> createState() => _NovelChaptersSectionState();
}

class _NovelChaptersSectionState extends State<NovelChaptersSection> {
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
        final previewChapters = chapterPageItems(chapters, 0);
        final canShowAll =
            chapters.length > chaptersPerPage ||
            (widget.canReadPrivate &&
                vipState.status == VipChaptersStatus.ready &&
                vipState.hasMore);

        return SliverMainAxisGroup(
          slivers: [
            SliverToBoxAdapter(
              child: SectionTitle(
                title: 'الفصول',
                leadingIcon: Icons.menu_book_outlined,
                action: widget.result.chapters.isEmpty
                    ? null
                    : TextButton.icon(
                        onPressed: widget.onDownloadChapters,
                        icon: const Icon(Icons.download_outlined),
                        label: const Text('تحميل الفصول'),
                      ),
              ),
            ),
            if (widget.result.chaptersError != null)
              SliverToBoxAdapter(
                child: _InlineMessage(
                  title: 'تعذر تحميل الفصول الآن',
                  subtitle: widget.result.chaptersError,
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

  List<VipChapter> _vipChaptersFor(VipChaptersState state) {
    if (!widget.canReadPrivate || state.status != VipChaptersStatus.ready) {
      return const [];
    }
    return state.chapters;
  }

  void _openAllChapters() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => AllChaptersScreen(
          result: widget.result,
          vipController: widget.vipController,
          canReadPrivate: widget.canReadPrivate,
          isVipDirectContentRouteAvailable:
              widget.isVipDirectContentRouteAvailable,
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
    final dependencies = AppDependencies.of(context);
    final downloadsRepository = dependencies.downloadsRepository;
    final downloadManager = dependencies.downloadManager;

    return ValueListenableBuilder<DownloadsState>(
      valueListenable: downloadsRepository.state,
      builder: (context, downloadsState, _) {
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final chapter = chapters[index];
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
                onTap: () => _openChapter(context, index),
              );
            },
            childCount: chapters.length,
            addAutomaticKeepAlives: false,
          ),
        );
      },
    );
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
          novelId: result.details.id,
          novelTitle: result.details.title,
          novelCover: result.details.bestCover,
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
    } on InsufficientDownloadPointsException {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('رصيد النقاط لا يكفي لتحميل هذا الفصل')),
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

  void _openChapter(BuildContext context, int index) {
    final chapter = chapters[index];
    if (chapter.isVip) {
      final contentApi = readableChapterOpenContentApi(
        chapters,
        index,
        directVipChapterRouteAvailable: isVipDirectContentRouteAvailable,
      );
      if (contentApi.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('قراءة هذا الفصل تحتاج تحديث مسار VIP في السيرفر.'),
          ),
        );
        return;
      }
      onOpenVipChapter(contentApi, chapter.label);
      return;
    }
    final publicChapter = chapter.publicChapter;
    if (publicChapter != null && publicChapter.effectiveContentApi.isNotEmpty) {
      onRead(publicChapter, result.details.title);
    }
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
    final tokens = theme.extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;

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
  const _InlineMessage({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;

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
