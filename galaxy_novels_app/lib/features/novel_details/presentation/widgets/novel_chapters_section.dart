import 'package:flutter/material.dart';

import '../../../../app/app_dependencies.dart';
import '../../../../app/app_theme.dart';
import '../../../../data/models/novel_details_data.dart';
import '../../../../data/repositories/downloads_repository.dart';
import '../../../../data/repositories/novel_repository.dart';
import '../../../../shared/widgets/section_title.dart';
import '../../../downloads/application/download_manager.dart';
import '../../../downloads/presentation/chapter_download_button.dart';
import '../../domain/chapter_search_index.dart';
import 'novel_chapter_tile.dart';

class NovelChaptersSection extends StatefulWidget {
  const NovelChaptersSection({
    required this.result,
    required this.onRead,
    required this.onDownloadChapters,
    super.key,
  });

  final NovelDetailsLoadResult result;
  final void Function(NovelChapter chapter, String novelTitle) onRead;
  final VoidCallback onDownloadChapters;

  @override
  State<NovelChaptersSection> createState() => _NovelChaptersSectionState();
}

class _NovelChaptersSectionState extends State<NovelChaptersSection> {
  final _searchController = TextEditingController();
  late ChapterSearchIndex _searchIndex;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchIndex = ChapterSearchIndex(widget.result.chapters);
  }

  @override
  void didUpdateWidget(covariant NovelChaptersSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.result != widget.result) {
      _searchIndex = ChapterSearchIndex(widget.result.chapters);
      _searchController.clear();
      _query = '';
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chapters = widget.result.chapters;
    final filteredChapters = _searchIndex.search(_query);

    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: SectionTitle(
            title: 'آخر الفصول',
            leadingIcon: Icons.menu_book_outlined,
            action: chapters.isEmpty
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
          SliverToBoxAdapter(
            child: _ChapterSearchToolbar(
              controller: _searchController,
              resultCount: filteredChapters.length,
              isFiltering: _query.trim().isNotEmpty,
              onChanged: (value) => setState(() => _query = value),
              onClear: _clearSearch,
            ),
          ),
          if (filteredChapters.isEmpty)
            const SliverToBoxAdapter(
              child: _InlineMessage(
                title: 'لا توجد فصول مطابقة',
                subtitle: 'جرّب رقم فصل أو كلمة أخرى من العنوان',
              ),
            )
          else
            _ChapterSliverList(
              result: widget.result,
              chapters: filteredChapters,
              onRead: widget.onRead,
            ),
        ],
      ],
    );
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _query = '');
  }
}

class _ChapterSliverList extends StatelessWidget {
  const _ChapterSliverList({
    required this.result,
    required this.chapters,
    required this.onRead,
  });

  final NovelDetailsLoadResult result;
  final List<NovelChapter> chapters;
  final void Function(NovelChapter chapter, String novelTitle) onRead;

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
              return NovelChapterTile(
                chapter: chapter,
                trailingAction: ChapterDownloadButton(
                  isDownloaded: downloadsState.contains(
                    chapter.effectiveContentApi,
                  ),
                  isEnabled: chapter.effectiveContentApi.isNotEmpty,
                  onPressed: () =>
                      _downloadChapter(context, downloadManager, chapter),
                ),
                onTap: () {
                  if (chapter.effectiveContentApi.isNotEmpty) {
                    onRead(chapter, result.details.title);
                  }
                },
              );
            },
            childCount: chapters.length,
            addAutomaticKeepAlives: false,
          ),
        );
      },
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
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر تحميل الفصل، حاول مجددا')),
        );
      }
    }
  }
}

class _ChapterSearchToolbar extends StatelessWidget {
  const _ChapterSearchToolbar({
    required this.controller,
    required this.resultCount,
    required this.isFiltering,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final int resultCount;
  final bool isFiltering;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            key: const ValueKey('chapter-search-field'),
            controller: controller,
            onChanged: onChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'ابحث برقم الفصل أو عنوانه',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: isFiltering
                  ? IconButton(
                      key: const ValueKey('clear-chapter-search'),
                      tooltip: 'مسح البحث',
                      onPressed: onClear,
                      icon: const Icon(Icons.close_rounded),
                    )
                  : null,
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
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isFiltering ? '$resultCount نتيجة' : '$resultCount فصل',
            key: const ValueKey('chapter-search-count'),
            style: theme.textTheme.labelMedium?.copyWith(
              color: tokens.textSecondary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
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
