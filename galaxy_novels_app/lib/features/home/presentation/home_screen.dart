import 'package:flutter/material.dart';

import '../../../app/app_dependencies.dart';
import '../../../data/models/chapter_summary.dart';
import '../../../data/models/home_data.dart';
import '../../../data/models/novel_summary.dart';
import '../../../data/repositories/home_repository.dart';
import '../../../shared/widgets/novel_list_tile.dart';

enum _LatestUpdatesView { list, grid }

const double _posterCardWidth = 112;
const double _posterImageAspectRatio = 0.70;
const double _posterTitleGap = 7;
const double _posterTitleHeight = 36;
const double _posterCardHeight =
    (_posterCardWidth / _posterImageAspectRatio) +
    _posterTitleGap +
    _posterTitleHeight;
const double _posterGridAspectRatio = 0.54;
const double _latestUpdateCardHeight = 164;

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
              _FeaturedNovelsShelf(novels: home.recentNovels.take(6).toList()),
            if (home.continueReading != null) ...[
              const _PlainSectionHeader(title: 'أكمل القراءة'),
              _ContinueReadingTile(progress: home.continueReading!),
            ],
            if (home.recentNovels.isNotEmpty) ...[
              const _PlainSectionHeader(title: 'روايات محدثة'),
              _RecentNovelsStrip(novels: home.recentNovels),
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
                      ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _FeaturedNovelsShelf extends StatelessWidget {
  const _FeaturedNovelsShelf({required this.novels});

  final List<NovelSummary> novels;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: SizedBox(
        height: _posterCardHeight,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: novels.length,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            final novel = novels[index];
            return SizedBox(
              width: _posterCardWidth,
              child: _NovelCoverCell(
                title: novel.title,
                coverUrl: novel.coverThumbnail,
                statusLabel: novel.statusLabel,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ContinueReadingTile extends StatelessWidget {
  const _ContinueReadingTile({required this.progress});

  final ReadingProgress progress;

  @override
  Widget build(BuildContext context) {
    return NovelListTile(
      title: progress.novelTitle,
      subtitle: 'آخر قراءة: ${progress.chapterLabel}',
      meta: 'تقدم القراءة ${progress.progress}%',
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
    final previewChapters = chapter.visibleChapters.take(3).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {},
        child: Ink(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.dividerColor),
          ),
          child: SizedBox(
            height: _latestUpdateCardHeight,
            child: Row(
              children: [
                SizedBox(
                  width: _posterCardWidth,
                  height: double.infinity,
                  child: _CoverImage(
                    url: novel?.coverThumbnail ?? '',
                    borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(8),
                    ),
                    title: chapter.novelTitle,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          chapter.novelTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 8),
                        for (final item in previewChapters)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
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

    return Row(
      children: [
        Container(
          width: 32,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.bookmark_border,
            size: 17,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 86,
          child: Text(
            item.dateLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.left,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.58),
              height: 1.15,
            ),
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
    final theme = Theme.of(context);
    final showingList = view == _LatestUpdatesView.list;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 34,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'آخر تحديثات الروايات',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Tooltip(
            message: showingList ? 'عرض كجرد ثلاثي' : 'عرض كقائمة',
            child: IconButton.filledTonal(
              onPressed: onToggle,
              icon: Icon(
                showingList ? Icons.grid_view_rounded : Icons.view_agenda,
              ),
            ),
          ),
        ],
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

class _LatestUpdatesGrid extends StatelessWidget {
  const _LatestUpdatesGrid({
    required this.chapters,
    required this.novelsById,
    super.key,
  });

  final List<ChapterSummary> chapters;
  final Map<int, NovelSummary> novelsById;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: chapters.take(18).length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 14,
        childAspectRatio: _posterGridAspectRatio,
      ),
      itemBuilder: (context, index) {
        final chapter = chapters[index];
        final novel = novelsById[chapter.novelId];
        return _NovelCoverCell(
          title: chapter.novelTitle,
          coverUrl: novel?.coverThumbnail ?? '',
          statusLabel: novel?.statusLabel ?? '',
        );
      },
    );
  }
}

class _RecentNovelsStrip extends StatelessWidget {
  const _RecentNovelsStrip({required this.novels});

  final List<NovelSummary> novels;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _posterCardHeight,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: novels.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final novel = novels[index];
          return SizedBox(
            width: _posterCardWidth,
            child: _NovelCoverCell(
              title: novel.title,
              coverUrl: novel.coverThumbnail,
              statusLabel: novel.statusLabel,
            ),
          );
        },
      ),
    );
  }
}

class _NovelCoverCell extends StatelessWidget {
  const _NovelCoverCell({
    required this.title,
    required this.coverUrl,
    required this.statusLabel,
  });

  final String title;
  final String coverUrl;
  final String statusLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {},
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                _CoverImage(
                  url: coverUrl,
                  borderRadius: BorderRadius.circular(8),
                  title: title,
                ),
                if (statusLabel.isNotEmpty)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        statusLabel,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: _posterTitleGap),
          SizedBox(
            height: _posterTitleHeight,
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoverImage extends StatelessWidget {
  const _CoverImage({
    required this.url,
    required this.borderRadius,
    required this.title,
  });

  final String url;
  final BorderRadius borderRadius;
  final String title;

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = _resolveImageUrl(context, url);

    return ClipRRect(
      borderRadius: borderRadius,
      child: resolvedUrl == null
          ? _CoverFallback(title: title)
          : Image.network(
              resolvedUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _CoverFallback(title: title),
            ),
    );
  }
}

class _CoverFallback extends StatelessWidget {
  const _CoverFallback({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.12),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            title.isEmpty ? 'غلاف' : title,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w900,
              height: 1.25,
            ),
          ),
        ),
      ),
    );
  }
}

class _PlainSectionHeader extends StatelessWidget {
  const _PlainSectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 10),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w900,
        ),
      ),
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

String? _resolveImageUrl(BuildContext context, String url) {
  if (url.isEmpty) {
    return null;
  }

  try {
    return AppDependencies.of(context).config.resolve(url).toString();
  } on Object {
    return null;
  }
}
