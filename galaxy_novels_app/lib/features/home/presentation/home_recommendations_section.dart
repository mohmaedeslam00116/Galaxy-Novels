import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show SliverConstraints;

import '../../../design_system/patterns/galaxy_adaptive_novel_collection.dart';
import '../domain/home_customization.dart';
import '../domain/home_recommendations.dart';
import 'home_card_appearance.dart';
import 'home_density_metrics.dart';
import 'home_novel_cover.dart';
import 'home_novel_open_request.dart';
import 'home_poster_card.dart';

class HomeRecommendationsStrip extends StatelessWidget {
  const HomeRecommendationsStrip({
    required this.items,
    required this.customization,
    required this.onOpen,
    required this.onHide,
    this.onNovelOpen,
    super.key,
  });

  final List<HomeRecommendation> items;
  final HomeCustomization customization;
  final ValueChanged<HomeRecommendation> onOpen;
  final ValueChanged<HomeRecommendation> onHide;
  final ValueChanged<HomeNovelOpenRequest>? onNovelOpen;

  @override
  Widget build(BuildContext context) {
    final template = customization.recommendedNovelsTemplate;
    final size = customization.cardSizeFor(HomeSectionId.becauseYouRead);
    final textGrowth = template == RecommendedNovelCardTemplate.horizontal
        ? (MediaQuery.textScalerOf(context).scale(14) - 14)
              .clamp(0, 24)
              .toDouble()
        : 0.0;
    final singleTextGrowth = (MediaQuery.textScalerOf(context).scale(14) - 14)
        .clamp(0, 24)
        .toDouble();
    final singleCustomization = customization.copyWith(
      recommendedNovelsTemplate: RecommendedNovelCardTemplate.horizontal,
    );
    return KeyedSubtree(
      key: const ValueKey('home-recommendations-strip'),
      child: GalaxyAdaptiveNovelCollection(
        itemCount: items.length,
        itemWidth: _cardWidth(template, size),
        itemExtent: _cardExtent(template, size) + textGrowth * 3,
        singleItemExtent:
            _cardExtent(RecommendedNovelCardTemplate.horizontal, size) +
            singleTextGrowth * 3,
        padding: EdgeInsets.symmetric(
          horizontal: customization.density.horizontalPadding,
        ),
        itemSpacing: customization.density.itemSpacing,
        itemBuilder: (context, index) => HomeRecommendationCard(
          recommendation: items[index],
          customization: customization,
          onOpen: () => onOpen(items[index]),
          onNovelOpen: onNovelOpen,
          onHide: () => onHide(items[index]),
        ),
        singleItemBuilder: (context) => HomeRecommendationCard(
          recommendation: items.single,
          customization: singleCustomization,
          onOpen: () => onOpen(items.single),
          onNovelOpen: onNovelOpen,
          onHide: () => onHide(items.single),
        ),
      ),
    );
  }
}

class HomeRecommendationsGrid extends StatelessWidget {
  const HomeRecommendationsGrid({
    required this.items,
    required this.customization,
    required this.onOpen,
    required this.onHide,
    this.onNovelOpen,
    super.key,
  });

  final List<HomeRecommendation> items;
  final HomeCustomization customization;
  final ValueChanged<HomeRecommendation> onOpen;
  final ValueChanged<HomeRecommendation> onHide;
  final ValueChanged<HomeNovelOpenRequest>? onNovelOpen;

  @override
  Widget build(BuildContext context) {
    if (items.length == 1) {
      return SliverToBoxAdapter(
        child: HomeRecommendationsStrip(
          items: items,
          customization: customization,
          onOpen: onOpen,
          onHide: onHide,
          onNovelOpen: onNovelOpen,
        ),
      );
    }
    return SliverLayoutBuilder(
      builder: (context, constraints) => _buildGrid(context, constraints),
    );
  }

  Widget _buildGrid(BuildContext context, SliverConstraints constraints) {
    final template = customization.recommendedNovelsTemplate;
    final size = customization.cardSizeFor(HomeSectionId.becauseYouRead);
    final padding = customization.density.horizontalPadding;
    final spacing = customization.density.itemSpacing;
    final usable = constraints.crossAxisExtent - padding * 2;
    final target = template == RecommendedNovelCardTemplate.horizontal
        ? 300 * size.scale
        : homePosterWidth(size);
    final columns = ((usable + spacing) / (target + spacing)).floor().clamp(
      template == RecommendedNovelCardTemplate.horizontal ? 1 : 2,
      5,
    );
    final cardWidth = (usable - spacing * (columns - 1)) / columns;
    final textGrowth = template == RecommendedNovelCardTemplate.horizontal
        ? (MediaQuery.textScalerOf(context).scale(14) - 14)
              .clamp(0, 24)
              .toDouble()
        : 0.0;
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: padding),
      sliver: SliverGrid.builder(
        key: const ValueKey('home-recommendations-grid'),
        itemCount: items.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          mainAxisExtent:
              (template == RecommendedNovelCardTemplate.horizontal
                  ? _cardExtent(template, size)
                  : homePosterExtentForWidth(cardWidth)) +
              textGrowth * 3,
        ),
        itemBuilder: (context, index) => HomeRecommendationCard(
          recommendation: items[index],
          customization: customization,
          onOpen: () => onOpen(items[index]),
          onNovelOpen: onNovelOpen,
          onHide: () => onHide(items[index]),
        ),
      ),
    );
  }
}

class HomeRecommendationCard extends StatelessWidget {
  const HomeRecommendationCard({
    required this.recommendation,
    required this.customization,
    required this.onOpen,
    required this.onHide,
    this.onNovelOpen,
    super.key,
  });

  final HomeRecommendation recommendation;
  final HomeCustomization customization;
  final VoidCallback onOpen;
  final VoidCallback onHide;
  final ValueChanged<HomeNovelOpenRequest>? onNovelOpen;

  @override
  Widget build(BuildContext context) {
    final template = customization.recommendedNovelsTemplate;
    final novel = recommendation.novel;
    final heroTag = homeNovelHeroTag(HomeSectionId.becauseYouRead, novel.id);
    final effectiveOpen = novel.manifest.isEmpty
        ? null
        : () {
            dispatchHomeNovelOpen(
              request: HomeNovelOpenRequest(
                manifestPath: novel.manifest,
                heroTag: heroTag,
                title: novel.title,
                coverUrl: novel.bestCover,
              ),
              enhancedOpen: onNovelOpen,
              legacyOpen: (_) => onOpen(),
            );
          };
    return Semantics(
      button: true,
      label: 'اقتراح ${recommendation.novel.title}',
      child: KeyedSubtree(
        key: ValueKey('recommendation-card-${recommendation.novel.id}'),
        child: template == RecommendedNovelCardTemplate.horizontal
            ? _HorizontalRecommendationCard(
                recommendation: recommendation,
                customization: customization,
                onOpen: effectiveOpen,
                heroTag: heroTag,
                menu: _RecommendationMenu(
                  novelId: recommendation.novel.id,
                  onHide: onHide,
                ),
              )
            : _PosterRecommendationCard(
                recommendation: recommendation,
                customization: customization,
                onOpen: effectiveOpen,
                heroTag: heroTag,
                minimal: template == RecommendedNovelCardTemplate.coverOnly,
                menu: _RecommendationMenu(
                  novelId: recommendation.novel.id,
                  onHide: onHide,
                ),
              ),
      ),
    );
  }
}

class _PosterRecommendationCard extends StatelessWidget {
  const _PosterRecommendationCard({
    required this.recommendation,
    required this.customization,
    required this.onOpen,
    required this.heroTag,
    required this.minimal,
    required this.menu,
  });

  final HomeRecommendation recommendation;
  final HomeCustomization customization;
  final VoidCallback? onOpen;
  final Object heroTag;
  final bool minimal;
  final Widget menu;

  @override
  Widget build(BuildContext context) {
    final novel = recommendation.novel;
    final section = HomeSectionId.becauseYouRead;
    final showsChapters = customization.showsField(
      section,
      HomeCardField.chapterCount,
    );
    final showsStatus = customization.showsField(section, HomeCardField.status);
    final metadata = <String>[
      if (!minimal &&
          customization.showsField(section, HomeCardField.matchReason))
        recommendation.reasonLabel,
      if (!minimal &&
          showsStatus &&
          showsChapters &&
          novel.chaptersCount > 0 &&
          novel.statusLabel.isNotEmpty)
        novel.statusLabel,
    ];
    return HomePosterCard(
      section: section,
      customization: customization,
      content: HomePosterContent(
        title: novel.title,
        imageUrl: novel.bestCover,
        badge: showsChapters && novel.chaptersCount > 0
            ? '${novel.chaptersCount}'
            : showsStatus && novel.statusLabel.isNotEmpty
            ? novel.statusLabel
            : null,
        metadata: metadata.isEmpty ? null : metadata.join(' • '),
      ),
      onTap: onOpen,
      captionAction: menu,
      heroTag: heroTag,
    );
  }
}

class _HorizontalRecommendationCard extends StatelessWidget {
  const _HorizontalRecommendationCard({
    required this.recommendation,
    required this.customization,
    required this.onOpen,
    required this.heroTag,
    required this.menu,
  });

  final HomeRecommendation recommendation;
  final HomeCustomization customization;
  final VoidCallback? onOpen;
  final Object heroTag;
  final Widget menu;

  @override
  Widget build(BuildContext context) {
    final section = HomeSectionId.becauseYouRead;
    final novel = recommendation.novel;
    final scale = customization.cardSizeFor(section).scale;
    final secondaryMetadata = <String>[
      if (customization.showsField(section, HomeCardField.status) &&
          novel.statusLabel.isNotEmpty)
        novel.statusLabel,
      if (customization.showsField(section, HomeCardField.chapterCount) &&
          novel.chaptersCount > 0)
        '${novel.chaptersCount} فصل',
    ];
    return homeCardSurface(
      context: context,
      customization: customization,
      radius: customization.coverCorner.radius,
      child: InkWell(
        onTap: onOpen,
        child: Row(
          children: [
            SizedBox(
              width: 92 * scale,
              child: LayoutBuilder(
                builder: (context, constraints) => HomeNovelCover(
                  section: section,
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
                padding: const EdgeInsetsDirectional.fromSTEB(12, 12, 4, 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            novel.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        menu,
                      ],
                    ),
                    if (customization.showsField(
                      section,
                      HomeCardField.matchReason,
                    )) ...[
                      const SizedBox(height: 6),
                      Text(
                        recommendation.reasonLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                    if (secondaryMetadata.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        secondaryMetadata.join(' • '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _RecommendationAction { hide }

class _RecommendationMenu extends StatelessWidget {
  const _RecommendationMenu({required this.novelId, required this.onHide});

  final int novelId;
  final VoidCallback onHide;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_RecommendationAction>(
      key: ValueKey('recommendation-menu-$novelId'),
      tooltip: 'خيارات الاقتراح',
      icon: const Icon(Icons.more_vert_rounded, size: 20),
      style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
      onSelected: (_) => onHide(),
      itemBuilder: (context) => [
        PopupMenuItem(
          key: ValueKey('recommendation-hide-$novelId'),
          value: _RecommendationAction.hide,
          child: const SizedBox(
            width: 190,
            child: Row(
              children: [
                Icon(Icons.visibility_off_outlined),
                SizedBox(width: 10),
                Expanded(child: Text('لا تقترح هذه الرواية')),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

double _cardWidth(RecommendedNovelCardTemplate template, HomeCardSize size) =>
    switch (template) {
      RecommendedNovelCardTemplate.poster ||
      RecommendedNovelCardTemplate.coverOnly => homePosterWidth(size),
      RecommendedNovelCardTemplate.horizontal => 300 * size.scale,
    };

double _cardExtent(RecommendedNovelCardTemplate template, HomeCardSize size) =>
    switch (template) {
      RecommendedNovelCardTemplate.poster ||
      RecommendedNovelCardTemplate.coverOnly => homePosterExtent(size),
      RecommendedNovelCardTemplate.horizontal => 176 * size.scale,
    };
