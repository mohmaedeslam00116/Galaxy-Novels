import 'package:flutter/material.dart';

import '../../../app/app_dependencies.dart';
import '../../../app/app_theme.dart';
import '../../../data/models/chapter_summary.dart';
import '../../../data/models/home_data.dart';
import '../../../data/models/novel_summary.dart';
import '../../../data/repositories/home_repository.dart';
import '../../../shared/widgets/novel_cover.dart';
import '../../../shared/widgets/novel_list_row.dart';
import '../../../shared/widgets/novel_poster_tile.dart';
import '../../../shared/widgets/section_title.dart';
import '../../novel_details/presentation/novel_details_screen.dart';

enum _LatestUpdatesView { list, grid }

const double _latestUpdateCardHeight = 150;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  HomeRepository? _repository;
  Future<HomeData>? _homeFuture;
  _LatestUpdatesView _latestUpdatesView = _LatestUpdatesView.list;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final repository = AppDependencies.of(context).homeRepository;
    if (_repository != repository) {
      _repository = repository;
      _homeFuture = repository.loadHome();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<HomeData>(
      future: _homeFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _HomeStateMessage(message: 'جار تحميل الرئيسية...');
        }

        if (snapshot.hasError) {
          return const _HomeStateMessage(message: 'تعذر تحميل الرئيسية الآن');
        }

        final home = snapshot.data;
        if (home == null || home.isEmpty) {
          return const _HomeStateMessage(message: 'لا توجد بيانات للعرض');
        }

        final novelsById = {
          for (final novel in home.recentNovels) novel.id: novel,
        };

        return ListView(
          padding: const EdgeInsets.only(bottom: 28),
          children: [
            if (home.recentNovels.isNotEmpty)
              _FeaturedNovelsShelf(
                novels: home.recentNovels.take(8).toList(),
                onNovelTap: _openNovelDetails,
              ),
            if (home.continueReading != null) ...[
              const SectionTitle(
                title: 'أكمل القراءة',
                leadingIcon: Icons.play_circle_outline_rounded,
              ),
              _ContinueReadingTile(progress: home.continueReading!),
            ],
            if (home.recentNovels.isNotEmpty) ...[
              const SectionTitle(
                title: 'روايات محدثة',
                leadingIcon: Icons.auto_stories_outlined,
              ),
              _RecentNovelsStrip(
                novels: home.recentNovels,
                onNovelTap: _openNovelDetails,
              ),
            ],
            if (home.latestChapters.isNotEmpty) ...[
              _LatestUpdatesHeader(
                view: _latestUpdatesView,
                onToggle: () {
                  setState(() {
                    _latestUpdatesView =
                        _latestUpdatesView == _LatestUpdatesView.list
                        ? _LatestUpdatesView.grid
                        : _LatestUpdatesView.list;
                  });
                },
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: _latestUpdatesView == _LatestUpdatesView.list
                    ? _LatestUpdatesList(
                        key: const ValueKey('latest-list'),
                        chapters: home.latestChapters,
                        novelsById: novelsById,
                      )
                    : _LatestUpdatesGrid(
                        key: const ValueKey('latest-grid'),
                        chapters: home.latestChapters,
                        novelsById: novelsById,
                        onNovelTap: _openNovelDetails,
                      ),
              ),
            ],
          ],
        );
      },
    );
  }

  void _openNovelDetails(String manifestPath) {
    if (manifestPath.isEmpty) {
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => NovelDetailsScreen(manifestPath: manifestPath),
      ),
    );
  }
}

class _FeaturedNovelsShelf extends StatelessWidget {
  const _FeaturedNovelsShelf({required this.novels, required this.onNovelTap});

  final List<NovelSummary> novels;
  final ValueChanged<String> onNovelTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 216,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
        scrollDirection: Axis.horizontal,
        itemCount: novels.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final novel = novels[index];
          return FeaturedPosterTile(
            title: novel.title,
            imageUrl: novel.coverThumbnail,
            statusLabel: index == 0 ? 'مختارة' : novel.statusLabel,
            onTap: novel.manifest.isEmpty
                ? null
                : () => onNovelTap(novel.manifest),
          );
        },
      ),
    );
  }
}

class _ContinueReadingTile extends StatelessWidget {
  const _ContinueReadingTile({required this.progress});

  final ReadingProgress progress;

  @override
  Widget build(BuildContext context) {
    return NovelListRow(
      title: progress.novelTitle,
      subtitle: progress.chapterLabel,
      meta: 'تقدم القراءة ${progress.progress}%',
      leadingLabel: '${progress.progress}%',
    );
  }
}

class _RecentNovelsStrip extends StatelessWidget {
  const _RecentNovelsStrip({required this.novels, required this.onNovelTap});

  final List<NovelSummary> novels;
  final ValueChanged<String> onNovelTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: NovelPosterTile.height,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: novels.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final novel = novels[index];
          return NovelPosterTile(
            title: novel.title,
            imageUrl: novel.coverThumbnail,
            statusLabel: novel.statusLabel,
            onTap: novel.manifest.isEmpty
                ? null
                : () => onNovelTap(novel.manifest),
          );
        },
      ),
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
    super.key,
  });

  final List<ChapterSummary> chapters;
  final Map<int, NovelSummary> novelsById;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final chapter in chapters.take(12))
          _LatestChapterTile(
            chapter: chapter,
            novel: novelsById[chapter.novelId],
          ),
      ],
    );
  }
}

class _LatestChapterTile extends StatelessWidget {
  const _LatestChapterTile({required this.chapter, required this.novel});

  final ChapterSummary chapter;
  final NovelSummary? novel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;
    final previewChapters = chapter.visibleChapters.take(3).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {},
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
                imageUrl: novel?.coverThumbnail ?? '',
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
    required this.onNovelTap,
    super.key,
  });

  final List<ChapterSummary> chapters;
  final Map<int, NovelSummary> novelsById;
  final ValueChanged<String> onNovelTap;

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
          title: chapter.novelTitle,
          imageUrl: novel?.coverThumbnail ?? '',
          statusLabel: novel?.statusLabel ?? '',
          onTap: novel == null || novel.manifest.isEmpty
              ? null
              : () => onNovelTap(novel.manifest),
        );
      },
    );
  }
}

class _HomeStateMessage extends StatelessWidget {
  const _HomeStateMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}
