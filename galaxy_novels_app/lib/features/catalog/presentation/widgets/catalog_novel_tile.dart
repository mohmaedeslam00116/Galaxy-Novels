import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';
import '../../../../data/models/catalog_data.dart';
import '../../../../design_system/components/galaxy_badge.dart';
import '../../../../design_system/components/galaxy_surface.dart';
import '../../../../design_system/foundation/galaxy_component_variants.dart';
import '../../../../design_system/novel/galaxy_novel_card.dart';
import '../../../../shared/widgets/novel_cover.dart';
import '../../domain/library_customization.dart';
import '../library_customization_metrics.dart';

class CatalogNovelTile extends StatelessWidget {
  const CatalogNovelTile({
    required this.novel,
    this.customization,
    this.onTap,
    super.key,
  });

  final CatalogNovel novel;
  final LibraryCustomization? customization;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final resolvedCustomization =
        customization ?? LibraryCustomization.defaults;
    final isGrid = resolvedCustomization.layout == LibraryLayout.grid;
    final child = isGrid
        ? _CatalogGridTile(novel: novel, customization: resolvedCustomization)
        : _CatalogListTile(novel: novel, customization: resolvedCustomization);

    return Semantics(
      label: novel.title,
      button: onTap != null,
      enabled: onTap == null ? null : true,
      onTap: onTap,
      excludeSemantics: true,
      child: RepaintBoundary(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(
              libraryCornerRadius(resolvedCustomization.cardCorner),
            ),
            child: isGrid
                ? child
                : _LibraryCardSurface(
                    customization: resolvedCustomization,
                    child: child,
                  ),
          ),
        ),
      ),
    );
  }
}

class _CatalogGridTile extends StatelessWidget {
  const _CatalogGridTile({required this.novel, required this.customization});

  final CatalogNovel novel;
  final LibraryCustomization customization;

  @override
  Widget build(BuildContext context) {
    if (customization.gridTemplate == LibraryGridTemplate.coverOnly) {
      return _CoverOnlyGridTile(novel: novel, customization: customization);
    }

    return GalaxyNovelCard(
      novel: GalaxyNovelCardData(
        title: novel.title,
        badge: _showsStatus(novel, customization) ? novel.statusLabel : null,
        metadata: _metadata(novel, customization).join(' • '),
      ),
      style: GalaxyNovelCardStyle(
        variant: GalaxyNovelCardVariant.editorialPoster,
        size: _componentSize(customization.cardSize),
        surface: _cardSurface(customization.cardSurface),
        coverPresentation: _coverPresentation(customization.coverPresentation),
        radius: libraryCornerRadius(customization.cardCorner),
      ),
      slots: GalaxyNovelCardSlots(
        coverSurfaceKey: const ValueKey('catalog-editorial-cover-surface'),
        cover: _CatalogCover(novel: novel, customization: customization),
        badge: _showsStatus(novel, customization)
            ? GalaxyBadge(
                key: const ValueKey('catalog-tile-status'),
                label: novel.statusLabel,
                size: GalaxyComponentSize.small,
              )
            : null,
        caption: _CatalogEditorialCaption(
          novel: novel,
          customization: customization,
        ),
      ),
    );
  }
}

class _CatalogEditorialCaption extends StatelessWidget {
  const _CatalogEditorialCaption({
    required this.novel,
    required this.customization,
  });

  final CatalogNovel novel;
  final LibraryCustomization customization;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          novel.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w900,
            height: 1.2,
          ),
        ),
        if (_metadata(novel, customization).isNotEmpty) ...[
          const SizedBox(height: 4),
          _CatalogMetadataLine(novel: novel, customization: customization),
        ],
      ],
    );
  }
}

class _CoverOnlyGridTile extends StatelessWidget {
  const _CoverOnlyGridTile({required this.novel, required this.customization});

  final CatalogNovel novel;
  final LibraryCustomization customization;

  @override
  Widget build(BuildContext context) {
    final metadata = _metadata(novel, customization);
    return _LibraryCardSurface(
      key: const ValueKey('catalog-editorial-cover-surface'),
      customization: customization,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _CatalogCover(novel: novel, customization: customization),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0xDC09090D)],
                stops: [0.46, 1],
              ),
            ),
          ),
          if (_showsStatus(novel, customization))
            Positioned(
              top: 8,
              left: 8,
              child: GalaxyBadge(
                key: const ValueKey('catalog-tile-status'),
                label: novel.statusLabel,
                size: GalaxyComponentSize.small,
              ),
            ),
          PositionedDirectional(
            start: 10,
            end: 10,
            bottom: 10,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  novel.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    height: 1.25,
                  ),
                ),
                if (metadata.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    metadata.join(' • '),
                    key: const ValueKey('catalog-tile-metadata'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.82),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CatalogListTile extends StatelessWidget {
  const _CatalogListTile({required this.novel, required this.customization});

  final CatalogNovel novel;
  final LibraryCustomization customization;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final compact = customization.listTemplate == LibraryListTemplate.compact;
    final coverWidth = libraryListCoverWidth(customization.cardSize);
    final coverHeight = compact ? coverWidth * 1.28 : coverWidth / 0.70;
    final padding = customization.density == LibraryDensity.compact
        ? 8.0
        : 10.0;

    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: libraryListMinimumHeight(customization.cardSize),
      ),
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: coverWidth,
              height: coverHeight,
              child: _CatalogCover(novel: novel, customization: customization),
            ),
            SizedBox(width: compact ? 10 : 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    novel.title,
                    maxLines: compact ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                    style:
                        (compact
                                ? theme.textTheme.titleSmall
                                : theme.textTheme.titleMedium)
                            ?.copyWith(
                              fontWeight: FontWeight.w900,
                              height: 1.25,
                            ),
                  ),
                  if (_showsStatus(novel, customization)) ...[
                    const SizedBox(height: 6),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: GalaxyBadge(
                        key: const ValueKey('catalog-tile-status'),
                        label: novel.statusLabel,
                        size: GalaxyComponentSize.small,
                      ),
                    ),
                  ],
                  if (_metadata(novel, customization).isNotEmpty) ...[
                    SizedBox(height: compact ? 5 : 8),
                    _CatalogMetadataLine(
                      novel: novel,
                      customization: customization,
                      maxLines: compact ? 1 : 2,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CatalogCover extends StatelessWidget {
  const _CatalogCover({required this.novel, required this.customization});

  final CatalogNovel novel;
  final LibraryCustomization customization;

  @override
  Widget build(BuildContext context) {
    final tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;
    final imageUrl = novel.coverMedium.isNotEmpty
        ? novel.coverMedium
        : novel.coverThumbnail.isNotEmpty
        ? novel.coverThumbnail
        : novel.coverLarge;
    final tonal =
        customization.coverPresentation == LibraryCoverPresentation.tonalFrame;
    final fit = customization.coverPresentation == LibraryCoverPresentation.fill
        ? BoxFit.cover
        : BoxFit.contain;
    final radius = libraryCornerRadius(customization.cardCorner);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 1.0;
        final height = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : 1.0;
        final cover = NovelCover(
          key: const ValueKey('catalog-tile-cover'),
          title: novel.title,
          imageUrl: imageUrl,
          width: tonal ? (width - 10).clamp(1, width) : width,
          height: tonal ? (height - 10).clamp(1, height) : height,
          borderRadius: tonal ? (radius - 3).clamp(1, radius) : radius,
          fit: fit,
          backgroundColor: tokens.surfaceRaised,
        );
        if (!tonal) return cover;
        return DecoratedBox(
          decoration: BoxDecoration(
            color: tokens.brandContainer.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: tokens.brand.withValues(alpha: 0.24)),
          ),
          child: Center(child: cover),
        );
      },
    );
  }
}

class _CatalogMetadataLine extends StatelessWidget {
  const _CatalogMetadataLine({
    required this.novel,
    required this.customization,
    this.maxLines = 1,
  });

  final CatalogNovel novel;
  final LibraryCustomization customization;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: scheme.onSurfaceVariant,
      height: 1.35,
    );
    final values = <Widget>[
      if (customization.shows(LibraryCardField.chapters))
        Text(
          novel.chaptersCount > 0
              ? '${novel.chaptersCount} فصل'
              : 'عدد الفصول غير متاح',
          key: const ValueKey('catalog-tile-chapters'),
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
          style: style,
        ),
      if (customization.shows(LibraryCardField.rating) &&
          novel.ratingAverage > 0)
        Text(
          '★ ${novel.ratingAverage.toStringAsFixed(1)}',
          key: const ValueKey('catalog-tile-rating'),
          maxLines: 1,
          style: style,
        ),
      if (customization.shows(LibraryCardField.firstGenre) &&
          novel.genres.isNotEmpty)
        Text(
          novel.genres.first.name,
          key: const ValueKey('catalog-tile-genre'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: style,
        ),
    ];
    return Wrap(
      key: const ValueKey('catalog-tile-metadata'),
      spacing: 5,
      runSpacing: 2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (var index = 0; index < values.length; index++) ...[
          if (index > 0) Text('•', style: style),
          values[index],
        ],
      ],
    );
  }
}

class _LibraryCardSurface extends StatelessWidget {
  const _LibraryCardSurface({
    required this.customization,
    required this.child,
    super.key,
  });

  final LibraryCustomization customization;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final radius = libraryCornerRadius(customization.cardCorner);
    return GalaxySurface(
      variant: switch (customization.cardSurface) {
        LibraryCardSurface.flat => GalaxySurfaceVariant.flat,
        LibraryCardSurface.outlined => GalaxySurfaceVariant.tonal,
        LibraryCardSurface.elevated => GalaxySurfaceVariant.raised,
      },
      radius: radius,
      child: child,
    );
  }
}

bool _showsStatus(CatalogNovel novel, LibraryCustomization customization) {
  return customization.shows(LibraryCardField.status) &&
      novel.statusLabel.isNotEmpty;
}

List<String> _metadata(CatalogNovel novel, LibraryCustomization customization) {
  return [
    if (customization.shows(LibraryCardField.chapters))
      novel.chaptersCount > 0
          ? '${novel.chaptersCount} فصل'
          : 'عدد الفصول غير متاح',
    if (customization.shows(LibraryCardField.rating) && novel.ratingAverage > 0)
      '★ ${novel.ratingAverage.toStringAsFixed(1)}',
    if (customization.shows(LibraryCardField.firstGenre) &&
        novel.genres.isNotEmpty)
      novel.genres.first.name,
  ];
}

GalaxyComponentSize _componentSize(LibraryCardSize size) => switch (size) {
  LibraryCardSize.small => GalaxyComponentSize.small,
  LibraryCardSize.medium => GalaxyComponentSize.medium,
  LibraryCardSize.large => GalaxyComponentSize.large,
};

GalaxyCardSurface _cardSurface(LibraryCardSurface surface) => switch (surface) {
  LibraryCardSurface.flat => GalaxyCardSurface.flat,
  LibraryCardSurface.outlined => GalaxyCardSurface.outlined,
  LibraryCardSurface.elevated => GalaxyCardSurface.raised,
};

GalaxyCoverPresentation _coverPresentation(
  LibraryCoverPresentation presentation,
) => switch (presentation) {
  LibraryCoverPresentation.fill => GalaxyCoverPresentation.fill,
  LibraryCoverPresentation.fit => GalaxyCoverPresentation.fit,
  LibraryCoverPresentation.tonalFrame => GalaxyCoverPresentation.tonalFrame,
};
