import 'package:flutter/foundation.dart';

enum HomeSectionId {
  continueReading,
  becauseYouRead,
  updatedNovels,
  latestUpdates,
}

enum HomeDensity { compact, balanced, comfortable }

enum HomeHeaderStyle { standard, simple }

/// Kept as a compatibility view over [ContinueReadingCardTemplate].
enum ContinueReadingLayout { cards, compactStrip, coverFocus }

enum UpdatedNovelsLayout { horizontalStrip, grid }

enum RecommendedNovelsLayout { horizontalStrip, grid }

enum LatestUpdatesLayout { horizontalStrip, detailedList, grid }

enum HomeItemCount { few, medium, all }

enum HomeCustomizationPreset { balanced, quick, visual }

enum HomeCoverCorner { soft, medium, almostSquare }

enum HomeCardSurface { flat, outlined, elevated }

enum HomeCardTint { neutral, subtle, strong }

enum HomeProgressStyle { bar, ring, percentage, hidden }

enum HomeCardSize { small, medium, large }

enum HomeSectionContainer { open, softPanel }

enum HomeCoverPresentation { fill, fit, tonalFrame }

enum ContinueReadingCardTemplate { detailed, compactStrip, coverFocus }

enum UpdatedNovelCardTemplate { poster, horizontal, coverOnly }

enum RecommendedNovelCardTemplate { poster, horizontal, coverOnly }

enum LatestUpdateCardTemplate { detailed, compact, poster }

enum HomeCardField {
  chapter,
  progress,
  status,
  chapterCount,
  firstGenre,
  date,
  secondChapter,
  matchReason,
}

class HomeCustomization {
  factory HomeCustomization({
    required List<HomeSectionId> sectionOrder,
    required Set<HomeSectionId> hiddenSections,
    required HomeDensity density,
    required HomeHeaderStyle headerStyle,
    required UpdatedNovelsLayout updatedNovelsLayout,
    required RecommendedNovelsLayout recommendedNovelsLayout,
    required LatestUpdatesLayout latestUpdatesLayout,
    required Map<HomeSectionId, HomeItemCount> itemCounts,
    required Set<HomeSectionId> knownSections,
    required HomeCoverCorner coverCorner,
    required HomeCardSurface cardSurface,
    required HomeCardTint cardTint,
    required HomeProgressStyle progressStyle,
    required ContinueReadingCardTemplate continueReadingTemplate,
    required UpdatedNovelCardTemplate updatedNovelsTemplate,
    required RecommendedNovelCardTemplate recommendedNovelsTemplate,
    required LatestUpdateCardTemplate latestUpdatesTemplate,
    required Map<HomeSectionId, HomeCardSize> cardSizes,
    required Map<HomeSectionId, Set<HomeCardField>> optionalFields,
    required Map<HomeSectionId, bool> quickActions,
    required Map<HomeSectionId, HomeSectionContainer> sectionContainers,
    required Map<HomeSectionId, HomeCoverPresentation> coverPresentations,
  }) {
    return HomeCustomization._(
      sectionOrder: List.unmodifiable(_normalizedOrder(sectionOrder)),
      hiddenSections: Set.unmodifiable(_normalizedHidden(hiddenSections)),
      density: density,
      headerStyle: headerStyle,
      updatedNovelsLayout: updatedNovelsLayout,
      recommendedNovelsLayout: recommendedNovelsLayout,
      latestUpdatesLayout: latestUpdatesLayout,
      itemCounts: Map.unmodifiable(_normalizedItemCounts(itemCounts)),
      knownSections: Set.unmodifiable(
        knownSections.intersection(HomeSectionId.values.toSet()),
      ),
      coverCorner: coverCorner,
      cardSurface: cardSurface,
      cardTint: cardTint,
      progressStyle: progressStyle,
      continueReadingTemplate: continueReadingTemplate,
      updatedNovelsTemplate: updatedNovelsTemplate,
      recommendedNovelsTemplate: recommendedNovelsTemplate,
      latestUpdatesTemplate: latestUpdatesTemplate,
      cardSizes: Map.unmodifiable(_normalizedCardSizes(cardSizes)),
      optionalFields: Map.unmodifiable(
        _normalizedOptionalFields(optionalFields),
      ),
      quickActions: Map.unmodifiable(_normalizedQuickActions(quickActions)),
      sectionContainers: Map.unmodifiable(
        _normalizedSectionContainers(sectionContainers),
      ),
      coverPresentations: Map.unmodifiable(
        _normalizedCoverPresentations(coverPresentations),
      ),
    );
  }

  const HomeCustomization._({
    required this.sectionOrder,
    required this.hiddenSections,
    required this.density,
    required this.headerStyle,
    required this.updatedNovelsLayout,
    required this.recommendedNovelsLayout,
    required this.latestUpdatesLayout,
    required this.itemCounts,
    required this.knownSections,
    required this.coverCorner,
    required this.cardSurface,
    required this.cardTint,
    required this.progressStyle,
    required this.continueReadingTemplate,
    required this.updatedNovelsTemplate,
    required this.recommendedNovelsTemplate,
    required this.latestUpdatesTemplate,
    required this.cardSizes,
    required this.optionalFields,
    required this.quickActions,
    required this.sectionContainers,
    required this.coverPresentations,
  });

  static const version = 4;
  static const defaultSectionOrder = [
    HomeSectionId.continueReading,
    HomeSectionId.becauseYouRead,
    HomeSectionId.updatedNovels,
    HomeSectionId.latestUpdates,
  ];

  static final defaults = HomeCustomization(
    sectionOrder: defaultSectionOrder,
    hiddenSections: const {},
    density: HomeDensity.balanced,
    headerStyle: HomeHeaderStyle.standard,
    updatedNovelsLayout: UpdatedNovelsLayout.horizontalStrip,
    recommendedNovelsLayout: RecommendedNovelsLayout.horizontalStrip,
    latestUpdatesLayout: LatestUpdatesLayout.detailedList,
    itemCounts: _defaultItemCounts,
    knownSections: HomeSectionId.values.toSet(),
    coverCorner: HomeCoverCorner.soft,
    cardSurface: HomeCardSurface.outlined,
    cardTint: HomeCardTint.neutral,
    progressStyle: HomeProgressStyle.bar,
    continueReadingTemplate: ContinueReadingCardTemplate.detailed,
    updatedNovelsTemplate: UpdatedNovelCardTemplate.poster,
    recommendedNovelsTemplate: RecommendedNovelCardTemplate.poster,
    latestUpdatesTemplate: LatestUpdateCardTemplate.detailed,
    cardSizes: _defaultCardSizes,
    optionalFields: _defaultOptionalFields,
    quickActions: _defaultQuickActions,
    sectionContainers: _defaultSectionContainers,
    coverPresentations: _defaultCoverPresentations,
  );

  final List<HomeSectionId> sectionOrder;
  final Set<HomeSectionId> hiddenSections;
  final HomeDensity density;
  final HomeHeaderStyle headerStyle;
  final UpdatedNovelsLayout updatedNovelsLayout;
  final RecommendedNovelsLayout recommendedNovelsLayout;
  final LatestUpdatesLayout latestUpdatesLayout;
  final Map<HomeSectionId, HomeItemCount> itemCounts;
  final Set<HomeSectionId> knownSections;
  final HomeCoverCorner coverCorner;
  final HomeCardSurface cardSurface;
  final HomeCardTint cardTint;
  final HomeProgressStyle progressStyle;
  final ContinueReadingCardTemplate continueReadingTemplate;
  final UpdatedNovelCardTemplate updatedNovelsTemplate;
  final RecommendedNovelCardTemplate recommendedNovelsTemplate;
  final LatestUpdateCardTemplate latestUpdatesTemplate;
  final Map<HomeSectionId, HomeCardSize> cardSizes;
  final Map<HomeSectionId, Set<HomeCardField>> optionalFields;
  final Map<HomeSectionId, bool> quickActions;
  final Map<HomeSectionId, HomeSectionContainer> sectionContainers;
  final Map<HomeSectionId, HomeCoverPresentation> coverPresentations;

  ContinueReadingLayout get continueReadingLayout =>
      switch (continueReadingTemplate) {
        ContinueReadingCardTemplate.detailed => ContinueReadingLayout.cards,
        ContinueReadingCardTemplate.compactStrip =>
          ContinueReadingLayout.compactStrip,
        ContinueReadingCardTemplate.coverFocus =>
          ContinueReadingLayout.coverFocus,
      };

  Set<HomeSectionId> get newSections => HomeSectionId.values
      .where((section) => !knownSections.contains(section))
      .toSet();

  bool isVisible(HomeSectionId section) => !hiddenSections.contains(section);

  bool showsField(HomeSectionId section, HomeCardField field) =>
      optionalFields[section]?.contains(field) ?? false;

  bool showsQuickAction(HomeSectionId section) => quickActions[section] ?? true;

  HomeCardSize cardSizeFor(HomeSectionId section) =>
      cardSizes[section] ?? HomeCardSize.medium;

  HomeSectionContainer containerFor(HomeSectionId section) =>
      sectionContainers[section] ?? HomeSectionContainer.open;

  HomeCoverPresentation coverPresentationFor(HomeSectionId section) =>
      coverPresentations[section] ?? HomeCoverPresentation.fill;

  int? itemLimitFor(HomeSectionId section) {
    return switch (itemCounts[section] ?? HomeItemCount.medium) {
      HomeItemCount.few => 4,
      HomeItemCount.medium => 8,
      HomeItemCount.all => section == HomeSectionId.becauseYouRead ? 12 : null,
    };
  }

  HomeCustomization markAllSectionsKnown() {
    return copyWith(knownSections: HomeSectionId.values.toSet());
  }

  HomeCustomization copyWith({
    List<HomeSectionId>? sectionOrder,
    Set<HomeSectionId>? hiddenSections,
    HomeDensity? density,
    HomeHeaderStyle? headerStyle,
    ContinueReadingLayout? continueReadingLayout,
    UpdatedNovelsLayout? updatedNovelsLayout,
    RecommendedNovelsLayout? recommendedNovelsLayout,
    LatestUpdatesLayout? latestUpdatesLayout,
    Map<HomeSectionId, HomeItemCount>? itemCounts,
    Set<HomeSectionId>? knownSections,
    HomeCoverCorner? coverCorner,
    HomeCardSurface? cardSurface,
    HomeCardTint? cardTint,
    HomeProgressStyle? progressStyle,
    ContinueReadingCardTemplate? continueReadingTemplate,
    UpdatedNovelCardTemplate? updatedNovelsTemplate,
    RecommendedNovelCardTemplate? recommendedNovelsTemplate,
    LatestUpdateCardTemplate? latestUpdatesTemplate,
    Map<HomeSectionId, HomeCardSize>? cardSizes,
    Map<HomeSectionId, Set<HomeCardField>>? optionalFields,
    Map<HomeSectionId, bool>? quickActions,
    Map<HomeSectionId, HomeSectionContainer>? sectionContainers,
    Map<HomeSectionId, HomeCoverPresentation>? coverPresentations,
  }) {
    return HomeCustomization(
      sectionOrder: sectionOrder ?? this.sectionOrder,
      hiddenSections: hiddenSections ?? this.hiddenSections,
      density: density ?? this.density,
      headerStyle: headerStyle ?? this.headerStyle,
      updatedNovelsLayout: updatedNovelsLayout ?? this.updatedNovelsLayout,
      recommendedNovelsLayout:
          recommendedNovelsLayout ?? this.recommendedNovelsLayout,
      latestUpdatesLayout: latestUpdatesLayout ?? this.latestUpdatesLayout,
      itemCounts: itemCounts ?? this.itemCounts,
      knownSections: knownSections ?? this.knownSections,
      coverCorner: coverCorner ?? this.coverCorner,
      cardSurface: cardSurface ?? this.cardSurface,
      cardTint: cardTint ?? this.cardTint,
      progressStyle: progressStyle ?? this.progressStyle,
      continueReadingTemplate:
          continueReadingTemplate ??
          (continueReadingLayout == null
              ? this.continueReadingTemplate
              : _templateForLegacyLayout(continueReadingLayout)),
      updatedNovelsTemplate:
          updatedNovelsTemplate ?? this.updatedNovelsTemplate,
      recommendedNovelsTemplate:
          recommendedNovelsTemplate ?? this.recommendedNovelsTemplate,
      latestUpdatesTemplate:
          latestUpdatesTemplate ?? this.latestUpdatesTemplate,
      cardSizes: cardSizes ?? this.cardSizes,
      optionalFields: optionalFields ?? this.optionalFields,
      quickActions: quickActions ?? this.quickActions,
      sectionContainers: sectionContainers ?? this.sectionContainers,
      coverPresentations: coverPresentations ?? this.coverPresentations,
    );
  }

  HomeCustomization applyPreset(HomeCustomizationPreset preset) {
    final style = HomeCustomization.forPreset(preset);
    return copyWith(
      density: style.density,
      headerStyle: style.headerStyle,
      updatedNovelsLayout: style.updatedNovelsLayout,
      recommendedNovelsLayout: style.recommendedNovelsLayout,
      latestUpdatesLayout: style.latestUpdatesLayout,
      itemCounts: style.itemCounts,
      coverCorner: style.coverCorner,
      cardSurface: style.cardSurface,
      cardTint: style.cardTint,
      progressStyle: style.progressStyle,
      continueReadingTemplate: style.continueReadingTemplate,
      updatedNovelsTemplate: style.updatedNovelsTemplate,
      recommendedNovelsTemplate: style.recommendedNovelsTemplate,
      latestUpdatesTemplate: style.latestUpdatesTemplate,
      cardSizes: style.cardSizes,
      optionalFields: style.optionalFields,
      quickActions: style.quickActions,
      sectionContainers: style.sectionContainers,
      coverPresentations: style.coverPresentations,
    );
  }

  HomeCustomization resetSection(HomeSectionId section) {
    final balanced = HomeCustomization.defaults;
    final counts = Map<HomeSectionId, HomeItemCount>.of(itemCounts)
      ..[section] = balanced.itemCounts[section]!;
    final sizes = Map<HomeSectionId, HomeCardSize>.of(cardSizes)
      ..[section] = balanced.cardSizes[section]!;
    final fields = {
      for (final entry in optionalFields.entries)
        entry.key: entry.value.toSet(),
    }..[section] = balanced.optionalFields[section]!.toSet();
    final actions = Map<HomeSectionId, bool>.of(quickActions)
      ..[section] = balanced.quickActions[section]!;
    final containers = Map<HomeSectionId, HomeSectionContainer>.of(
      sectionContainers,
    )..[section] = balanced.sectionContainers[section]!;
    final covers = Map<HomeSectionId, HomeCoverPresentation>.of(
      coverPresentations,
    )..[section] = balanced.coverPresentations[section]!;
    final common = copyWith(
      itemCounts: counts,
      cardSizes: sizes,
      optionalFields: fields,
      quickActions: actions,
      sectionContainers: containers,
      coverPresentations: covers,
    );
    return switch (section) {
      HomeSectionId.continueReading => common.copyWith(
        continueReadingTemplate: balanced.continueReadingTemplate,
      ),
      HomeSectionId.becauseYouRead => common.copyWith(
        recommendedNovelsTemplate: balanced.recommendedNovelsTemplate,
        recommendedNovelsLayout: balanced.recommendedNovelsLayout,
      ),
      HomeSectionId.updatedNovels => common.copyWith(
        updatedNovelsTemplate: balanced.updatedNovelsTemplate,
        updatedNovelsLayout: balanced.updatedNovelsLayout,
      ),
      HomeSectionId.latestUpdates => common.copyWith(
        latestUpdatesTemplate: balanced.latestUpdatesTemplate,
        latestUpdatesLayout: balanced.latestUpdatesLayout,
      ),
    };
  }

  factory HomeCustomization.fromJson(Map<String, dynamic> json) {
    final hasKnownSections = json.containsKey('known_sections');
    final storedVersion = json['version'] is num
        ? (json['version'] as num).toInt()
        : 1;
    return HomeCustomization(
      sectionOrder: _enumList(json['section_order'], HomeSectionId.values),
      hiddenSections: _enumList(
        json['hidden_sections'],
        HomeSectionId.values,
      ).toSet(),
      density: _enumValue(
        json['density'],
        HomeDensity.values,
        HomeDensity.balanced,
      ),
      headerStyle: _enumValue(
        json['header_style'],
        HomeHeaderStyle.values,
        HomeHeaderStyle.standard,
      ),
      updatedNovelsLayout: _enumValue(
        json['updated_novels_layout'],
        UpdatedNovelsLayout.values,
        UpdatedNovelsLayout.horizontalStrip,
      ),
      recommendedNovelsLayout: _enumValue(
        json['recommended_novels_layout'],
        RecommendedNovelsLayout.values,
        RecommendedNovelsLayout.horizontalStrip,
      ),
      latestUpdatesLayout: _enumValue(
        json['latest_updates_layout'],
        LatestUpdatesLayout.values,
        LatestUpdatesLayout.detailedList,
      ),
      itemCounts: _enumMap(
        json['item_counts'],
        HomeItemCount.values,
        HomeItemCount.medium,
      ),
      knownSections: hasKnownSections
          ? _enumList(json['known_sections'], HomeSectionId.values).toSet()
          : storedVersion < 4
          ? HomeSectionId.values
                .where((section) => section != HomeSectionId.becauseYouRead)
                .toSet()
          : HomeSectionId.values.toSet(),
      coverCorner: _enumValue(
        json['cover_corner'],
        HomeCoverCorner.values,
        HomeCoverCorner.soft,
      ),
      cardSurface: _enumValue(
        json['card_surface'],
        HomeCardSurface.values,
        HomeCardSurface.outlined,
      ),
      cardTint: _enumValue(
        json['card_tint'],
        HomeCardTint.values,
        HomeCardTint.neutral,
      ),
      progressStyle: _enumValue(
        json['progress_style'],
        HomeProgressStyle.values,
        HomeProgressStyle.bar,
      ),
      continueReadingTemplate: storedVersion < 2
          ? _templateForLegacyName(json['continue_reading_layout'])
          : _enumValue(
              json['continue_reading_template'],
              ContinueReadingCardTemplate.values,
              ContinueReadingCardTemplate.detailed,
            ),
      updatedNovelsTemplate: _enumValue(
        json['updated_novels_template'],
        UpdatedNovelCardTemplate.values,
        UpdatedNovelCardTemplate.poster,
      ),
      recommendedNovelsTemplate: _enumValue(
        json['recommended_novels_template'],
        RecommendedNovelCardTemplate.values,
        RecommendedNovelCardTemplate.poster,
      ),
      latestUpdatesTemplate: _enumValue(
        json['latest_updates_template'],
        LatestUpdateCardTemplate.values,
        LatestUpdateCardTemplate.detailed,
      ),
      cardSizes: _enumMap(
        json['card_sizes'],
        HomeCardSize.values,
        HomeCardSize.medium,
      ),
      optionalFields: _optionalFieldsFromJson(json['optional_fields']),
      quickActions: _boolMap(json['quick_actions']),
      sectionContainers: _enumMap(
        json['section_containers'],
        HomeSectionContainer.values,
        HomeSectionContainer.open,
      ),
      coverPresentations: storedVersion < 3
          ? const {}
          : _enumMap(
              json['cover_presentations'],
              HomeCoverPresentation.values,
              HomeCoverPresentation.fill,
            ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'section_order': sectionOrder.map((section) => section.name).toList(),
      'hidden_sections': hiddenSections.map((section) => section.name).toList(),
      'density': density.name,
      'header_style': headerStyle.name,
      'continue_reading_layout': continueReadingLayout.name,
      'updated_novels_layout': updatedNovelsLayout.name,
      'recommended_novels_layout': recommendedNovelsLayout.name,
      'latest_updates_layout': latestUpdatesLayout.name,
      'item_counts': _enumMapToJson(itemCounts),
      'known_sections': knownSections.map((section) => section.name).toList(),
      'cover_corner': coverCorner.name,
      'card_surface': cardSurface.name,
      'card_tint': cardTint.name,
      'progress_style': progressStyle.name,
      'continue_reading_template': continueReadingTemplate.name,
      'updated_novels_template': updatedNovelsTemplate.name,
      'recommended_novels_template': recommendedNovelsTemplate.name,
      'latest_updates_template': latestUpdatesTemplate.name,
      'card_sizes': _enumMapToJson(cardSizes),
      'optional_fields': {
        for (final entry in optionalFields.entries)
          entry.key.name: entry.value.map((field) => field.name).toList(),
      },
      'quick_actions': {
        for (final entry in quickActions.entries) entry.key.name: entry.value,
      },
      'section_containers': _enumMapToJson(sectionContainers),
      'cover_presentations': _enumMapToJson(coverPresentations),
    };
  }

  static HomeCustomization forPreset(HomeCustomizationPreset preset) {
    return switch (preset) {
      HomeCustomizationPreset.balanced => defaults,
      HomeCustomizationPreset.quick => HomeCustomization(
        sectionOrder: defaultSectionOrder,
        hiddenSections: const {},
        density: HomeDensity.compact,
        headerStyle: HomeHeaderStyle.simple,
        updatedNovelsLayout: UpdatedNovelsLayout.grid,
        recommendedNovelsLayout: RecommendedNovelsLayout.horizontalStrip,
        latestUpdatesLayout: LatestUpdatesLayout.detailedList,
        itemCounts: {
          for (final section in HomeSectionId.values)
            section: HomeItemCount.few,
        },
        knownSections: HomeSectionId.values.toSet(),
        coverCorner: HomeCoverCorner.medium,
        cardSurface: HomeCardSurface.flat,
        cardTint: HomeCardTint.neutral,
        progressStyle: HomeProgressStyle.percentage,
        continueReadingTemplate: ContinueReadingCardTemplate.compactStrip,
        updatedNovelsTemplate: UpdatedNovelCardTemplate.coverOnly,
        recommendedNovelsTemplate: RecommendedNovelCardTemplate.coverOnly,
        latestUpdatesTemplate: LatestUpdateCardTemplate.compact,
        cardSizes: {
          for (final section in HomeSectionId.values)
            section: HomeCardSize.small,
        },
        optionalFields: const {
          HomeSectionId.continueReading: {
            HomeCardField.chapter,
            HomeCardField.progress,
          },
          HomeSectionId.becauseYouRead: {HomeCardField.matchReason},
          HomeSectionId.updatedNovels: {},
          HomeSectionId.latestUpdates: {HomeCardField.date},
        },
        quickActions: _defaultQuickActions,
        sectionContainers: _defaultSectionContainers,
        coverPresentations: _defaultCoverPresentations,
      ),
      HomeCustomizationPreset.visual => HomeCustomization(
        sectionOrder: defaultSectionOrder,
        hiddenSections: const {},
        density: HomeDensity.comfortable,
        headerStyle: HomeHeaderStyle.standard,
        updatedNovelsLayout: UpdatedNovelsLayout.horizontalStrip,
        recommendedNovelsLayout: RecommendedNovelsLayout.grid,
        latestUpdatesLayout: LatestUpdatesLayout.grid,
        itemCounts: {
          for (final section in HomeSectionId.values)
            section: HomeItemCount.all,
        },
        knownSections: HomeSectionId.values.toSet(),
        coverCorner: HomeCoverCorner.soft,
        cardSurface: HomeCardSurface.elevated,
        cardTint: HomeCardTint.subtle,
        progressStyle: HomeProgressStyle.ring,
        continueReadingTemplate: ContinueReadingCardTemplate.coverFocus,
        updatedNovelsTemplate: UpdatedNovelCardTemplate.poster,
        recommendedNovelsTemplate: RecommendedNovelCardTemplate.poster,
        latestUpdatesTemplate: LatestUpdateCardTemplate.poster,
        cardSizes: {
          for (final section in HomeSectionId.values)
            section: HomeCardSize.large,
        },
        optionalFields: _defaultOptionalFields,
        quickActions: _defaultQuickActions,
        sectionContainers: {
          for (final section in HomeSectionId.values)
            section: HomeSectionContainer.softPanel,
        },
        coverPresentations: _visualCoverPresentations,
      ),
    };
  }

  @override
  bool operator ==(Object other) {
    return other is HomeCustomization &&
        listEquals(other.sectionOrder, sectionOrder) &&
        setEquals(other.hiddenSections, hiddenSections) &&
        other.density == density &&
        other.headerStyle == headerStyle &&
        other.updatedNovelsLayout == updatedNovelsLayout &&
        other.recommendedNovelsLayout == recommendedNovelsLayout &&
        other.latestUpdatesLayout == latestUpdatesLayout &&
        mapEquals(other.itemCounts, itemCounts) &&
        setEquals(other.knownSections, knownSections) &&
        other.coverCorner == coverCorner &&
        other.cardSurface == cardSurface &&
        other.cardTint == cardTint &&
        other.progressStyle == progressStyle &&
        other.continueReadingTemplate == continueReadingTemplate &&
        other.updatedNovelsTemplate == updatedNovelsTemplate &&
        other.recommendedNovelsTemplate == recommendedNovelsTemplate &&
        other.latestUpdatesTemplate == latestUpdatesTemplate &&
        mapEquals(other.cardSizes, cardSizes) &&
        _setMapEquals(other.optionalFields, optionalFields) &&
        mapEquals(other.quickActions, quickActions) &&
        mapEquals(other.sectionContainers, sectionContainers) &&
        mapEquals(other.coverPresentations, coverPresentations);
  }

  @override
  int get hashCode => Object.hashAll([
    Object.hashAll(sectionOrder),
    Object.hashAllUnordered(hiddenSections),
    density,
    headerStyle,
    updatedNovelsLayout,
    recommendedNovelsLayout,
    latestUpdatesLayout,
    Object.hashAllUnordered(itemCounts.entries),
    Object.hashAllUnordered(knownSections),
    coverCorner,
    cardSurface,
    cardTint,
    progressStyle,
    continueReadingTemplate,
    updatedNovelsTemplate,
    recommendedNovelsTemplate,
    latestUpdatesTemplate,
    Object.hashAllUnordered(cardSizes.entries),
    Object.hashAllUnordered(
      optionalFields.entries.map(
        (entry) => Object.hash(entry.key, Object.hashAllUnordered(entry.value)),
      ),
    ),
    Object.hashAllUnordered(quickActions.entries),
    Object.hashAllUnordered(sectionContainers.entries),
    Object.hashAllUnordered(coverPresentations.entries),
  ]);
}

const _defaultItemCounts = {
  HomeSectionId.continueReading: HomeItemCount.medium,
  HomeSectionId.becauseYouRead: HomeItemCount.medium,
  HomeSectionId.updatedNovels: HomeItemCount.medium,
  HomeSectionId.latestUpdates: HomeItemCount.medium,
};

const _defaultCardSizes = {
  HomeSectionId.continueReading: HomeCardSize.medium,
  HomeSectionId.becauseYouRead: HomeCardSize.medium,
  HomeSectionId.updatedNovels: HomeCardSize.medium,
  HomeSectionId.latestUpdates: HomeCardSize.medium,
};

const _defaultOptionalFields = {
  HomeSectionId.continueReading: {
    HomeCardField.chapter,
    HomeCardField.progress,
  },
  HomeSectionId.becauseYouRead: {
    HomeCardField.matchReason,
    HomeCardField.status,
    HomeCardField.chapterCount,
  },
  HomeSectionId.updatedNovels: {
    HomeCardField.status,
    HomeCardField.chapterCount,
    HomeCardField.firstGenre,
  },
  HomeSectionId.latestUpdates: {
    HomeCardField.status,
    HomeCardField.date,
    HomeCardField.secondChapter,
  },
};

const _defaultQuickActions = {
  HomeSectionId.continueReading: true,
  HomeSectionId.becauseYouRead: true,
  HomeSectionId.updatedNovels: true,
  HomeSectionId.latestUpdates: true,
};

const _defaultSectionContainers = {
  HomeSectionId.continueReading: HomeSectionContainer.open,
  HomeSectionId.becauseYouRead: HomeSectionContainer.open,
  HomeSectionId.updatedNovels: HomeSectionContainer.open,
  HomeSectionId.latestUpdates: HomeSectionContainer.open,
};

const _defaultCoverPresentations = {
  HomeSectionId.continueReading: HomeCoverPresentation.fill,
  HomeSectionId.becauseYouRead: HomeCoverPresentation.fill,
  HomeSectionId.updatedNovels: HomeCoverPresentation.fill,
  HomeSectionId.latestUpdates: HomeCoverPresentation.fill,
};

const _visualCoverPresentations = {
  HomeSectionId.continueReading: HomeCoverPresentation.tonalFrame,
  HomeSectionId.becauseYouRead: HomeCoverPresentation.tonalFrame,
  HomeSectionId.updatedNovels: HomeCoverPresentation.tonalFrame,
  HomeSectionId.latestUpdates: HomeCoverPresentation.tonalFrame,
};

Set<HomeCardField> _allowedFields(HomeSectionId section) => switch (section) {
  HomeSectionId.continueReading => const {
    HomeCardField.chapter,
    HomeCardField.progress,
  },
  HomeSectionId.becauseYouRead => const {
    HomeCardField.matchReason,
    HomeCardField.status,
    HomeCardField.chapterCount,
  },
  HomeSectionId.updatedNovels => const {
    HomeCardField.status,
    HomeCardField.chapterCount,
    HomeCardField.firstGenre,
  },
  HomeSectionId.latestUpdates => const {
    HomeCardField.status,
    HomeCardField.date,
    HomeCardField.secondChapter,
  },
};

List<HomeSectionId> _normalizedOrder(List<HomeSectionId> storedOrder) {
  final order = <HomeSectionId>[];
  for (final section in storedOrder) {
    if (!order.contains(section)) {
      order.add(section);
    }
  }
  for (
    var index = 0;
    index < HomeCustomization.defaultSectionOrder.length;
    index++
  ) {
    final section = HomeCustomization.defaultSectionOrder[index];
    if (!order.contains(section)) {
      order.insert(index.clamp(0, order.length), section);
    }
  }
  return order;
}

Set<HomeSectionId> _normalizedHidden(Set<HomeSectionId> hiddenSections) {
  final hidden = hiddenSections.intersection(HomeSectionId.values.toSet());
  if (hidden.length == HomeSectionId.values.length) {
    hidden.remove(HomeSectionId.latestUpdates);
  }
  return hidden;
}

Map<HomeSectionId, HomeItemCount> _normalizedItemCounts(
  Map<HomeSectionId, HomeItemCount> itemCounts,
) => {
  for (final section in HomeSectionId.values)
    section: itemCounts[section] ?? HomeItemCount.medium,
};

Map<HomeSectionId, HomeCardSize> _normalizedCardSizes(
  Map<HomeSectionId, HomeCardSize> cardSizes,
) => {
  for (final section in HomeSectionId.values)
    section: cardSizes[section] ?? HomeCardSize.medium,
};

Map<HomeSectionId, Set<HomeCardField>> _normalizedOptionalFields(
  Map<HomeSectionId, Set<HomeCardField>> fields,
) => {
  for (final section in HomeSectionId.values)
    section: Set.unmodifiable(
      (fields[section] ?? _defaultOptionalFields[section]!).intersection(
        _allowedFields(section),
      ),
    ),
};

Map<HomeSectionId, bool> _normalizedQuickActions(
  Map<HomeSectionId, bool> quickActions,
) => {
  for (final section in HomeSectionId.values)
    section: quickActions[section] ?? true,
};

Map<HomeSectionId, HomeSectionContainer> _normalizedSectionContainers(
  Map<HomeSectionId, HomeSectionContainer> containers,
) => {
  for (final section in HomeSectionId.values)
    section: containers[section] ?? HomeSectionContainer.open,
};

Map<HomeSectionId, HomeCoverPresentation> _normalizedCoverPresentations(
  Map<HomeSectionId, HomeCoverPresentation> presentations,
) => {
  for (final section in HomeSectionId.values)
    section: presentations[section] ?? HomeCoverPresentation.fill,
};

ContinueReadingCardTemplate _templateForLegacyLayout(
  ContinueReadingLayout layout,
) => switch (layout) {
  ContinueReadingLayout.cards => ContinueReadingCardTemplate.detailed,
  ContinueReadingLayout.compactStrip =>
    ContinueReadingCardTemplate.compactStrip,
  ContinueReadingLayout.coverFocus => ContinueReadingCardTemplate.coverFocus,
};

ContinueReadingCardTemplate _templateForLegacyName(Object? raw) =>
    switch (raw?.toString()) {
      'compactStrip' => ContinueReadingCardTemplate.compactStrip,
      'coverFocus' => ContinueReadingCardTemplate.coverFocus,
      _ => ContinueReadingCardTemplate.detailed,
    };

T _enumValue<T extends Enum>(Object? raw, List<T> values, T fallback) {
  final name = raw?.toString();
  for (final candidate in values) {
    if (candidate.name == name) {
      return candidate;
    }
  }
  return fallback;
}

List<T> _enumList<T extends Enum>(Object? raw, List<T> values) {
  if (raw is! List) {
    return const [];
  }
  final parsed = <T>[];
  for (final entry in raw) {
    for (final candidate in values) {
      if (candidate.name == entry.toString()) {
        parsed.add(candidate);
        break;
      }
    }
  }
  return parsed;
}

Map<HomeSectionId, T> _enumMap<T extends Enum>(
  Object? raw,
  List<T> values,
  T fallback,
) {
  if (raw is! Map) {
    return const {};
  }
  return {
    for (final section in HomeSectionId.values)
      if (raw.containsKey(section.name))
        section: _enumValue(raw[section.name], values, fallback),
  };
}

Map<HomeSectionId, bool> _boolMap(Object? raw) {
  if (raw is! Map) {
    return const {};
  }
  return {
    for (final section in HomeSectionId.values)
      if (raw[section.name] is bool) section: raw[section.name] as bool,
  };
}

Map<HomeSectionId, Set<HomeCardField>> _optionalFieldsFromJson(Object? raw) {
  if (raw is! Map) {
    return const {};
  }
  return {
    for (final section in HomeSectionId.values)
      if (raw.containsKey(section.name))
        section: _enumList(raw[section.name], HomeCardField.values).toSet(),
  };
}

Map<String, String> _enumMapToJson<T extends Enum>(Map<HomeSectionId, T> map) {
  return {for (final entry in map.entries) entry.key.name: entry.value.name};
}

bool _setMapEquals(
  Map<HomeSectionId, Set<HomeCardField>> first,
  Map<HomeSectionId, Set<HomeCardField>> second,
) {
  if (first.length != second.length) {
    return false;
  }
  for (final entry in first.entries) {
    if (!setEquals(entry.value, second[entry.key])) {
      return false;
    }
  }
  return true;
}
