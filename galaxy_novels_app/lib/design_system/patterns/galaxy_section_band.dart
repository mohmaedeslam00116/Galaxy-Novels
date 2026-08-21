import 'package:flutter/material.dart';

import '../foundation/galaxy_design_tokens.dart';
import '../foundation/galaxy_metrics.dart';

class GalaxySectionBand extends StatelessWidget {
  const GalaxySectionBand({
    required this.child,
    this.padding = const EdgeInsets.symmetric(
      horizontal: GalaxyMetrics.space16,
      vertical: GalaxyMetrics.space16,
    ),
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const ValueKey('galaxy-section-band'),
      decoration: galaxySectionBandDecoration(context),
      child: Padding(padding: padding, child: child),
    );
  }
}

BoxDecoration galaxySectionBandDecoration(BuildContext context) {
  final tokens = GalaxyDesignTokens.of(context);
  return BoxDecoration(
    gradient: LinearGradient(
      begin: AlignmentDirectional.centerStart,
      end: AlignmentDirectional.centerEnd,
      colors: [
        tokens.surfaceRaised.withValues(alpha: 0.72),
        tokens.surface.withValues(alpha: 0.36),
      ],
    ),
    border: Border.symmetric(
      horizontal: BorderSide(color: tokens.outline.withValues(alpha: 0.24)),
    ),
  );
}
