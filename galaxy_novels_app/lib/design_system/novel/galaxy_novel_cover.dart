import 'package:flutter/material.dart';

import '../foundation/galaxy_component_variants.dart';
import '../foundation/galaxy_design_tokens.dart';
import '../foundation/galaxy_metrics.dart';

export '../foundation/galaxy_component_variants.dart'
    show GalaxyCoverPresentation;

@immutable
class GalaxyNovelArtwork {
  const GalaxyNovelArtwork({required this.title, this.image});

  final String title;
  final ImageProvider<Object>? image;
}

class GalaxyNovelCover extends StatelessWidget {
  const GalaxyNovelCover({
    required this.artwork,
    this.presentation = GalaxyCoverPresentation.fill,
    this.radius = GalaxyMetrics.radiusCard,
    this.heroTag,
    super.key,
  });

  final GalaxyNovelArtwork artwork;
  final GalaxyCoverPresentation presentation;
  final double radius;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    final cover = AspectRatio(
      aspectRatio: GalaxyMetrics.coverAspectRatio,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tokens = GalaxyDesignTokens.of(context);
          final framed = presentation == GalaxyCoverPresentation.tonalFrame;
          final coverRadius = framed
              ? (radius - 5).clamp(0.0, radius).toDouble()
              : radius;
          final image = _CoverImage(
            artwork: artwork,
            fit: presentation == GalaxyCoverPresentation.fill
                ? BoxFit.cover
                : BoxFit.contain,
            width: constraints.maxWidth - (framed ? 12 : 0),
            height: constraints.maxHeight - (framed ? 12 : 0),
            radius: coverRadius,
          );
          if (!framed) {
            return ColoredBox(color: tokens.surfaceRaised, child: image);
          }
          return DecoratedBox(
            decoration: BoxDecoration(
              color: Color.alphaBlend(
                tokens.brand.withValues(alpha: 0.10),
                tokens.surface,
              ),
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: tokens.brand.withValues(alpha: 0.26)),
            ),
            child: Padding(padding: const EdgeInsets.all(6), child: image),
          );
        },
      ),
    );
    final animatedCover =
        heroTag == null || MediaQuery.disableAnimationsOf(context)
        ? cover
        : Hero(tag: heroTag!, transitionOnUserGestures: true, child: cover);
    return Semantics(
      image: true,
      label: 'غلاف رواية ${artwork.title}',
      child: RepaintBoundary(child: animatedCover),
    );
  }
}

class _CoverImage extends StatelessWidget {
  const _CoverImage({
    required this.artwork,
    required this.fit,
    required this.width,
    required this.height,
    required this.radius,
  });

  final GalaxyNovelArtwork artwork;
  final BoxFit fit;
  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final imageProvider = artwork.image;
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    final cacheWidth = _cacheDimension(width, pixelRatio);
    final cacheHeight = _cacheDimension(height, pixelRatio);
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: imageProvider == null
          ? const _CoverFallback()
          : Image(
              image: ResizeImage.resizeIfNeeded(
                cacheWidth,
                cacheHeight,
                imageProvider,
              ),
              fit: fit,
              filterQuality: FilterQuality.medium,
              errorBuilder: (_, _, _) => const _CoverFallback(),
            ),
    );
  }
}

class _CoverFallback extends StatelessWidget {
  const _CoverFallback();

  @override
  Widget build(BuildContext context) {
    final tokens = GalaxyDesignTokens.of(context);
    return ColoredBox(
      color: tokens.surfaceRaised,
      child: Center(
        child: Text(
          'غلاف',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: tokens.brand,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

int? _cacheDimension(double logicalSize, double pixelRatio) {
  final scaled = logicalSize * pixelRatio * 1.25;
  return scaled.isFinite && scaled > 0 ? scaled.ceil() : null;
}
