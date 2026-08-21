import 'package:flutter/material.dart';

import '../foundation/galaxy_design_tokens.dart';
import '../foundation/galaxy_metrics.dart';
import '../foundation/galaxy_motion.dart';

enum GalaxySurfaceVariant { flat, base, tonal, raised, interactive }

class GalaxySurface extends StatefulWidget {
  const GalaxySurface({
    required this.child,
    this.variant = GalaxySurfaceVariant.base,
    this.onTap,
    this.onLongPress,
    this.semanticLabel,
    this.padding = EdgeInsets.zero,
    this.radius = GalaxyMetrics.radiusCard,
    this.clipBehavior = Clip.antiAlias,
    super.key,
  });

  final Widget child;
  final GalaxySurfaceVariant variant;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final String? semanticLabel;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Clip clipBehavior;

  @override
  State<GalaxySurface> createState() => _GalaxySurfaceState();
}

class _GalaxySurfaceState extends State<GalaxySurface> {
  var _pressed = false;

  @override
  Widget build(BuildContext context) {
    final tokens = GalaxyDesignTokens.of(context);
    final radius = BorderRadius.circular(widget.radius);
    final style = _surfaceStyle(tokens, widget.variant);
    final interactive = widget.onTap != null || widget.onLongPress != null;

    final surface = Material(
      color: style.color,
      elevation: style.elevation,
      shadowColor: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.18),
      shape: RoundedRectangleBorder(borderRadius: radius, side: style.side),
      clipBehavior: widget.clipBehavior,
      child: InkWell(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        onHighlightChanged: interactive
            ? (pressed) => setState(() => _pressed = pressed)
            : null,
        borderRadius: radius,
        overlayColor: WidgetStatePropertyAll(
          tokens.brand.withValues(alpha: 0.10),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: interactive ? GalaxyMetrics.minimumTouchTarget : 0,
          ),
          child: Padding(padding: widget.padding, child: widget.child),
        ),
      ),
    );

    final result = interactive
        ? AnimatedScale(
            scale: _pressed ? 0.99 : 1,
            duration: GalaxyMotion.resolve(context, GalaxyMotion.press),
            curve: GalaxyMotion.curve,
            child: surface,
          )
        : surface;
    return Semantics(
      label: widget.semanticLabel,
      button: interactive,
      enabled: interactive ? true : null,
      child: result,
    );
  }
}

_GalaxySurfaceStyle _surfaceStyle(
  GalaxyDesignTokens tokens,
  GalaxySurfaceVariant variant,
) {
  return switch (variant) {
    GalaxySurfaceVariant.flat => _GalaxySurfaceStyle(
      color: tokens.surface,
      side: BorderSide.none,
    ),
    GalaxySurfaceVariant.base => _GalaxySurfaceStyle(
      color: tokens.surface,
      side: BorderSide(color: tokens.outline.withValues(alpha: 0.62)),
    ),
    GalaxySurfaceVariant.tonal => _GalaxySurfaceStyle(
      color: Color.alphaBlend(
        tokens.brand.withValues(alpha: 0.07),
        tokens.surface,
      ),
      side: BorderSide(color: tokens.brand.withValues(alpha: 0.20)),
    ),
    GalaxySurfaceVariant.raised => _GalaxySurfaceStyle(
      color: tokens.surfaceRaised,
      side: BorderSide(color: tokens.outline.withValues(alpha: 0.42)),
      elevation: 2,
    ),
    GalaxySurfaceVariant.interactive => _GalaxySurfaceStyle(
      color: tokens.brandContainer.withValues(alpha: 0.72),
      side: BorderSide(color: tokens.brand.withValues(alpha: 0.28)),
    ),
  };
}

class _GalaxySurfaceStyle {
  const _GalaxySurfaceStyle({
    required this.color,
    required this.side,
    this.elevation = 0,
  });

  final Color color;
  final BorderSide side;
  final double elevation;
}
