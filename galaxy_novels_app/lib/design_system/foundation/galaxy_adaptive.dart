import 'package:flutter/widgets.dart';

import 'galaxy_metrics.dart';

enum GalaxyLayoutTier { compact, medium, expanded }

@Deprecated('Use GalaxyLayoutTier instead.')
typedef GalaxyWindowClass = GalaxyLayoutTier;

@immutable
class GalaxyAdaptiveMetrics {
  const GalaxyAdaptiveMetrics({
    required this.tier,
    required this.horizontalPadding,
    required this.sectionSpacing,
  });

  factory GalaxyAdaptiveMetrics.forWidth(double width) {
    final tier = GalaxyAdaptive.windowClassFor(width);
    return GalaxyAdaptiveMetrics(
      tier: tier,
      horizontalPadding: switch (tier) {
        GalaxyLayoutTier.compact => GalaxyMetrics.space16,
        GalaxyLayoutTier.medium => GalaxyMetrics.space20,
        GalaxyLayoutTier.expanded => GalaxyMetrics.space24,
      },
      sectionSpacing: switch (tier) {
        GalaxyLayoutTier.compact => GalaxyMetrics.space24,
        GalaxyLayoutTier.medium => 28,
        GalaxyLayoutTier.expanded => GalaxyMetrics.space32,
      },
    );
  }

  final GalaxyLayoutTier tier;
  final double horizontalPadding;
  final double sectionSpacing;
}

abstract final class GalaxyAdaptive {
  static const mediumBreakpoint = 600.0;
  static const expandedBreakpoint = 840.0;

  static GalaxyLayoutTier windowClassFor(double width) {
    if (width >= expandedBreakpoint) return GalaxyLayoutTier.expanded;
    if (width >= mediumBreakpoint) return GalaxyLayoutTier.medium;
    return GalaxyLayoutTier.compact;
  }

  static double horizontalPaddingFor(double width) {
    return GalaxyAdaptiveMetrics.forWidth(width).horizontalPadding;
  }

  static double sectionSpacingFor(double width) {
    return GalaxyAdaptiveMetrics.forWidth(width).sectionSpacing;
  }

  static GalaxyLayoutTier of(BuildContext context) {
    return windowClassFor(MediaQuery.sizeOf(context).width);
  }
}
