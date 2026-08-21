import 'package:flutter/material.dart';

import '../../../design_system/components/galaxy_badge.dart';
import '../../../design_system/foundation/galaxy_component_variants.dart';
import '../../../design_system/novel/galaxy_chapter_count_tab.dart';
import '../../../design_system/novel/galaxy_novel_card.dart';
import '../domain/home_customization.dart';
import 'home_card_appearance.dart';
import 'home_novel_cover.dart';

class HomePosterContent {
  const HomePosterContent({
    required this.title,
    required this.imageUrl,
    this.badge,
    this.metadata,
  });

  final String title;
  final String imageUrl;
  final String? badge;
  final String? metadata;
}

class HomePosterCard extends StatelessWidget {
  const HomePosterCard({
    required this.section,
    required this.customization,
    required this.content,
    required this.onTap,
    this.captionAction,
    this.heroTag,
    super.key,
  });

  final HomeSectionId section;
  final HomeCustomization customization;
  final HomePosterContent content;
  final VoidCallback? onTap;
  final Widget? captionAction;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    final radius = customization.coverCorner.radius;
    final badgeLabel = content.badge;
    final chapterCount = int.tryParse(badgeLabel ?? '');
    final componentSize = _componentSize(customization.cardSizeFor(section));
    return GalaxyNovelCard(
      key: ValueKey('home-poster-shell-${section.name}'),
      novel: GalaxyNovelCardData(
        title: content.title,
        metadata: content.metadata,
      ),
      style: GalaxyNovelCardStyle(
        variant: GalaxyNovelCardVariant.cinematicPoster,
        size: componentSize,
        surface: _cardSurface(customization.cardSurface),
        coverPresentation: _coverPresentation(
          customization.coverPresentationFor(section),
        ),
        radius: radius,
      ),
      slots: GalaxyNovelCardSlots(
        cover: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: LayoutBuilder(
            builder: (context, constraints) => HomeNovelCover(
              section: section,
              customization: customization,
              title: content.title,
              imageUrl: content.imageUrl,
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              heroTag: heroTag,
            ),
          ),
        ),
        badge: badgeLabel == null
            ? null
            : chapterCount != null
            ? Transform.translate(
                offset: const Offset(0, -8),
                child: GalaxyChapterCountTab(
                  key: ValueKey(
                    'home-poster-chapter-count-tab-${section.name}',
                  ),
                  chapterCount: badgeLabel,
                  size: componentSize,
                ),
              )
            : GalaxyBadge(
                key: ValueKey('home-poster-badge-${section.name}'),
                label: badgeLabel,
              ),
        captionAction: captionAction,
      ),
      onTap: onTap,
    );
  }
}

GalaxyComponentSize _componentSize(HomeCardSize size) => switch (size) {
  HomeCardSize.small => GalaxyComponentSize.small,
  HomeCardSize.medium => GalaxyComponentSize.medium,
  HomeCardSize.large => GalaxyComponentSize.large,
};

GalaxyCardSurface _cardSurface(HomeCardSurface surface) => switch (surface) {
  HomeCardSurface.flat => GalaxyCardSurface.flat,
  HomeCardSurface.outlined => GalaxyCardSurface.outlined,
  HomeCardSurface.elevated => GalaxyCardSurface.raised,
};

GalaxyCoverPresentation _coverPresentation(HomeCoverPresentation value) =>
    switch (value) {
      HomeCoverPresentation.fill => GalaxyCoverPresentation.fill,
      HomeCoverPresentation.fit => GalaxyCoverPresentation.fit,
      HomeCoverPresentation.tonalFrame => GalaxyCoverPresentation.tonalFrame,
    };

double homePosterWidth(HomeCardSize size) => switch (size) {
  HomeCardSize.small => 118,
  HomeCardSize.medium => 136,
  HomeCardSize.large => 160,
};

double homePosterExtent(HomeCardSize size) =>
    homePosterExtentForWidth(homePosterWidth(size));

double homePosterExtentForWidth(double width) => width * 1.5;
