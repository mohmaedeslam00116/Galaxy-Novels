import 'package:flutter/material.dart';

import '../components/galaxy_badge.dart';
import '../components/galaxy_surface.dart';
import '../foundation/galaxy_component_variants.dart';
import '../foundation/galaxy_metrics.dart';
import 'galaxy_novel_cover.dart';

enum GalaxyNovelCardVariant {
  poster,
  cinematicPoster,
  editorialPoster,
  coverOnly,
  horizontal,
  compactUpdate,
  detailedUpdate,
}

@immutable
class GalaxyNovelCardData {
  const GalaxyNovelCardData({
    required this.title,
    this.artwork,
    this.badge,
    this.metadata,
    this.secondaryMetadata,
  });

  final String title;
  final ImageProvider<Object>? artwork;
  final String? badge;
  final String? metadata;
  final String? secondaryMetadata;
}

@immutable
class GalaxyNovelCardStyle {
  const GalaxyNovelCardStyle({
    required this.variant,
    this.size = GalaxyComponentSize.medium,
    this.surface = GalaxyCardSurface.outlined,
    this.coverPresentation = GalaxyCoverPresentation.fill,
    this.radius = GalaxyMetrics.radiusCard,
  });

  const GalaxyNovelCardStyle.poster({
    this.size = GalaxyComponentSize.medium,
    this.surface = GalaxyCardSurface.outlined,
    this.coverPresentation = GalaxyCoverPresentation.fill,
    this.radius = GalaxyMetrics.radiusCard,
  }) : variant = GalaxyNovelCardVariant.poster;

  final GalaxyNovelCardVariant variant;
  final GalaxyComponentSize size;
  final GalaxyCardSurface surface;
  final GalaxyCoverPresentation coverPresentation;
  final double radius;
}

@immutable
class GalaxyNovelCardSlots {
  const GalaxyNovelCardSlots({
    this.cover,
    this.badge,
    this.caption,
    this.captionAction,
    this.coverSurfaceKey,
  });

  final Widget? cover;
  final Widget? badge;
  final Widget? caption;
  final Widget? captionAction;
  final Key? coverSurfaceKey;
}

class GalaxyNovelCard extends StatelessWidget {
  const GalaxyNovelCard({
    required this.novel,
    required this.style,
    this.slots = const GalaxyNovelCardSlots(),
    this.onTap,
    this.heroTag,
    super.key,
  });

  final GalaxyNovelCardData novel;
  final GalaxyNovelCardStyle style;
  final GalaxyNovelCardSlots slots;
  final VoidCallback? onTap;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    if (style.variant == GalaxyNovelCardVariant.editorialPoster) {
      return _EditorialPosterCard(
        novel: novel,
        style: style,
        slots: slots,
        onTap: onTap,
        heroTag: heroTag,
      );
    }
    final content = switch (style.variant) {
      GalaxyNovelCardVariant.poster ||
      GalaxyNovelCardVariant.cinematicPoster ||
      GalaxyNovelCardVariant.coverOnly => _PosterCard(
        novel: novel,
        style: style,
        slots: slots,
        heroTag: heroTag,
      ),
      GalaxyNovelCardVariant.editorialPoster => const SizedBox.shrink(),
      GalaxyNovelCardVariant.horizontal ||
      GalaxyNovelCardVariant.compactUpdate ||
      GalaxyNovelCardVariant.detailedUpdate => _HorizontalCard(
        novel: novel,
        style: style,
        slots: slots,
        heroTag: heroTag,
      ),
    };
    return GalaxySurface(
      variant: _surfaceVariant(style.surface),
      radius: style.radius,
      onTap: onTap,
      semanticLabel: novel.title,
      child: content,
    );
  }
}

class _PosterCard extends StatelessWidget {
  const _PosterCard({
    required this.novel,
    required this.style,
    required this.slots,
    this.heroTag,
  });

  final GalaxyNovelCardData novel;
  final GalaxyNovelCardStyle style;
  final GalaxyNovelCardSlots slots;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      key: style.variant == GalaxyNovelCardVariant.cinematicPoster
          ? const ValueKey('galaxy-cinematic-cover')
          : null,
      aspectRatio: GalaxyMetrics.coverAspectRatio,
      child: Stack(
        fit: StackFit.expand,
        children: [
          slots.cover ??
              GalaxyNovelCover(
                artwork: GalaxyNovelArtwork(
                  title: novel.title,
                  image: novel.artwork,
                ),
                presentation: style.coverPresentation,
                radius: style.radius,
                heroTag: heroTag,
              ),
          const _ReadabilityGradient(),
          if (slots.badge != null || novel.badge != null)
            PositionedDirectional(
              top: 8,
              start: 8,
              child: slots.badge ?? GalaxyBadge(label: novel.badge!),
            ),
          PositionedDirectional(
            start: 10,
            end: 10,
            bottom: 10,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        novel.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          height: 1.22,
                        ),
                      ),
                      if (novel.metadata case final metadata?) ...[
                        const SizedBox(height: GalaxyMetrics.space4),
                        Text(
                          metadata,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.82),
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (slots.captionAction != null)
                  SizedBox.square(
                    dimension: GalaxyMetrics.minimumTouchTarget,
                    child: IconTheme(
                      data: const IconThemeData(color: Colors.white, size: 20),
                      child: slots.captionAction!,
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

class _EditorialPosterCard extends StatelessWidget {
  const _EditorialPosterCard({
    required this.novel,
    required this.style,
    required this.slots,
    required this.onTap,
    this.heroTag,
  });

  final GalaxyNovelCardData novel;
  final GalaxyNovelCardStyle style;
  final GalaxyNovelCardSlots slots;
  final VoidCallback? onTap;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GalaxySurface(
          key: slots.coverSurfaceKey,
          variant: _surfaceVariant(style.surface),
          radius: style.radius,
          clipBehavior: Clip.antiAlias,
          child: AspectRatio(
            aspectRatio: GalaxyMetrics.coverAspectRatio,
            child: Stack(
              fit: StackFit.expand,
              children: [
                slots.cover ??
                    GalaxyNovelCover(
                      artwork: GalaxyNovelArtwork(
                        title: novel.title,
                        image: novel.artwork,
                      ),
                      presentation: style.coverPresentation,
                      radius: style.radius,
                      heroTag: heroTag,
                    ),
                if (slots.badge != null || novel.badge != null)
                  PositionedDirectional(
                    top: GalaxyMetrics.space8,
                    start: GalaxyMetrics.space8,
                    child: slots.badge ?? GalaxyBadge(label: novel.badge!),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: GalaxyMetrics.space4),
        Row(
          key: const ValueKey('galaxy-editorial-caption'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child:
                  slots.caption ??
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        novel.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 1.22,
                        ),
                      ),
                      if (novel.metadata case final metadata?) ...[
                        const SizedBox(height: GalaxyMetrics.space4),
                        Text(
                          metadata,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall,
                        ),
                      ],
                    ],
                  ),
            ),
            if (slots.captionAction != null)
              SizedBox.square(
                dimension: GalaxyMetrics.minimumTouchTarget,
                child: slots.captionAction,
              ),
          ],
        ),
      ],
    );
    return Semantics(
      label: novel.title,
      button: onTap != null,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(style.radius),
          child: content,
        ),
      ),
    );
  }
}

class _HorizontalCard extends StatelessWidget {
  const _HorizontalCard({
    required this.novel,
    required this.style,
    required this.slots,
    this.heroTag,
  });

  final GalaxyNovelCardData novel;
  final GalaxyNovelCardStyle style;
  final GalaxyNovelCardSlots slots;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    final compact = style.variant == GalaxyNovelCardVariant.compactUpdate;
    final width = compact ? 56.0 : 78.0;
    return Padding(
      padding: const EdgeInsets.all(GalaxyMetrics.space8),
      child: Row(
        children: [
          SizedBox(
            width: width,
            child:
                slots.cover ??
                GalaxyNovelCover(
                  artwork: GalaxyNovelArtwork(
                    title: novel.title,
                    image: novel.artwork,
                  ),
                  presentation: style.coverPresentation,
                  radius: (style.radius - 4).clamp(0, style.radius),
                  heroTag: heroTag,
                ),
          ),
          const SizedBox(width: GalaxyMetrics.space12),
          Expanded(
            child:
                slots.caption ??
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      novel.title,
                      maxLines: compact ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (novel.metadata case final metadata?) ...[
                      const SizedBox(height: GalaxyMetrics.space4),
                      Text(
                        metadata,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    if (!compact && novel.secondaryMetadata != null) ...[
                      const SizedBox(height: GalaxyMetrics.space4),
                      Text(
                        novel.secondaryMetadata!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
          ),
          if (slots.captionAction != null) ...[
            const SizedBox(width: GalaxyMetrics.space8),
            SizedBox.square(
              dimension: GalaxyMetrics.minimumTouchTarget,
              child: slots.captionAction,
            ),
          ],
          if (slots.badge != null || novel.badge != null) ...[
            const SizedBox(width: GalaxyMetrics.space8),
            slots.badge ?? GalaxyBadge(label: novel.badge!),
          ],
        ],
      ),
    );
  }
}

class _ReadabilityGradient extends StatelessWidget {
  const _ReadabilityGradient();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0.40, 0.70, 1],
          colors: [Colors.transparent, Color(0x36000000), Color(0xD9000000)],
        ),
      ),
    );
  }
}

GalaxySurfaceVariant _surfaceVariant(GalaxyCardSurface surface) {
  return switch (surface) {
    GalaxyCardSurface.flat => GalaxySurfaceVariant.flat,
    GalaxyCardSurface.outlined => GalaxySurfaceVariant.tonal,
    GalaxyCardSurface.raised => GalaxySurfaceVariant.raised,
  };
}
