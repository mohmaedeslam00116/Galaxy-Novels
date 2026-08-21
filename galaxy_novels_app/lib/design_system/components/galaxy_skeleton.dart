import 'package:flutter/material.dart';

import '../foundation/galaxy_design_tokens.dart';
import '../foundation/galaxy_metrics.dart';

enum GalaxySkeletonVariant { poster, row, details }

class GalaxySkeleton extends StatelessWidget {
  const GalaxySkeleton({this.variant = GalaxySkeletonVariant.row, super.key});

  final GalaxySkeletonVariant variant;

  @override
  Widget build(BuildContext context) {
    final tokens = GalaxyDesignTokens.of(context);
    final base = Color.alphaBlend(
      tokens.contentSecondary.withValues(alpha: 0.10),
      tokens.surface,
    );
    final highlight = Color.alphaBlend(
      tokens.contentSecondary.withValues(alpha: 0.16),
      tokens.surface,
    );
    return RepaintBoundary(
      child: Semantics(
        label: 'جارٍ تحميل المحتوى',
        child: ExcludeSemantics(
          child: switch (variant) {
            GalaxySkeletonVariant.poster => _PosterSkeleton(
              base: base,
              highlight: highlight,
            ),
            GalaxySkeletonVariant.row => _RowSkeleton(
              base: base,
              highlight: highlight,
            ),
            GalaxySkeletonVariant.details => _DetailsSkeleton(
              base: base,
              highlight: highlight,
            ),
          },
        ),
      ),
    );
  }
}

class _PosterSkeleton extends StatelessWidget {
  const _PosterSkeleton({required this.base, required this.highlight});

  final Color base;
  final Color highlight;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: GalaxyMetrics.coverAspectRatio,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(GalaxyMetrics.radiusCard),
        ),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.all(GalaxyMetrics.space12),
            child: _SkeletonLine(color: highlight, widthFactor: 0.78),
          ),
        ),
      ),
    );
  }
}

class _RowSkeleton extends StatelessWidget {
  const _RowSkeleton({required this.base, required this.highlight});

  final Color base;
  final Color highlight;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 64,
          height: 96,
          decoration: BoxDecoration(
            color: base,
            borderRadius: BorderRadius.circular(GalaxyMetrics.radiusControl),
          ),
        ),
        const SizedBox(width: GalaxyMetrics.space12),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SkeletonLine(color: highlight, widthFactor: 0.72),
              const SizedBox(height: GalaxyMetrics.space8),
              _SkeletonLine(color: base, widthFactor: 0.48),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailsSkeleton extends StatelessWidget {
  const _DetailsSkeleton({required this.base, required this.highlight});

  final Color base;
  final Color highlight;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 160,
          child: _PosterSkeleton(base: base, highlight: highlight),
        ),
        const SizedBox(height: GalaxyMetrics.space16),
        _SkeletonLine(color: highlight, widthFactor: 0.62),
        const SizedBox(height: GalaxyMetrics.space8),
        _SkeletonLine(color: base, widthFactor: 0.42),
      ],
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({required this.color, required this.widthFactor});

  final Color color;
  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        height: 12,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(GalaxyMetrics.radiusSmall),
        ),
      ),
    );
  }
}
