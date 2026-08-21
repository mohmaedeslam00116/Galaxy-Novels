import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/features/home/data/shared_preferences_home_customization_store.dart';
import 'package:galaxy_novels_app/features/home/data/stored_home_customization_repository.dart';
import 'package:galaxy_novels_app/features/home/domain/home_customization.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('default customization matches the current home layout', () {
    final defaults = HomeCustomization.defaults;

    expect(HomeCustomization.version, 4);
    expect(defaults.sectionOrder, HomeCustomization.defaultSectionOrder);
    expect(defaults.sectionOrder[1], HomeSectionId.becauseYouRead);
    expect(defaults.hiddenSections, isEmpty);
    expect(defaults.density, HomeDensity.balanced);
    expect(defaults.itemLimitFor(HomeSectionId.latestUpdates), 8);
    expect(defaults.coverCorner, HomeCoverCorner.soft);
    expect(defaults.cardSurface, HomeCardSurface.outlined);
    expect(defaults.cardTint, HomeCardTint.neutral);
    expect(defaults.progressStyle, HomeProgressStyle.bar);
    expect(
      defaults.continueReadingTemplate,
      ContinueReadingCardTemplate.detailed,
    );
    expect(defaults.updatedNovelsTemplate, UpdatedNovelCardTemplate.poster);
    expect(
      defaults.recommendedNovelsTemplate,
      RecommendedNovelCardTemplate.poster,
    );
    expect(
      defaults.recommendedNovelsLayout,
      RecommendedNovelsLayout.horizontalStrip,
    );
    expect(defaults.latestUpdatesLayout, LatestUpdatesLayout.detailedList);
    expect(defaults.latestUpdatesTemplate, LatestUpdateCardTemplate.detailed);
    expect(defaults.itemLimitFor(HomeSectionId.becauseYouRead), 8);
    for (final section in HomeSectionId.values) {
      expect(defaults.cardSizes[section], HomeCardSize.medium);
      expect(defaults.quickActions[section], isTrue);
      expect(defaults.sectionContainers[section], HomeSectionContainer.open);
      expect(
        defaults.coverPresentationFor(section),
        HomeCoverPresentation.fill,
      );
    }
  });

  test('v1 settings migrate without losing order, visibility, or layouts', () {
    final customization = HomeCustomization.fromJson({
      'version': 1,
      'section_order': ['latestUpdates', 'continueReading', 'updatedNovels'],
      'hidden_sections': ['updatedNovels'],
      'density': 'compact',
      'header_style': 'simple',
      'continue_reading_layout': 'compactStrip',
      'updated_novels_layout': 'grid',
      'latest_updates_layout': 'grid',
      'item_counts': {'continueReading': 'few'},
      'known_sections': ['continueReading', 'updatedNovels', 'latestUpdates'],
    });

    expect(customization.sectionOrder.first, HomeSectionId.latestUpdates);
    expect(customization.hiddenSections, {HomeSectionId.updatedNovels});
    expect(customization.density, HomeDensity.compact);
    expect(customization.headerStyle, HomeHeaderStyle.simple);
    expect(
      customization.continueReadingTemplate,
      ContinueReadingCardTemplate.compactStrip,
    );
    expect(customization.updatedNovelsLayout, UpdatedNovelsLayout.grid);
    expect(customization.latestUpdatesLayout, LatestUpdatesLayout.grid);
    expect(customization.coverCorner, HomeCoverCorner.soft);
    expect(customization.cardSurface, HomeCardSurface.outlined);
    expect(
      customization.coverPresentationFor(HomeSectionId.continueReading),
      HomeCoverPresentation.fill,
    );
  });

  test('v4 round trip preserves card templates and section options', () {
    final configured = HomeCustomization.defaults.copyWith(
      coverCorner: HomeCoverCorner.almostSquare,
      cardSurface: HomeCardSurface.elevated,
      cardTint: HomeCardTint.strong,
      progressStyle: HomeProgressStyle.ring,
      continueReadingTemplate: ContinueReadingCardTemplate.coverFocus,
      updatedNovelsTemplate: UpdatedNovelCardTemplate.horizontal,
      recommendedNovelsTemplate: RecommendedNovelCardTemplate.coverOnly,
      recommendedNovelsLayout: RecommendedNovelsLayout.grid,
      latestUpdatesTemplate: LatestUpdateCardTemplate.compact,
      cardSizes: const {
        HomeSectionId.continueReading: HomeCardSize.large,
        HomeSectionId.updatedNovels: HomeCardSize.small,
        HomeSectionId.latestUpdates: HomeCardSize.medium,
      },
      optionalFields: const {
        HomeSectionId.continueReading: {HomeCardField.chapter},
        HomeSectionId.updatedNovels: {
          HomeCardField.status,
          HomeCardField.firstGenre,
        },
        HomeSectionId.latestUpdates: {HomeCardField.date},
      },
      quickActions: const {
        HomeSectionId.continueReading: false,
        HomeSectionId.updatedNovels: true,
        HomeSectionId.latestUpdates: false,
      },
      sectionContainers: const {
        HomeSectionId.continueReading: HomeSectionContainer.softPanel,
        HomeSectionId.updatedNovels: HomeSectionContainer.open,
        HomeSectionId.latestUpdates: HomeSectionContainer.softPanel,
      },
      coverPresentations: const {
        HomeSectionId.continueReading: HomeCoverPresentation.fit,
        HomeSectionId.updatedNovels: HomeCoverPresentation.tonalFrame,
        HomeSectionId.latestUpdates: HomeCoverPresentation.fill,
      },
    );

    final restored = HomeCustomization.fromJson(configured.toJson());

    expect(restored, configured);
    expect(restored.toJson()['version'], 4);
  });

  test('v4 round trip preserves the premium latest updates strip', () {
    final configured = HomeCustomization.defaults.copyWith(
      latestUpdatesLayout: LatestUpdatesLayout.horizontalStrip,
    );

    final restored = HomeCustomization.fromJson(configured.toJson());

    expect(restored.latestUpdatesLayout, LatestUpdatesLayout.horizontalStrip);
    expect(restored.toJson()['version'], 4);
  });

  test(
    'v3 migration inserts recommendations without reordering old sections',
    () {
      final customization = HomeCustomization.fromJson({
        'version': 3,
        'section_order': ['latestUpdates', 'continueReading', 'updatedNovels'],
        'known_sections': ['continueReading', 'updatedNovels', 'latestUpdates'],
        'cover_presentations': {'continueReading': 'fit'},
      });

      final oldOrder = customization.sectionOrder
          .where((section) => section != HomeSectionId.becauseYouRead)
          .toList(growable: false);
      expect(oldOrder, [
        HomeSectionId.latestUpdates,
        HomeSectionId.continueReading,
        HomeSectionId.updatedNovels,
      ]);
      expect(customization.newSections, {HomeSectionId.becauseYouRead});
      expect(customization.isVisible(HomeSectionId.becauseYouRead), isTrue);
      expect(
        customization.coverPresentationFor(HomeSectionId.continueReading),
        HomeCoverPresentation.fit,
      );
    },
  );

  test('v2 settings migrate with fill covers and preserve structure', () {
    final customization = HomeCustomization.fromJson({
      'version': 2,
      'section_order': ['latestUpdates', 'updatedNovels', 'continueReading'],
      'hidden_sections': ['continueReading'],
      'continue_reading_template': 'coverFocus',
      'updated_novels_template': 'horizontal',
      'latest_updates_template': 'poster',
    });

    expect(customization.sectionOrder.first, HomeSectionId.latestUpdates);
    expect(customization.hiddenSections, {HomeSectionId.continueReading});
    expect(
      customization.continueReadingTemplate,
      ContinueReadingCardTemplate.coverFocus,
    );
    for (final section in HomeSectionId.values) {
      expect(
        customization.coverPresentationFor(section),
        HomeCoverPresentation.fill,
      );
    }
  });

  test('unknown v2 card values fall back to balanced safe values', () {
    final customization = HomeCustomization.fromJson({
      'version': 2,
      'cover_corner': 'broken',
      'card_surface': 'broken',
      'card_tint': 'broken',
      'progress_style': 'broken',
      'continue_reading_template': 'broken',
      'updated_novels_template': 'broken',
      'latest_updates_template': 'broken',
      'latest_updates_layout': 'broken',
      'card_sizes': {'continueReading': 'broken'},
      'optional_fields': {
        'continueReading': ['unknown', 'chapter'],
      },
      'quick_actions': {'continueReading': 'not-a-bool'},
      'section_containers': {'continueReading': 'broken'},
      'cover_presentations': {'continueReading': 'broken'},
    });

    expect(customization.coverCorner, HomeCustomization.defaults.coverCorner);
    expect(customization.cardSurface, HomeCustomization.defaults.cardSurface);
    expect(customization.cardTint, HomeCustomization.defaults.cardTint);
    expect(
      customization.progressStyle,
      HomeCustomization.defaults.progressStyle,
    );
    expect(
      customization.continueReadingTemplate,
      HomeCustomization.defaults.continueReadingTemplate,
    );
    expect(
      customization.updatedNovelsTemplate,
      HomeCustomization.defaults.updatedNovelsTemplate,
    );
    expect(
      customization.latestUpdatesTemplate,
      HomeCustomization.defaults.latestUpdatesTemplate,
    );
    expect(
      customization.latestUpdatesLayout,
      HomeCustomization.defaults.latestUpdatesLayout,
    );
    expect(
      customization.cardSizes[HomeSectionId.continueReading],
      HomeCardSize.medium,
    );
    expect(customization.optionalFields[HomeSectionId.continueReading], {
      HomeCardField.chapter,
    });
    expect(customization.quickActions[HomeSectionId.continueReading], isTrue);
    expect(
      customization.sectionContainers[HomeSectionId.continueReading],
      HomeSectionContainer.open,
    );
    expect(
      customization.coverPresentationFor(HomeSectionId.continueReading),
      HomeCoverPresentation.fill,
    );
  });

  test(
    'stored customization repairs duplicates, unknown values, and all hidden',
    () {
      final customization = HomeCustomization.fromJson({
        'section_order': ['latestUpdates', 'unknownSection', 'latestUpdates'],
        'hidden_sections': [
          'continueReading',
          'updatedNovels',
          'latestUpdates',
        ],
        'density': 'compact',
        'item_counts': {'latestUpdates': 'all'},
        'known_sections': ['continueReading'],
      });

      expect(customization.sectionOrder.toSet(), HomeSectionId.values.toSet());
      expect(customization.sectionOrder, hasLength(4));
      expect(customization.isVisible(HomeSectionId.becauseYouRead), isTrue);
      expect(customization.density, HomeDensity.compact);
      expect(customization.itemLimitFor(HomeSectionId.latestUpdates), isNull);
      expect(customization.newSections, {
        HomeSectionId.becauseYouRead,
        HomeSectionId.updatedNovels,
        HomeSectionId.latestUpdates,
      });
    },
  );

  test('presets contain the approved layout combinations', () {
    final quick = HomeCustomization.forPreset(HomeCustomizationPreset.quick);
    final visual = HomeCustomization.forPreset(HomeCustomizationPreset.visual);

    expect(quick.density, HomeDensity.compact);
    expect(quick.headerStyle, HomeHeaderStyle.simple);
    expect(quick.continueReadingLayout, ContinueReadingLayout.compactStrip);
    expect(quick.updatedNovelsLayout, UpdatedNovelsLayout.grid);
    expect(
      quick.recommendedNovelsTemplate,
      RecommendedNovelCardTemplate.coverOnly,
    );
    expect(quick.updatedNovelsTemplate, UpdatedNovelCardTemplate.coverOnly);
    expect(quick.latestUpdatesTemplate, LatestUpdateCardTemplate.compact);
    expect(quick.cardSurface, HomeCardSurface.flat);
    expect(quick.progressStyle, HomeProgressStyle.percentage);
    expect(quick.itemLimitFor(HomeSectionId.continueReading), 4);
    expect(visual.density, HomeDensity.comfortable);
    expect(visual.latestUpdatesLayout, LatestUpdatesLayout.grid);
    expect(visual.recommendedNovelsLayout, RecommendedNovelsLayout.grid);
    expect(
      visual.continueReadingTemplate,
      ContinueReadingCardTemplate.coverFocus,
    );
    expect(visual.latestUpdatesTemplate, LatestUpdateCardTemplate.poster);
    expect(visual.cardSurface, HomeCardSurface.elevated);
    expect(visual.progressStyle, HomeProgressStyle.ring);
    expect(
      quick.coverPresentationFor(HomeSectionId.updatedNovels),
      HomeCoverPresentation.fill,
    );
    expect(
      visual.coverPresentationFor(HomeSectionId.updatedNovels),
      HomeCoverPresentation.tonalFrame,
    );
    expect(
      visual.sectionContainers.values,
      everyElement(HomeSectionContainer.softPanel),
    );
    expect(visual.itemLimitFor(HomeSectionId.latestUpdates), isNull);
    expect(visual.itemLimitFor(HomeSectionId.becauseYouRead), 12);
  });

  test(
    'applying a preset changes style but preserves order and visibility',
    () {
      final customized = HomeCustomization.defaults.copyWith(
        sectionOrder: const [
          HomeSectionId.latestUpdates,
          HomeSectionId.continueReading,
          HomeSectionId.updatedNovels,
        ],
        hiddenSections: const {HomeSectionId.updatedNovels},
        knownSections: const {HomeSectionId.continueReading},
      );

      final quick = customized.applyPreset(HomeCustomizationPreset.quick);

      expect(quick.sectionOrder, customized.sectionOrder);
      expect(quick.hiddenSections, customized.hiddenSections);
      expect(quick.knownSections, customized.knownSections);
      expect(quick.density, HomeDensity.compact);
      expect(quick.updatedNovelsTemplate, UpdatedNovelCardTemplate.coverOnly);
    },
  );

  test(
    'resetting a section keeps its position visibility and global style',
    () {
      final customized =
          HomeCustomization.forPreset(HomeCustomizationPreset.visual).copyWith(
            sectionOrder: const [
              HomeSectionId.latestUpdates,
              HomeSectionId.continueReading,
              HomeSectionId.updatedNovels,
            ],
            hiddenSections: const {HomeSectionId.updatedNovels},
            cardSizes: const {
              HomeSectionId.continueReading: HomeCardSize.large,
              HomeSectionId.updatedNovels: HomeCardSize.large,
              HomeSectionId.latestUpdates: HomeCardSize.large,
            },
          );

      final reset = customized.resetSection(HomeSectionId.updatedNovels);

      expect(reset.sectionOrder, customized.sectionOrder);
      expect(reset.hiddenSections, customized.hiddenSections);
      expect(reset.cardSurface, HomeCardSurface.elevated);
      expect(
        reset.cardSizeFor(HomeSectionId.updatedNovels),
        HomeCardSize.medium,
      );
      expect(reset.updatedNovelsTemplate, UpdatedNovelCardTemplate.poster);
      expect(
        reset.coverPresentationFor(HomeSectionId.updatedNovels),
        HomeCoverPresentation.fill,
      );
    },
  );

  test('repository loads valid JSON and persists updates', () async {
    final stored = HomeCustomization.forPreset(HomeCustomizationPreset.quick);
    final store = _MemoryHomeCustomizationStore(jsonEncode(stored.toJson()));
    final repository = StoredHomeCustomizationRepository(store: store);

    await repository.load();
    expect(repository.value, stored);

    final updated = HomeCustomization.forPreset(HomeCustomizationPreset.visual);
    await repository.update(updated);

    expect(jsonDecode(store.encoded!)['density'], 'comfortable');
    repository.dispose();
  });

  test('repository keeps defaults when stored JSON is invalid', () async {
    final repository = StoredHomeCustomizationRepository(
      store: _MemoryHomeCustomizationStore('{invalid'),
    );

    await repository.load();

    expect(repository.value, HomeCustomization.defaults);
    repository.dispose();
  });

  test('shared preferences store persists the encoded customization', () async {
    final store = SharedPreferencesHomeCustomizationStore();
    final encoded = jsonEncode(HomeCustomization.defaults.toJson());

    await store.write(encoded);

    expect(await store.read(), encoded);
  });

  test('shared preferences store reads the legacy v1 key', () async {
    const legacy = '{"version":1,"density":"compact"}';
    SharedPreferences.setMockInitialValues({
      SharedPreferencesHomeCustomizationStore.legacyKey: legacy,
    });
    final store = SharedPreferencesHomeCustomizationStore();

    expect(await store.read(), legacy);
  });

  test('shared preferences store reads the legacy v2 key', () async {
    const legacy = '{"version":2,"density":"comfortable"}';
    SharedPreferences.setMockInitialValues({
      SharedPreferencesHomeCustomizationStore.v2Key: legacy,
    });
    final store = SharedPreferencesHomeCustomizationStore();

    expect(await store.read(), legacy);
  });

  test('shared preferences store reads the legacy v3 key', () async {
    const legacy = '{"version":3,"density":"balanced"}';
    SharedPreferences.setMockInitialValues({
      SharedPreferencesHomeCustomizationStore.v3Key: legacy,
    });
    final store = SharedPreferencesHomeCustomizationStore();

    expect(await store.read(), legacy);
  });
}

class _MemoryHomeCustomizationStore implements HomeCustomizationStore {
  _MemoryHomeCustomizationStore(this.encoded);

  String? encoded;

  @override
  Future<String?> read() async => encoded;

  @override
  Future<void> write(String encodedCustomization) async {
    encoded = encodedCustomization;
  }
}
