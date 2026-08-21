import '../domain/library_customization.dart';

double libraryOuterPadding(LibraryDensity density) => switch (density) {
  LibraryDensity.compact => 12,
  LibraryDensity.balanced => 16,
  LibraryDensity.comfortable => 20,
};

double libraryCardSpacing(LibraryDensity density) => switch (density) {
  LibraryDensity.compact => 8,
  LibraryDensity.balanced => 10,
  LibraryDensity.comfortable => 14,
};

double librarySectionSpacing(LibraryDensity density) => switch (density) {
  LibraryDensity.compact => 10,
  LibraryDensity.balanced => 14,
  LibraryDensity.comfortable => 18,
};

double libraryCornerRadius(LibraryCardCorner corner) => switch (corner) {
  LibraryCardCorner.soft => 18,
  LibraryCardCorner.medium => 12,
  LibraryCardCorner.almostSquare => 4,
};

double libraryMinimumCardWidth(LibraryCardSize size) => switch (size) {
  LibraryCardSize.small => 104,
  LibraryCardSize.medium => 132,
  LibraryCardSize.large => 164,
};

int libraryMaximumColumns(LibraryCardSize size) => switch (size) {
  LibraryCardSize.small => 6,
  LibraryCardSize.medium => 5,
  LibraryCardSize.large => 4,
};

double libraryGridTileExtent(
  double cardWidth,
  LibraryCustomization customization,
  double textScale,
) {
  final coverHeight = cardWidth * 1.5;
  if (customization.gridTemplate == LibraryGridTemplate.coverOnly) {
    return coverHeight;
  }
  final baseTextHeight = customization.cardSize == LibraryCardSize.small
      ? 76.0
      : customization.cardSize == LibraryCardSize.large
      ? 92.0
      : 84.0;
  final scaledTextHeight = baseTextHeight * textScale.clamp(1, 1.55);
  final accessibilityAllowance = 48.0 * (textScale - 1).clamp(0.0, 1.0);
  return coverHeight + scaledTextHeight + accessibilityAllowance;
}

double libraryListCoverWidth(LibraryCardSize size) => switch (size) {
  LibraryCardSize.small => 56,
  LibraryCardSize.medium => 72,
  LibraryCardSize.large => 92,
};

double libraryListMinimumHeight(LibraryCardSize size) => switch (size) {
  LibraryCardSize.small => 88,
  LibraryCardSize.medium => 112,
  LibraryCardSize.large => 140,
};
