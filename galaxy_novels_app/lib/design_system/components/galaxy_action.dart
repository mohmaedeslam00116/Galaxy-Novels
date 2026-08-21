import 'package:flutter/material.dart';

import '../foundation/galaxy_design_tokens.dart';
import '../foundation/galaxy_metrics.dart';

enum GalaxyActionVariant { primary, secondary, ghost, danger }

class GalaxyButton extends StatelessWidget {
  const GalaxyButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = GalaxyActionVariant.primary,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final GalaxyActionVariant variant;

  @override
  Widget build(BuildContext context) {
    final tokens = GalaxyDesignTokens.of(context);
    final child = icon == null
        ? Text(label, textAlign: TextAlign.center)
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: GalaxyMetrics.space8),
              Flexible(child: Text(label, textAlign: TextAlign.center)),
            ],
          );
    final button = switch (variant) {
      GalaxyActionVariant.primary => FilledButton(
        onPressed: onPressed,
        child: child,
      ),
      GalaxyActionVariant.secondary => FilledButton.tonal(
        onPressed: onPressed,
        child: child,
      ),
      GalaxyActionVariant.ghost => TextButton(
        onPressed: onPressed,
        child: child,
      ),
      GalaxyActionVariant.danger => FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: tokens.dangerContainer,
          foregroundColor: tokens.onDangerContainer,
        ),
        onPressed: onPressed,
        child: child,
      ),
    };
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: GalaxyMetrics.minimumTouchTarget,
      ),
      child: button,
    );
  }
}

class GalaxyIconAction extends StatelessWidget {
  const GalaxyIconAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.selected = false,
    super.key,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final tokens = GalaxyDesignTokens.of(context);
    return SizedBox.square(
      dimension: GalaxyMetrics.minimumTouchTarget,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        isSelected: selected,
        style: IconButton.styleFrom(
          backgroundColor: selected ? tokens.brandContainer : tokens.surface,
          foregroundColor: selected
              ? tokens.onBrandContainer
              : tokens.contentSecondary,
          side: BorderSide(color: tokens.outline.withValues(alpha: 0.62)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(GalaxyMetrics.radiusControl),
          ),
        ),
        icon: Icon(icon),
      ),
    );
  }
}
