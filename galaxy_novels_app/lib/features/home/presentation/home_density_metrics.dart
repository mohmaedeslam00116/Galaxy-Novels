import '../domain/home_customization.dart';

extension HomeDensityMetrics on HomeDensity {
  double get scale => switch (this) {
    HomeDensity.compact => 0.88,
    HomeDensity.balanced => 1,
    HomeDensity.comfortable => 1.12,
  };

  double get horizontalPadding => switch (this) {
    HomeDensity.compact => 12,
    HomeDensity.balanced => 16,
    HomeDensity.comfortable => 20,
  };

  double get itemSpacing => switch (this) {
    HomeDensity.compact => 8,
    HomeDensity.balanced => 12,
    HomeDensity.comfortable => 16,
  };

  double get sectionSpacing => switch (this) {
    HomeDensity.compact => 24,
    HomeDensity.balanced => 28,
    HomeDensity.comfortable => 32,
  };
}
