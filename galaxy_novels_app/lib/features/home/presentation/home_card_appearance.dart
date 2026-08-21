import 'package:flutter/material.dart';

import '../../../design_system/components/galaxy_surface.dart';
import '../domain/home_customization.dart';

extension HomeCoverCornerMetrics on HomeCoverCorner {
  double get radius => switch (this) {
    HomeCoverCorner.soft => 16,
    HomeCoverCorner.medium => 12,
    HomeCoverCorner.almostSquare => 8,
  };
}

extension HomeCardSizeMetrics on HomeCardSize {
  double get scale => switch (this) {
    HomeCardSize.small => 0.86,
    HomeCardSize.medium => 1,
    HomeCardSize.large => 1.14,
  };
}

Color homeCardColor(ColorScheme scheme, HomeCardTint tint) {
  final base = scheme.surfaceContainerLow;
  return switch (tint) {
    HomeCardTint.neutral => base,
    HomeCardTint.subtle => Color.alphaBlend(
      scheme.primary.withValues(alpha: 0.055),
      base,
    ),
    HomeCardTint.strong => Color.alphaBlend(
      scheme.primary.withValues(alpha: 0.12),
      base,
    ),
  };
}

Color homeImageForeground(ColorScheme scheme) {
  return scheme.brightness == Brightness.dark
      ? scheme.onSurface
      : scheme.surface;
}

Widget homeCardSurface({
  required BuildContext context,
  required HomeCustomization customization,
  required Widget child,
  Key? key,
  double? radius,
  EdgeInsetsGeometry margin = EdgeInsets.zero,
  Clip clipBehavior = Clip.antiAlias,
}) {
  final surface = GalaxySurface(
    key: key,
    variant: _galaxySurfaceVariant(customization),
    radius: radius ?? 16,
    clipBehavior: clipBehavior,
    child: child,
  );
  if (margin == EdgeInsets.zero) return surface;
  return Padding(padding: margin, child: surface);
}

GalaxySurfaceVariant _galaxySurfaceVariant(HomeCustomization customization) {
  return switch (customization.cardSurface) {
    HomeCardSurface.elevated => GalaxySurfaceVariant.raised,
    HomeCardSurface.outlined => GalaxySurfaceVariant.tonal,
    HomeCardSurface.flat => switch (customization.cardTint) {
      HomeCardTint.neutral => GalaxySurfaceVariant.flat,
      HomeCardTint.subtle => GalaxySurfaceVariant.tonal,
      HomeCardTint.strong => GalaxySurfaceVariant.interactive,
    },
  };
}

BoxDecoration homeSectionPanelDecoration(
  BuildContext context,
  HomeCustomization customization,
) {
  final scheme = Theme.of(context).colorScheme;
  return BoxDecoration(
    color: Color.alphaBlend(
      scheme.primary.withValues(alpha: 0.035),
      scheme.surfaceContainerLowest,
    ),
  );
}

BoxDecoration homeCoverSurfaceDecoration({
  required BuildContext context,
  required HomeCustomization customization,
  required double radius,
}) {
  final scheme = Theme.of(context).colorScheme;
  final surface = customization.cardSurface;
  return BoxDecoration(
    color: homeCardColor(scheme, customization.cardTint),
    borderRadius: BorderRadius.circular(radius),
    border: surface == HomeCardSurface.outlined
        ? Border.all(color: scheme.outlineVariant.withValues(alpha: 0.58))
        : null,
    boxShadow: surface == HomeCardSurface.elevated
        ? [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.14),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ]
        : null,
  );
}
