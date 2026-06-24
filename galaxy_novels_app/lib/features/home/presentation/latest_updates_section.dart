import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../data/models/chapter_summary.dart';
import '../../../data/models/novel_summary.dart';
import '../../../shared/widgets/novel_cover.dart';
import '../../../shared/widgets/novel_poster_tile.dart';
import '../../../shared/widgets/section_title.dart';

enum _LatestUpdatesView { list, grid }

const double _latestUpdateCardHeight = 150;

class LatestUpdatesSection extends StatefulWidget {
  const LatestUpdatesSection({
    required this.chapters,
    required this.novelsById,
    required this.onChapterTap,
    super.key,
  });

  final List<ChapterSummary> chapters;
  final Map<int, NovelSummary> novelsById;
  final ValueChanged<ChapterSummary> onChapterTap;

  @override
  State<LatestUpdatesSection> createState() => _LatestUpdatesSectionState();
}

class _LatestUpdatesSectionState extends State<LatestUpdatesSection> {
  _LatestUpdatesView _view = _LatestUpdatesView.list;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _LatestUpdatesHeader(
          view: _view,
          onToggle: () {
            setState(() {
              _view = _view == _LatestUpdatesView.list
                  ? _LatestUpdatesView.grid
                  : _LatestUpdatesView.list;
            });
          },
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: _view == _LatestUpdatesView.list
              ? _LatestUpdatesList(
                  key: const ValueKey('latest-list'),
                  chapters: widget.chapters,
                  novelsById: widget.novelsById,
                  onChapterTap: widget.onChapterTap,
                )
              : _LatestUpdatesGrid(
                  key: const ValueKey('latest-grid'),
                  chapters: widget.chapters,
                  novelsById: widget.novelsById,
                  onChapterTap: widget.onChapterTap,
                ),
        ),
      ],
    );
  }
}

class _LatestUpdatesHeader extends StatelessWidget {
  const _LatestUpdatesHeader({required this.view, required this.onToggle});

  final _LatestUpdatesView view;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final showingList = view == _LatestUpdatesView.list;

    return SectionTitle(
      title: 'آخر تحديثات الروايات',
      leadingIcon: Icons.update_rounded,
      action: Tooltip(
        message: showingList ? 'عرض كجرد ثلاثي' : 'عرض كقائمة',
        child: IconButton.filledTonal(
          onPressed: onToggle,
          icon: Icon(showingList ? Icons.grid_view_rounded : Icons.view_agenda),
        ),
      ),
    );
  }
}

class _LatestUpdatesList extends StatelessWidget {
  const _LatestUpdatesList({
    required this.chapters,
    required this.novelsById,
    required this.onChapterTap,
    super.key,
  });

  final List<ChapterSummary> chapters;
  final Map<int, NovelSummary> novelsById;
  final ValueChanged<ChapterSummary> onChapterTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final chapter in chapters.take(12))
          _LatestChapterTile(
            chapter: chapter,
            novel: novelsById[chapter.novelId],
            onTap: chapter.effectiveContentApi.isEmpty
                ? null
                : () => onChapterTap(chapter),
          ),
      ],
    );
  }
}

class _LatestChapterTile extends StatelessWidget {
  const _LatestChapterTile({
    required this.chapter,
    required this.novel,
    required this.onTap,
  });

  final ChapterSummary chapter;
  final NovelSummary? novel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;
    final previewChapters = chapter.visibleChapters.take(3).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: InkWell(
        key: ValueKey('latest-update-${chapter.id}'),
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Ink(
          height: _latestUpdateCardHeight,
          decoration: BoxDecoration(
            color: tokens.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: tokens.border),
          ),
          child: Row(
            children: [
              NovelCover(
                title: chapter.novelTitle,
                imageUrl: chapter.coverUrl.isNotEmpty
                    ? chapter.coverUrl
                    : novel?.coverThumbnail ?? '',
                width: 104,
                height: _latestUpdateCardHeight,
                borderRadius: 8,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        chapter.novelTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 5),
                      for (final item in previewChapters)
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: _ChapterLine(item: item),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChapterLine extends StatelessWidget {
  const _ChapterLine({required this.item});

  final ChapterSummaryItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;

    return Row(
      children: [
        Container(
          width: 30,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: tokens.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.bookmark_border_rounded,
            size: 16,
            color: tokens.primary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 76,
          child: Text(
            item.dateLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.left,
            style: theme.textTheme.labelSmall?.copyWith(
              color: tokens.textSecondary,
              height: 1.1,
            ),
          ),
        ),
      ],
    );
  }
}

class _LatestUpdatesGrid extends StatelessWidget {
  const _LatestUpdatesGrid({
    required this.chapters,
    required this.novelsById,
    required this.onChapterTap,
    super.key,
  });

  final List<ChapterSummary> chapters;
  final Map<int, NovelSummary> novelsById;
  final ValueChanged<ChapterSummary> onChapterTap;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: chapters.take(18).length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
        mainAxisExtent: NovelPosterTile.height,
      ),
      itemBuilder: (context, index) {
        final chapter = chapters[index];
        final novel = novelsById[chapter.novelId];
        return NovelPosterTile(
          key: ValueKey('latest-grid-${chapter.id}'),
          title: chapter.novelTitle,
          imageUrl: chapter.coverUrl.isNotEmpty
              ? chapter.coverUrl
              : novel?.coverThumbnail ?? '',
          statusLabel: novel?.statusLabel ?? '',
          onTap: chapter.effectiveContentApi.isEmpty
              ? null
              : () => onChapterTap(chapter),
        );
      },
    );
  }
}
