abstract final class GalaxyMetrics {
  static const radiusSmall = 8.0;
  static const radiusControl = 12.0;
  static const radiusCard = 16.0;
  static const radiusOverlay = 24.0;
  static const minimumTouchTarget = 48.0;
  static const coverAspectRatio = 2 / 3;

  static const space2 = 2.0;
  static const space4 = 4.0;
  static const space8 = 8.0;
  static const space12 = 12.0;
  static const space16 = 16.0;
  static const space20 = 20.0;
  static const space24 = 24.0;
  static const space32 = 32.0;
}

@Deprecated('Use GalaxyMetrics instead.')
abstract final class AppVisualMetrics {
  static const radiusSmall = GalaxyMetrics.radiusSmall;
  static const radiusControl = GalaxyMetrics.radiusControl;
  static const radiusCard = GalaxyMetrics.radiusCard;
  static const radiusOverlay = GalaxyMetrics.radiusOverlay;
  static const minimumTouchTarget = GalaxyMetrics.minimumTouchTarget;
  static const themeTransition = Duration(milliseconds: 220);
}
