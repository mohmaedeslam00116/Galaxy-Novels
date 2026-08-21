import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show SliverConstraints;

import '../../../data/models/chapter_summary.dart';
import '../../../data/models/novel_summary.dart';
import '../../../design_system/components/galaxy_badge.dart';
import '../../../design_system/patterns/galaxy_editorial_list.dart';
import '../../../design_system/patterns/galaxy_novel_shelf.dart';
import '../domain/home_customization.dart';
import 'home_card_appearance.dart';
import 'home_density_metrics.dart';
import 'home_novel_cover.dart';
import 'home_novel_open_request.dart';
import 'home_poster_card.dart';
import 'home_section_header.dart';

class LatestUpdatesSection extends StatelessWidget {
  const LatestUpdatesSection({
    required this.chapters,
    required this.novelsById,
    required this.onNovelTap,
    this.initialLayout = LatestUpdatesLayout.detailedList,
    this.headerStyle = HomeHeaderStyle.standard,
    this.density = HomeDensity.balanced,
    this.customization,
    this.onHeaderAction,
    this.headerActionLabel,
    this.onNovelOpen,
    super.key,
  });

  final List<ChapterSummary> chapters;
  final Map<int, NovelSummary> novelsById;
  final ValueChanged<String> onNovelTap;
  final LatestUpdatesLayout initialLayout;
  final HomeHeaderStyle headerStyle;
  final HomeDensity density;
  final HomeCustomization? customization;
  final VoidCallback? onHeaderAction;
  final String? headerActionLabel;
  final ValueChanged<HomeNovelOpenRequest>? onNovelOpen;

  HomeCustomization get effectiveCustomization =>
      customization ??
      HomeCustomization.defaults.copyWith(
        latestUpdatesLayout: initialLayout,
        headerStyle: headerStyle,
        density: density,
      );

  @override
  Widget build(BuildContext context) {
    final customization = effectiveCustomization;
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: _LatestUpdatesHeader(
            customization: customization,
            onAction: onHeaderAction,
            actionLabel: headerActionLabel,
          ),
        ),
        switch (customization.latestUpdatesLayout) {
          LatestUpdatesLayout.horizontalStrip => SliverToBoxAdapter(
            child: _LatestUpdatesStrip(
              key: const ValueKey('latest-updates-strip'),
              chapters: chapters,
              novelsById: novelsById,
              onNovelTap: onNovelTap,
              customization: customization,
              onNovelOpen: onNovelOpen,
            ),
          ),
          LatestUpdatesLayout.detailedList => _LatestUpdatesList(
            key: const ValueKey('latest-list'),
            chapters: chapters,
            novelsById: novelsById,
            onNovelTap: onNovelTap,
            customization: customization,
            onNovelOpen: onNovelOpen,
          ),
          LatestUpdatesLayout.grid => _LatestUpdatesGrid(
            key: const ValueKey('latest-grid'),
            chapters: chapters,
            novelsById: novelsById,
            onNovelTap: onNovelTap,
            customization: customization,
            onNovelOpen: onNovelOpen,
          ),
        },
      ],
    );
  }
}

class _LatestUpdatesStrip extends StatelessWidget {
  const _LatestUpdatesStrip({
    required this.chapters,
    required this.novelsById,
    required this.onNovelTap,
    required this.customization,
    this.onNovelOpen,
    super.key,
  });

  final List<ChapterSummary> chapters;
  final Map<int, NovelSummary> novelsById;
  final ValueChanged<String> onNovelTap;
  final HomeCustomization customization;
  final ValueChanged<HomeNovelOpenRequest>? onNovelOpen;

  @override
  Widget build(BuildContext context) {
    final density = customization.density;
    final size = customization.cardSizeFor(HomeSectionId.latestUpdates);
    final width = homePosterWidth(size);
    return SizedBox(
      height: homePosterExtent(size),
      child: GalaxyNovelShelf.builder(
        itemWidth: width,
        padding: EdgeInsets.symmetric(horizontal: density.horizontalPadding),
        itemCount: chapters.length,
        itemSpacing: density.itemSpacing,
        itemBuilder: (context, index) {
          final chapter = chapters[index];
          final novel = novelsById[chapter.novelId];
          final manifestPath = _manifestFor(chapter, novel);
          final heroTag = homeNovelHeroTag(
            HomeSectionId.latestUpdates,
            chapter.id,
          );
          return KeyedSubtree(
            key: ValueKey('latest-update-${chapter.id}'),
            child: HomePosterCard(
              key: ValueKey('latest-card-strip-${chapter.id}'),
              section: HomeSectionId.latestUpdates,
              customization: customization,
              heroTag: heroTag,
              content: _latestPosterContent(chapter, novel, customization),
              onTap: manifestPath.isEmpty
                  ? null
                  : () => _openNovel(chapter, novel, manifestPath, heroTag),
            ),
          );
        },
      ),
    );
  }

  void _openNovel(
    ChapterSummary chapter,
    NovelSummary? novel,
    String manifestPath,
    Object heroTag,
  ) {
    dispatchHomeNovelOpen(
      request: _latestOpenRequest(chapter, novel, manifestPath, heroTag),
      enhancedOpen: onNovelOpen,
      legacyOpen: onNovelTap,
    );
  }
}

class _LatestUpdatesHeader extends StatelessWidget {
  const _LatestUpdatesHeader({
    required this.customization,
    this.onAction,
    this.actionLabel,
  });

  final HomeCustomization customization;
  final VoidCallback? onAction;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    return HomeSectionHeader(
      key: const ValueKey('home-latest-header'),
      title: 'آخر تحديثات الروايات',
      subtitle: 'الفصول الأحدث مرتبة للوصول السريع',
      icon: Icons.schedule_rounded,
      actionLabel: actionLabel,
      onAction: onAction,
      customization: customization,
    );
  }
}

class _LatestUpdatesList extends StatelessWidget {
  const _LatestUpdatesList({
    required this.chapters,
    required this.novelsById,
    required this.onNovelTap,
    required this.customization,
    this.onNovelOpen,
    super.key,
  });

  final List<ChapterSummary> chapters;
  final Map<int, NovelSummary> novelsById;
  final ValueChanged<String> onNovelTap;
  final HomeCustomization customization;
  final ValueChanged<HomeNovelOpenRequest>? onNovelOpen;

  @override
  Widget build(BuildContext context) {
    return GalaxyEditorialSliverList(
      padding: EdgeInsets.symmetric(
        horizontal: customization.density.horizontalPadding,
      ),
      itemCount: chapters.length,
      itemBuilder: (context, index) {
        final chapter = chapters[index];
        final novel = novelsById[chapter.novelId];
        final manifestPath = _manifestFor(chapter, novel);
        final heroTag = homeNovelHeroTag(
          HomeSectionId.latestUpdates,
          chapter.id,
        );
        final template = customization.latestUpdatesTemplate;
        return Align(
          alignment: AlignmentDirectional.centerStart,
          child: SizedBox(
            key: ValueKey('latest-update-${chapter.id}'),
            width: template == LatestUpdateCardTemplate.poster
                ? _posterListWidth(customization)
                : double.infinity,
            height: _latestCardExtent(context, customization),
            child: _LatestUpdateCard(
              key: ValueKey('latest-card-${template.name}-${chapter.id}'),
              chapter: chapter,
              novel: novel,
              customization: customization,
              heroTag: heroTag,
              editorialRow: template != LatestUpdateCardTemplate.poster,
              showDivider: false,
              onTap: manifestPath.isEmpty
                  ? null
                  : () => _openNovel(chapter, novel, manifestPath, heroTag),
            ),
          ),
        );
      },
    );
  }

  void _openNovel(
    ChapterSummary chapter,
    NovelSummary? novel,
    String manifestPath,
    Object heroTag,
  ) {
    dispatchHomeNovelOpen(
      request: _latestOpenRequest(chapter, novel, manifestPath, heroTag),
      enhancedOpen: onNovelOpen,
      legacyOpen: onNovelTap,
    );
  }
}

class _LatestUpdatesGrid extends StatelessWidget {
  const _LatestUpdatesGrid({
    required this.chapters,
    required this.novelsById,
    required this.onNovelTap,
    required this.customization,
    this.onNovelOpen,
    super.key,
  });

  final List<ChapterSummary> chapters;
  final Map<int, NovelSummary> novelsById;
  final ValueChanged<String> onNovelTap;
  final HomeCustomization customization;
  final ValueChanged<HomeNovelOpenRequest>? onNovelOpen;

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(builder: _gridForConstraints);
  }

  Widget _gridForConstraints(
    BuildContext context,
    SliverConstraints constraints,
  ) {
    final density = customization.density;
    final padding = 12 * density.scale;
    final spacing = density.itemSpacing;
    final columns = _latestGridColumns(
      constraints.crossAxisExtent,
      customization,
    );
    final cardWidth =
        (constraints.crossAxisExtent - padding * 2 - spacing * (columns - 1)) /
        columns;
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: padding),
      sliver: SliverGrid.builder(
        itemCount: chapters.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          mainAxisExtent: _latestCardExtent(
            context,
            customization,
            posterWidth: cardWidth,
          ),
        ),
        itemBuilder: (context, index) {
          final chapter = chapters[index];
          final novel = novelsById[chapter.novelId];
          final manifestPath = _manifestFor(chapter, novel);
          final heroTag = homeNovelHeroTag(
            HomeSectionId.latestUpdates,
            chapter.id,
          );
          return KeyedSubtree(
            key: ValueKey('latest-grid-${chapter.id}'),
            child: _LatestUpdateCard(
              key: ValueKey(
                'latest-card-${customization.latestUpdatesTemplate.name}-${chapter.id}',
              ),
              chapter: chapter,
              novel: novel,
              customization: customization,
              heroTag: heroTag,
              onTap: manifestPath.isEmpty
                  ? null
                  : () => _openNovel(chapter, novel, manifestPath, heroTag),
            ),
          );
        },
      ),
    );
  }

  void _openNovel(
    ChapterSummary chapter,
    NovelSummary? novel,
    String manifestPath,
    Object heroTag,
  ) {
    dispatchHomeNovelOpen(
      request: _latestOpenRequest(chapter, novel, manifestPath, heroTag),
      enhancedOpen: onNovelOpen,
      legacyOpen: onNovelTap,
    );
  }
}

class HomeLatestUpdateCardPreview extends StatelessWidget {
  const HomeLatestUpdateCardPreview({
    required this.chapter,
    required this.novel,
    required this.customization,
    super.key,
  });

  final ChapterSummary chapter;
  final NovelSummary? novel;
  final HomeCustomization customization;

  @override
  Widget build(BuildContext context) {
    final template = customization.latestUpdatesTemplate;
    return SizedBox(
      width: template == LatestUpdateCardTemplate.poster
          ? _posterListWidth(customization)
          : double.infinity,
      height: _latestCardExtent(context, customization),
      child: _LatestUpdateCard(
        key: ValueKey('latest-card-${template.name}-${chapter.id}'),
        chapter: chapter,
        novel: novel,
        onTap: () {},
        customization: customization,
      ),
    );
  }
}

class _LatestUpdateCard extends StatelessWidget {
  const _LatestUpdateCard({
    required this.chapter,
    required this.novel,
    required this.onTap,
    required this.customization,
    this.editorialRow = false,
    this.showDivider = false,
    this.heroTag,
    super.key,
  });

  final ChapterSummary chapter;
  final NovelSummary? novel;
  final VoidCallback? onTap;
  final HomeCustomization customization;
  final bool editorialRow;
  final bool showDivider;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    if (customization.latestUpdatesTemplate ==
        LatestUpdateCardTemplate.poster) {
      return HomePosterCard(
        section: HomeSectionId.latestUpdates,
        customization: customization,
        content: _latestPosterContent(chapter, novel, customization),
        heroTag: heroTag,
        onTap: onTap,
      );
    }
    final content =
        customization.latestUpdatesTemplate == LatestUpdateCardTemplate.detailed
        ? _DetailedLatestContent(
            chapter: chapter,
            novel: novel,
            customization: customization,
            heroTag: heroTag,
          )
        : _CompactLatestContent(
            chapter: chapter,
            novel: novel,
            customization: customization,
            heroTag: heroTag,
          );
    if (!editorialRow) {
      return homeCardSurface(
        context: context,
        customization: customization,
        radius: customization.coverCorner.radius,
        child: InkWell(onTap: onTap, child: content),
      );
    }
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: homeCardColor(scheme, customization.cardTint),
        border: showDivider
            ? Border(
                bottom: BorderSide(
                  color: scheme.outlineVariant.withValues(alpha: 0.55),
                ),
              )
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(onTap: onTap, child: content),
      ),
    );
  }
}

class _DetailedLatestContent extends StatelessWidget {
  const _DetailedLatestContent({
    required this.chapter,
    required this.novel,
    required this.customization,
    this.heroTag,
  });

  final ChapterSummary chapter;
  final NovelSummary? novel;
  final HomeCustomization customization;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    final scale = customization.cardSizeFor(HomeSectionId.latestUpdates).scale;
    final chapters = _displayedChapters(chapter, customization);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 76 * scale,
          child: Stack(
            fit: StackFit.expand,
            children: [
              HomeNovelCover(
                section: HomeSectionId.latestUpdates,
                customization: customization,
                title: chapter.novelTitle,
                imageUrl: _bestLatestCover(chapter, novel),
                width: 76 * scale,
                height: 114 * scale,
                heroTag: heroTag,
              ),
              if (_showsStatus(customization, novel))
                PositionedDirectional(
                  top: 8,
                  start: 8,
                  child: GalaxyBadge(
                    key: ValueKey('latest-status-${chapter.id}'),
                    label: novel!.statusLabel,
                    tone: GalaxyBadgeTone.success,
                    size: GalaxyComponentSize.small,
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsetsDirectional.fromSTEB(
              13 * scale,
              13 * scale,
              13 * scale,
              13 * scale,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LatestTitle(title: chapter.novelTitle, maxLines: 2),
                SizedBox(height: 8 * scale),
                for (final item in chapters)
                  _LatestChapterRow(
                    chapter: item,
                    showDate: customization.showsField(
                      HomeSectionId.latestUpdates,
                      HomeCardField.date,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CompactLatestContent extends StatelessWidget {
  const _CompactLatestContent({
    required this.chapter,
    required this.novel,
    required this.customization,
    this.heroTag,
  });

  final ChapterSummary chapter;
  final NovelSummary? novel;
  final HomeCustomization customization;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    const section = HomeSectionId.latestUpdates;
    final scale = customization.cardSizeFor(HomeSectionId.latestUpdates).scale;
    final chapters = _displayedChapters(chapter, customization);
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        8 * scale,
        8 * scale,
        8 * scale,
        8 * scale,
      ),
      child: Row(
        children: [
          HomeNovelCover(
            section: HomeSectionId.latestUpdates,
            customization: customization,
            title: chapter.novelTitle,
            imageUrl: _bestLatestCover(chapter, novel),
            width: 52 * scale,
            height: 70 * scale,
            heroTag: heroTag,
          ),
          SizedBox(width: 10 * scale),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _LatestTitle(
                        title: chapter.novelTitle,
                        maxLines: 1,
                      ),
                    ),
                    if (_showsStatus(customization, novel)) ...[
                      const SizedBox(width: 6),
                      GalaxyBadge(
                        label: novel!.statusLabel,
                        tone: GalaxyBadgeTone.success,
                        size: GalaxyComponentSize.small,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 5),
                for (final item in chapters)
                  _LatestChapterRow(
                    chapter: item,
                    showDate: customization.showsField(
                      section,
                      HomeCardField.date,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LatestTitle extends StatelessWidget {
  const _LatestTitle({required this.title, required this.maxLines});

  final String title;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
    );
  }
}

class _LatestChapterRow extends StatelessWidget {
  const _LatestChapterRow({required this.chapter, required this.showDate});

  final ChapterSummaryItem chapter;
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              chapter.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (showDate && chapter.dateLabel.isNotEmpty) ...[
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                chapter.dateLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

HomePosterContent _latestPosterContent(
  ChapterSummary chapter,
  NovelSummary? novel,
  HomeCustomization customization,
) {
  const section = HomeSectionId.latestUpdates;
  final chapters = _displayedChapters(chapter, customization);
  final latestChapter = chapters.first;
  final metadata = <String>[
    if (customization.showsField(section, HomeCardField.secondChapter) &&
        chapters.length > 1)
      chapters[1].label,
    if (customization.showsField(section, HomeCardField.date) &&
        latestChapter.dateLabel.isNotEmpty)
      latestChapter.dateLabel,
    if (_showsStatus(customization, novel)) novel!.statusLabel,
  ];
  return HomePosterContent(
    title: chapter.novelTitle,
    imageUrl: _bestLatestCover(chapter, novel),
    badge: latestChapter.label,
    metadata: metadata.isEmpty ? null : metadata.join(' • '),
  );
}

List<ChapterSummaryItem> _displayedChapters(
  ChapterSummary chapter,
  HomeCustomization customization,
) {
  final count =
      customization.showsField(
        HomeSectionId.latestUpdates,
        HomeCardField.secondChapter,
      )
      ? 2
      : 1;
  return chapter.visibleChapters.take(count).toList(growable: false);
}

bool _showsStatus(HomeCustomization customization, NovelSummary? novel) {
  return novel != null &&
      novel.statusLabel.isNotEmpty &&
      customization.showsField(
        HomeSectionId.latestUpdates,
        HomeCardField.status,
      );
}

int _latestGridColumns(double width, HomeCustomization customization) {
  final density = customization.density;
  final size = customization.cardSizeFor(HomeSectionId.latestUpdates);
  final padding = 24 * density.scale;
  final minimumWidth = switch (customization.latestUpdatesTemplate) {
    LatestUpdateCardTemplate.detailed => 270 * size.scale,
    LatestUpdateCardTemplate.compact => 230 * size.scale,
    LatestUpdateCardTemplate.poster => homePosterWidth(size),
  };
  final columns =
      ((width - padding + density.itemSpacing) /
              (minimumWidth + density.itemSpacing))
          .floor();
  final minimumColumns =
      customization.latestUpdatesTemplate == LatestUpdateCardTemplate.poster
      ? 2
      : 1;
  return columns.clamp(minimumColumns, 5);
}

double _latestCardExtent(
  BuildContext context,
  HomeCustomization customization, {
  double? posterWidth,
}) {
  final size = customization.cardSizeFor(HomeSectionId.latestUpdates);
  final textGrowth = (MediaQuery.textScalerOf(context).scale(14) - 14)
      .clamp(0, 20)
      .toDouble();
  if (customization.latestUpdatesTemplate == LatestUpdateCardTemplate.poster) {
    return (posterWidth == null
            ? homePosterExtent(size)
            : homePosterExtentForWidth(posterWidth)) +
        textGrowth * 3;
  }
  final base =
      customization.latestUpdatesTemplate == LatestUpdateCardTemplate.detailed
      ? 136.0
      : 112.0;
  final textMultiplier =
      customization.latestUpdatesTemplate == LatestUpdateCardTemplate.detailed
      ? 6
      : 5;
  return base * size.scale + textGrowth * textMultiplier;
}

double _posterListWidth(HomeCustomization customization) {
  return homePosterWidth(
    customization.cardSizeFor(HomeSectionId.latestUpdates),
  );
}

HomeNovelOpenRequest _latestOpenRequest(
  ChapterSummary chapter,
  NovelSummary? novel,
  String manifestPath,
  Object heroTag,
) => HomeNovelOpenRequest(
  manifestPath: manifestPath,
  heroTag: heroTag,
  title: chapter.novelTitle,
  coverUrl: _bestLatestCover(chapter, novel),
);

String _bestLatestCover(ChapterSummary chapter, NovelSummary? novel) {
  if (chapter.coverLarge.isNotEmpty) {
    return chapter.coverLarge;
  }
  if (chapter.coverMedium.isNotEmpty) {
    return chapter.coverMedium;
  }
  if (novel != null && novel.bestCover.isNotEmpty) {
    return novel.bestCover;
  }
  if (chapter.coverUrl.isNotEmpty) {
    return chapter.coverUrl;
  }
  return chapter.coverThumbnail;
}

String _manifestFor(ChapterSummary chapter, NovelSummary? novel) {
  if (chapter.manifest.isNotEmpty) {
    return chapter.manifest;
  }
  if (novel != null && novel.manifest.isNotEmpty) {
    return novel.manifest;
  }
  if (chapter.novelId <= 0) {
    return '';
  }
  return '/wp-content/uploads/wor-reader-cache/app/manifest/novel-${chapter.novelId}.json';
}
