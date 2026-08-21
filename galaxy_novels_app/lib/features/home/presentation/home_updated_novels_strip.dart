import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show SliverConstraints;

import '../../../data/models/novel_summary.dart';
import '../../../design_system/components/galaxy_badge.dart';
import '../../../design_system/patterns/galaxy_adaptive_novel_collection.dart';
import '../domain/home_customization.dart';
import 'home_card_appearance.dart';
import 'home_density_metrics.dart';
import 'home_novel_cover.dart';
import 'home_novel_open_request.dart';
import 'home_poster_card.dart';

class HomeUpdatedNovelsStrip extends StatelessWidget {
  const HomeUpdatedNovelsStrip({
    required this.novels,
    required this.onNovelTap,
    this.onNovelOpen,
    this.density = HomeDensity.balanced,
    this.customization,
    super.key,
  });

  final List<NovelSummary> novels;
  final ValueChanged<String> onNovelTap;
  final ValueChanged<HomeNovelOpenRequest>? onNovelOpen;
  final HomeDensity density;
  final HomeCustomization? customization;

  @override
  Widget build(BuildContext context) {
    final effective =
        customization ?? HomeCustomization.defaults.copyWith(density: density);
    final template = effective.updatedNovelsTemplate;
    final size = effective.cardSizeFor(HomeSectionId.updatedNovels);
    final textGrowth = template == UpdatedNovelCardTemplate.horizontal
        ? (MediaQuery.textScalerOf(context).scale(14) - 14)
              .clamp(0, 20)
              .toDouble()
        : 0.0;
    final singleTextGrowth = (MediaQuery.textScalerOf(context).scale(14) - 14)
        .clamp(0, 20)
        .toDouble();
    final singleCustomization = effective.copyWith(
      updatedNovelsTemplate: UpdatedNovelCardTemplate.horizontal,
    );
    return KeyedSubtree(
      key: const ValueKey('updated-novels-strip'),
      child: GalaxyAdaptiveNovelCollection(
        itemCount: novels.length,
        itemWidth: _updatedCardWidth(template, size),
        itemExtent: _updatedCardExtent(template, size) + textGrowth * 3,
        singleItemExtent:
            _updatedCardExtent(UpdatedNovelCardTemplate.horizontal, size) +
            singleTextGrowth * 3,
        padding: EdgeInsets.symmetric(
          horizontal: effective.density.horizontalPadding,
        ),
        itemSpacing: effective.density.itemSpacing,
        itemBuilder: (context, index) {
          final novel = novels[index];
          final heroTag = homeNovelHeroTag(
            HomeSectionId.updatedNovels,
            novel.id,
          );
          return _UpdatedNovelCard(
            key: ValueKey('updated-card-${template.name}-${novel.id}'),
            novel: novel,
            customization: effective,
            heroTag: heroTag,
            onTap: novel.manifest.isEmpty
                ? null
                : () => _openNovel(novel, heroTag),
          );
        },
        singleItemBuilder: (context) {
          final novel = novels.single;
          final heroTag = homeNovelHeroTag(
            HomeSectionId.updatedNovels,
            novel.id,
          );
          return _UpdatedNovelCard(
            key: ValueKey(
              'updated-card-${UpdatedNovelCardTemplate.horizontal.name}-${novel.id}',
            ),
            novel: novel,
            customization: singleCustomization,
            heroTag: heroTag,
            onTap: novel.manifest.isEmpty
                ? null
                : () => _openNovel(novel, heroTag),
          );
        },
      ),
    );
  }

  void _openNovel(NovelSummary novel, Object heroTag) {
    dispatchHomeNovelOpen(
      request: _updatedNovelRequest(novel, heroTag),
      enhancedOpen: onNovelOpen,
      legacyOpen: onNovelTap,
    );
  }
}

class HomeUpdatedNovelsGrid extends StatelessWidget {
  const HomeUpdatedNovelsGrid({
    required this.novels,
    required this.onNovelTap,
    this.onNovelOpen,
    this.density = HomeDensity.balanced,
    this.customization,
    super.key,
  });

  final List<NovelSummary> novels;
  final ValueChanged<String> onNovelTap;
  final ValueChanged<HomeNovelOpenRequest>? onNovelOpen;
  final HomeDensity density;
  final HomeCustomization? customization;

  @override
  Widget build(BuildContext context) {
    final effective =
        customization ?? HomeCustomization.defaults.copyWith(density: density);
    if (novels.length == 1) {
      return SliverToBoxAdapter(
        child: HomeUpdatedNovelsStrip(
          novels: novels,
          onNovelTap: onNovelTap,
          onNovelOpen: onNovelOpen,
          density: density,
          customization: effective,
        ),
      );
    }
    return SliverLayoutBuilder(
      builder: (context, constraints) =>
          _gridFor(context, constraints, effective),
    );
  }

  Widget _gridFor(
    BuildContext context,
    SliverConstraints constraints,
    HomeCustomization customization,
  ) {
    final template = customization.updatedNovelsTemplate;
    final size = customization.cardSizeFor(HomeSectionId.updatedNovels);
    final spacing = customization.density.itemSpacing;
    final padding = customization.density.horizontalPadding;
    final columns = _updatedGridColumns(
      constraints.crossAxisExtent,
      customization,
    );
    final cardWidth =
        (constraints.crossAxisExtent - padding * 2 - spacing * (columns - 1)) /
        columns;
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: padding),
      sliver: SliverGrid.builder(
        key: const ValueKey('updated-novels-grid'),
        itemCount: novels.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          mainAxisExtent:
              (template == UpdatedNovelCardTemplate.poster ||
                      template == UpdatedNovelCardTemplate.coverOnly
                  ? homePosterExtentForWidth(cardWidth)
                  : _updatedCardExtent(template, size)) +
              (template == UpdatedNovelCardTemplate.horizontal
                  ? (MediaQuery.textScalerOf(context).scale(14) - 14)
                            .clamp(0, 20)
                            .toDouble() *
                        3
                  : 0),
        ),
        itemBuilder: (context, index) {
          final novel = novels[index];
          final heroTag = homeNovelHeroTag(
            HomeSectionId.updatedNovels,
            novel.id,
          );
          return _UpdatedNovelCard(
            key: ValueKey('updated-card-${template.name}-${novel.id}'),
            novel: novel,
            customization: customization,
            heroTag: heroTag,
            onTap: novel.manifest.isEmpty
                ? null
                : () => _openNovel(novel, heroTag),
          );
        },
      ),
    );
  }

  void _openNovel(NovelSummary novel, Object heroTag) {
    dispatchHomeNovelOpen(
      request: _updatedNovelRequest(novel, heroTag),
      enhancedOpen: onNovelOpen,
      legacyOpen: onNovelTap,
    );
  }
}

class _UpdatedNovelCard extends StatelessWidget {
  const _UpdatedNovelCard({
    required this.novel,
    required this.onTap,
    required this.customization,
    this.heroTag,
    super.key,
  });

  final NovelSummary novel;
  final VoidCallback? onTap;
  final HomeCustomization customization;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    return switch (customization.updatedNovelsTemplate) {
      UpdatedNovelCardTemplate.poster => HomePosterCard(
        section: HomeSectionId.updatedNovels,
        customization: customization,
        content: _posterContent(novel, customization),
        heroTag: heroTag,
        onTap: onTap,
      ),
      UpdatedNovelCardTemplate.coverOnly => HomePosterCard(
        section: HomeSectionId.updatedNovels,
        customization: customization,
        content: _posterContent(novel, customization, minimal: true),
        heroTag: heroTag,
        onTap: onTap,
      ),
      UpdatedNovelCardTemplate.horizontal => homeCardSurface(
        context: context,
        customization: customization,
        radius: customization.coverCorner.radius,
        child: InkWell(
          onTap: onTap,
          child: _HorizontalCardContent(
            novel: novel,
            customization: customization,
            heroTag: heroTag,
          ),
        ),
      ),
    };
  }
}

class _HorizontalCardContent extends StatelessWidget {
  const _HorizontalCardContent({
    required this.novel,
    required this.customization,
    this.heroTag,
  });

  final NovelSummary novel;
  final HomeCustomization customization;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    final scale = customization.cardSizeFor(HomeSectionId.updatedNovels).scale;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 92 * scale,
          child: LayoutBuilder(
            builder: (context, constraints) => HomeNovelCover(
              section: HomeSectionId.updatedNovels,
              customization: customization,
              title: novel.title,
              imageUrl: novel.bestCover,
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              heroTag: heroTag,
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsetsDirectional.fromSTEB(
              12 * scale,
              10 * scale,
              12 * scale,
              10 * scale,
            ),
            child: _UpdatedNovelDetails(
              novel: novel,
              customization: customization,
              titleLines: 2,
            ),
          ),
        ),
      ],
    );
  }
}

class _UpdatedNovelDetails extends StatelessWidget {
  const _UpdatedNovelDetails({
    required this.novel,
    required this.customization,
    required this.titleLines,
  });

  final NovelSummary novel;
  final HomeCustomization customization;
  final int titleLines;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final section = HomeSectionId.updatedNovels;
    final metadata = _updatedMetadata(novel, customization);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          novel.title,
          maxLines: titleLines,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        if (metadata.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            metadata.join(' • '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
        if (customization.showsField(section, HomeCardField.status) &&
            novel.statusLabel.isNotEmpty) ...[
          const SizedBox(height: 5),
          GalaxyBadge(
            label: novel.statusLabel,
            tone: GalaxyBadgeTone.success,
            size: GalaxyComponentSize.small,
          ),
        ],
      ],
    );
  }
}

HomePosterContent _posterContent(
  NovelSummary novel,
  HomeCustomization customization, {
  bool minimal = false,
}) {
  const section = HomeSectionId.updatedNovels;
  final showsChapters = customization.showsField(
    section,
    HomeCardField.chapterCount,
  );
  final showsStatus = customization.showsField(section, HomeCardField.status);
  final badge = showsChapters && novel.chaptersCount > 0
      ? '${novel.chaptersCount}'
      : showsStatus && novel.statusLabel.isNotEmpty
      ? novel.statusLabel
      : null;
  final metadata = <String>[
    if (!minimal &&
        showsStatus &&
        showsChapters &&
        novel.statusLabel.isNotEmpty)
      novel.statusLabel,
    if (!minimal &&
        customization.showsField(section, HomeCardField.firstGenre) &&
        novel.genres.isNotEmpty)
      novel.genres.first,
  ];
  return HomePosterContent(
    title: novel.title,
    imageUrl: novel.bestCover,
    badge: badge,
    metadata: metadata.isEmpty ? null : metadata.join(' • '),
  );
}

List<String> _updatedMetadata(
  NovelSummary novel,
  HomeCustomization customization,
) {
  const section = HomeSectionId.updatedNovels;
  return [
    if (customization.showsField(section, HomeCardField.chapterCount) &&
        novel.chaptersCount > 0)
      '${novel.chaptersCount} فصل',
    if (customization.showsField(section, HomeCardField.firstGenre) &&
        novel.genres.isNotEmpty)
      novel.genres.first,
  ];
}

int _updatedGridColumns(double width, HomeCustomization customization) {
  final density = customization.density;
  final size = customization.cardSizeFor(HomeSectionId.updatedNovels);
  final usableWidth = width - density.horizontalPadding * 2;
  if (customization.updatedNovelsTemplate ==
      UpdatedNovelCardTemplate.horizontal) {
    final columns = (usableWidth / (300 * size.scale)).floor();
    return columns.clamp(1, 4);
  }
  final minimumCardWidth = homePosterWidth(size);
  final columns =
      ((usableWidth + density.itemSpacing) /
              (minimumCardWidth + density.itemSpacing))
          .floor();
  return columns.clamp(2, 5);
}

double _updatedCardWidth(UpdatedNovelCardTemplate template, HomeCardSize size) {
  return switch (template) {
    UpdatedNovelCardTemplate.poster ||
    UpdatedNovelCardTemplate.coverOnly => homePosterWidth(size),
    UpdatedNovelCardTemplate.horizontal => 300 * size.scale,
  };
}

double _updatedCardExtent(
  UpdatedNovelCardTemplate template,
  HomeCardSize size,
) {
  return switch (template) {
    UpdatedNovelCardTemplate.poster ||
    UpdatedNovelCardTemplate.coverOnly => homePosterExtent(size),
    UpdatedNovelCardTemplate.horizontal => 176 * size.scale,
  };
}

HomeNovelOpenRequest _updatedNovelRequest(NovelSummary novel, Object heroTag) =>
    HomeNovelOpenRequest(
      manifestPath: novel.manifest,
      heroTag: heroTag,
      title: novel.title,
      coverUrl: novel.bestCover,
    );
