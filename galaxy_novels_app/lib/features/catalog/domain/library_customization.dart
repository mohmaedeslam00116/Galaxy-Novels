import 'package:flutter/foundation.dart';

import 'catalog_query.dart';

enum LibraryLayout { grid, list }

enum LibraryGridTemplate { calmPoster, coverOnly }

enum LibraryListTemplate { detailed, compact }

enum LibraryCardSize { small, medium, large }

enum LibraryDensity { compact, balanced, comfortable }

enum LibraryCoverPresentation { fill, fit, tonalFrame }

enum LibraryCardSurface { flat, outlined, elevated }

enum LibraryCardCorner { soft, medium, almostSquare }

enum LibraryCardField { status, chapters, rating, firstGenre }

enum LibraryCustomizationPreset { balanced, quick, visual }

class LibraryCustomization {
  factory LibraryCustomization({
    required LibraryLayout layout,
    required LibraryGridTemplate gridTemplate,
    required LibraryListTemplate listTemplate,
    required LibraryCardSize cardSize,
    required LibraryDensity density,
    required LibraryCoverPresentation coverPresentation,
    required LibraryCardSurface cardSurface,
    required LibraryCardCorner cardCorner,
    required Set<LibraryCardField> visibleFields,
    required CatalogSort defaultSort,
    required bool rememberViewAndSort,
    required bool pinCompactSearch,
  }) {
    return LibraryCustomization._(
      layout: layout,
      gridTemplate: gridTemplate,
      listTemplate: listTemplate,
      cardSize: cardSize,
      density: density,
      coverPresentation: coverPresentation,
      cardSurface: cardSurface,
      cardCorner: cardCorner,
      visibleFields: Set.unmodifiable(
        visibleFields.intersection(LibraryCardField.values.toSet()),
      ),
      defaultSort: defaultSort,
      rememberViewAndSort: rememberViewAndSort,
      pinCompactSearch: pinCompactSearch,
    );
  }

  const LibraryCustomization._({
    required this.layout,
    required this.gridTemplate,
    required this.listTemplate,
    required this.cardSize,
    required this.density,
    required this.coverPresentation,
    required this.cardSurface,
    required this.cardCorner,
    required this.visibleFields,
    required this.defaultSort,
    required this.rememberViewAndSort,
    required this.pinCompactSearch,
  });

  static const version = 1;

  static final defaults = LibraryCustomization(
    layout: LibraryLayout.grid,
    gridTemplate: LibraryGridTemplate.calmPoster,
    listTemplate: LibraryListTemplate.detailed,
    cardSize: LibraryCardSize.medium,
    density: LibraryDensity.balanced,
    coverPresentation: LibraryCoverPresentation.fill,
    cardSurface: LibraryCardSurface.outlined,
    cardCorner: LibraryCardCorner.medium,
    visibleFields: const {
      LibraryCardField.status,
      LibraryCardField.chapters,
      LibraryCardField.rating,
    },
    defaultSort: CatalogSort.latest,
    rememberViewAndSort: true,
    pinCompactSearch: true,
  );

  final LibraryLayout layout;
  final LibraryGridTemplate gridTemplate;
  final LibraryListTemplate listTemplate;
  final LibraryCardSize cardSize;
  final LibraryDensity density;
  final LibraryCoverPresentation coverPresentation;
  final LibraryCardSurface cardSurface;
  final LibraryCardCorner cardCorner;
  final Set<LibraryCardField> visibleFields;
  final CatalogSort defaultSort;
  final bool rememberViewAndSort;
  final bool pinCompactSearch;

  bool shows(LibraryCardField field) => visibleFields.contains(field);

  LibraryCustomization copyWith({
    LibraryLayout? layout,
    LibraryGridTemplate? gridTemplate,
    LibraryListTemplate? listTemplate,
    LibraryCardSize? cardSize,
    LibraryDensity? density,
    LibraryCoverPresentation? coverPresentation,
    LibraryCardSurface? cardSurface,
    LibraryCardCorner? cardCorner,
    Set<LibraryCardField>? visibleFields,
    CatalogSort? defaultSort,
    bool? rememberViewAndSort,
    bool? pinCompactSearch,
  }) {
    return LibraryCustomization(
      layout: layout ?? this.layout,
      gridTemplate: gridTemplate ?? this.gridTemplate,
      listTemplate: listTemplate ?? this.listTemplate,
      cardSize: cardSize ?? this.cardSize,
      density: density ?? this.density,
      coverPresentation: coverPresentation ?? this.coverPresentation,
      cardSurface: cardSurface ?? this.cardSurface,
      cardCorner: cardCorner ?? this.cardCorner,
      visibleFields: visibleFields ?? this.visibleFields,
      defaultSort: defaultSort ?? this.defaultSort,
      rememberViewAndSort: rememberViewAndSort ?? this.rememberViewAndSort,
      pinCompactSearch: pinCompactSearch ?? this.pinCompactSearch,
    );
  }

  LibraryCustomization applyPreset(LibraryCustomizationPreset preset) {
    return LibraryCustomization.forPreset(preset);
  }

  static LibraryCustomization forPreset(LibraryCustomizationPreset preset) {
    return switch (preset) {
      LibraryCustomizationPreset.balanced => defaults,
      LibraryCustomizationPreset.quick => LibraryCustomization(
        layout: LibraryLayout.list,
        gridTemplate: LibraryGridTemplate.calmPoster,
        listTemplate: LibraryListTemplate.compact,
        cardSize: LibraryCardSize.small,
        density: LibraryDensity.compact,
        coverPresentation: LibraryCoverPresentation.fill,
        cardSurface: LibraryCardSurface.flat,
        cardCorner: LibraryCardCorner.medium,
        visibleFields: const {
          LibraryCardField.status,
          LibraryCardField.chapters,
        },
        defaultSort: CatalogSort.latest,
        rememberViewAndSort: true,
        pinCompactSearch: true,
      ),
      LibraryCustomizationPreset.visual => LibraryCustomization(
        layout: LibraryLayout.grid,
        gridTemplate: LibraryGridTemplate.coverOnly,
        listTemplate: LibraryListTemplate.detailed,
        cardSize: LibraryCardSize.large,
        density: LibraryDensity.comfortable,
        coverPresentation: LibraryCoverPresentation.tonalFrame,
        cardSurface: LibraryCardSurface.elevated,
        cardCorner: LibraryCardCorner.soft,
        visibleFields: const {
          LibraryCardField.status,
          LibraryCardField.rating,
          LibraryCardField.firstGenre,
        },
        defaultSort: CatalogSort.latest,
        rememberViewAndSort: true,
        pinCompactSearch: true,
      ),
    };
  }

  factory LibraryCustomization.fromJson(Map<String, dynamic> json) {
    return LibraryCustomization(
      layout: _enumValue(
        json['layout'],
        LibraryLayout.values,
        LibraryLayout.grid,
      ),
      gridTemplate: _enumValue(
        json['grid_template'],
        LibraryGridTemplate.values,
        LibraryGridTemplate.calmPoster,
      ),
      listTemplate: _enumValue(
        json['list_template'],
        LibraryListTemplate.values,
        LibraryListTemplate.detailed,
      ),
      cardSize: _enumValue(
        json['card_size'],
        LibraryCardSize.values,
        LibraryCardSize.medium,
      ),
      density: _enumValue(
        json['density'],
        LibraryDensity.values,
        LibraryDensity.balanced,
      ),
      coverPresentation: _enumValue(
        json['cover_presentation'],
        LibraryCoverPresentation.values,
        LibraryCoverPresentation.fill,
      ),
      cardSurface: _enumValue(
        json['card_surface'],
        LibraryCardSurface.values,
        LibraryCardSurface.outlined,
      ),
      cardCorner: _enumValue(
        json['card_corner'],
        LibraryCardCorner.values,
        LibraryCardCorner.medium,
      ),
      visibleFields: _enumSet(
        json['visible_fields'],
        LibraryCardField.values,
        defaults.visibleFields,
      ),
      defaultSort: _enumValue(
        json['default_sort'],
        CatalogSort.values,
        CatalogSort.latest,
      ),
      rememberViewAndSort: _boolValue(json['remember_view_and_sort'], true),
      pinCompactSearch: _boolValue(json['pin_compact_search'], true),
    );
  }

  Map<String, dynamic> toJson() => {
    'version': version,
    'layout': layout.name,
    'grid_template': gridTemplate.name,
    'list_template': listTemplate.name,
    'card_size': cardSize.name,
    'density': density.name,
    'cover_presentation': coverPresentation.name,
    'card_surface': cardSurface.name,
    'card_corner': cardCorner.name,
    'visible_fields': visibleFields.map((field) => field.name).toList(),
    'default_sort': defaultSort.name,
    'remember_view_and_sort': rememberViewAndSort,
    'pin_compact_search': pinCompactSearch,
  };

  @override
  bool operator ==(Object other) {
    return other is LibraryCustomization &&
        other.layout == layout &&
        other.gridTemplate == gridTemplate &&
        other.listTemplate == listTemplate &&
        other.cardSize == cardSize &&
        other.density == density &&
        other.coverPresentation == coverPresentation &&
        other.cardSurface == cardSurface &&
        other.cardCorner == cardCorner &&
        setEquals(other.visibleFields, visibleFields) &&
        other.defaultSort == defaultSort &&
        other.rememberViewAndSort == rememberViewAndSort &&
        other.pinCompactSearch == pinCompactSearch;
  }

  @override
  int get hashCode => Object.hash(
    layout,
    gridTemplate,
    listTemplate,
    cardSize,
    density,
    coverPresentation,
    cardSurface,
    cardCorner,
    Object.hashAllUnordered(visibleFields),
    defaultSort,
    rememberViewAndSort,
    pinCompactSearch,
  );
}

T _enumValue<T extends Enum>(Object? value, List<T> values, T fallback) {
  if (value is! String) return fallback;
  return values.where((item) => item.name == value).firstOrNull ?? fallback;
}

Set<T> _enumSet<T extends Enum>(
  Object? value,
  List<T> values,
  Set<T> fallback,
) {
  if (value is! List) return fallback.toSet();
  final names = value.whereType<String>().toSet();
  return values.where((item) => names.contains(item.name)).toSet();
}

bool _boolValue(Object? value, bool fallback) {
  return value is bool ? value : fallback;
}
