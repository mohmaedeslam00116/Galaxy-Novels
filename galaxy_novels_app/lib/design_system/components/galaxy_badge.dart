import 'package:flutter/material.dart';

import '../foundation/galaxy_component_variants.dart';
import '../foundation/galaxy_design_tokens.dart';
import '../foundation/galaxy_metrics.dart';

export '../foundation/galaxy_component_variants.dart'
    show GalaxyBadgeTone, GalaxyComponentSize;

class GalaxyBadge extends StatelessWidget {
  const GalaxyBadge({
    required this.label,
    this.tone = GalaxyBadgeTone.neutral,
    this.size = GalaxyComponentSize.medium,
    this.icon,
    super.key,
  });

  final String label;
  final GalaxyBadgeTone tone;
  final GalaxyComponentSize size;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = _badgeColors(GalaxyDesignTokens.of(context), tone);
    final metrics = switch (size) {
      GalaxyComponentSize.small => (
        minHeight: 24.0,
        horizontal: 7.0,
        vertical: 3.0,
        iconSize: 13.0,
      ),
      GalaxyComponentSize.medium => (
        minHeight: 30.0,
        horizontal: 9.0,
        vertical: 5.0,
        iconSize: 15.0,
      ),
      GalaxyComponentSize.large => (
        minHeight: 36.0,
        horizontal: 11.0,
        vertical: 7.0,
        iconSize: 17.0,
      ),
    };
    return Container(
      constraints: BoxConstraints(minHeight: metrics.minHeight),
      padding: EdgeInsets.symmetric(
        horizontal: metrics.horizontal,
        vertical: metrics.vertical,
      ),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(GalaxyMetrics.radiusSmall),
        border: Border.all(color: colors.foreground.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon case final icon?) ...[
            Icon(icon, size: metrics.iconSize, color: colors.foreground),
            const SizedBox(width: GalaxyMetrics.space4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.foreground,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

({Color background, Color foreground}) _badgeColors(
  GalaxyDesignTokens tokens,
  GalaxyBadgeTone tone,
) {
  return switch (tone) {
    GalaxyBadgeTone.neutral => (
      background: tokens.surfaceRaised,
      foreground: tokens.contentSecondary,
    ),
    GalaxyBadgeTone.brand => (
      background: tokens.brandContainer,
      foreground: tokens.onBrandContainer,
    ),
    GalaxyBadgeTone.success => (
      background: tokens.successContainer,
      foreground: tokens.onSuccessContainer,
    ),
    GalaxyBadgeTone.warning => (
      background: tokens.warningContainer,
      foreground: tokens.onWarningContainer,
    ),
    GalaxyBadgeTone.danger => (
      background: tokens.dangerContainer,
      foreground: tokens.onDangerContainer,
    ),
  };
}
