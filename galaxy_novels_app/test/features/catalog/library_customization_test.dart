import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/features/catalog/application/library_customization_draft_controller.dart';
import 'package:galaxy_novels_app/features/catalog/application/library_customization_repository.dart';
import 'package:galaxy_novels_app/features/catalog/data/stored_library_customization_repository.dart';
import 'package:galaxy_novels_app/features/catalog/domain/catalog_query.dart';
import 'package:galaxy_novels_app/features/catalog/domain/library_customization.dart';

void main() {
  group('LibraryCustomization', () {
    test('round-trips every setting through JSON', () {
      final original = LibraryCustomization(
        layout: LibraryLayout.list,
        gridTemplate: LibraryGridTemplate.coverOnly,
        listTemplate: LibraryListTemplate.compact,
        cardSize: LibraryCardSize.large,
        density: LibraryDensity.comfortable,
        coverPresentation: LibraryCoverPresentation.tonalFrame,
        cardSurface: LibraryCardSurface.elevated,
        cardCorner: LibraryCardCorner.almostSquare,
        visibleFields: const {
          LibraryCardField.rating,
          LibraryCardField.firstGenre,
        },
        defaultSort: CatalogSort.rating,
        rememberViewAndSort: false,
        pinCompactSearch: false,
      );

      final restored = LibraryCustomization.fromJson(original.toJson());

      expect(restored, original);
      expect(restored.toJson()['version'], 1);
    });

    test('repairs unknown and malformed values to safe defaults', () {
      final restored = LibraryCustomization.fromJson({
        'layout': 'unknown',
        'grid_template': 14,
        'visible_fields': 'not-a-list',
        'default_sort': 'missing',
        'remember_view_and_sort': 'yes',
      });

      expect(restored, LibraryCustomization.defaults);
    });

    test('presets are complete and intentionally distinct', () {
      final balanced = LibraryCustomization.forPreset(
        LibraryCustomizationPreset.balanced,
      );
      final quick = LibraryCustomization.forPreset(
        LibraryCustomizationPreset.quick,
      );
      final visual = LibraryCustomization.forPreset(
        LibraryCustomizationPreset.visual,
      );

      expect(balanced.layout, LibraryLayout.grid);
      expect(quick.layout, LibraryLayout.list);
      expect(quick.listTemplate, LibraryListTemplate.compact);
      expect(visual.gridTemplate, LibraryGridTemplate.coverOnly);
      expect(visual.cardSize, LibraryCardSize.large);
    });
  });

  group('StoredLibraryCustomizationRepository', () {
    test('loads valid data and falls back after corrupt JSON', () async {
      final expected = LibraryCustomization.forPreset(
        LibraryCustomizationPreset.quick,
      );
      final repository = StoredLibraryCustomizationRepository(
        store: _MemoryStore(jsonEncode(expected.toJson())),
      );

      await repository.load();
      expect(repository.value, expected);

      final corruptRepository = StoredLibraryCustomizationRepository(
        store: _MemoryStore('{broken'),
      );
      await corruptRepository.load();
      expect(corruptRepository.value, LibraryCustomization.defaults);
    });

    test('publishes before persisting and serializes updates', () async {
      final store = _MemoryStore(null);
      final repository = StoredLibraryCustomizationRepository(store: store);
      final next = LibraryCustomization.forPreset(
        LibraryCustomizationPreset.visual,
      );
      var notifications = 0;
      repository.addListener(() => notifications += 1);

      await repository.update(next);

      expect(repository.value, next);
      expect(notifications, 1);
      expect(
        LibraryCustomization.fromJson(
          (jsonDecode(store.value!) as Map).map(
            (key, value) => MapEntry(key.toString(), value),
          ),
        ),
        next,
      );
    });
  });

  group('LibraryCustomizationDraftController', () {
    test('tracks one-step undo, apply, and discard', () async {
      final repository = _FakeRepository(LibraryCustomization.defaults);
      final controller = LibraryCustomizationDraftController(
        repository: repository,
      );
      final quick = LibraryCustomization.forPreset(
        LibraryCustomizationPreset.quick,
      );

      controller.replaceDraft(quick);
      expect(controller.isDirty, isTrue);
      expect(controller.canUndo, isTrue);

      controller.undo();
      expect(controller.draft, LibraryCustomization.defaults);
      expect(controller.canUndo, isFalse);

      controller.replaceDraft(quick);
      await controller.apply();
      expect(controller.isDirty, isFalse);
      expect(repository.value, quick);

      controller.replaceDraft(LibraryCustomization.defaults);
      controller.discard();
      expect(controller.draft, quick);
      expect(controller.isDirty, isFalse);
    });

    test('keeps the draft when persistence fails', () async {
      final repository = _FakeRepository(
        LibraryCustomization.defaults,
        failUpdates: true,
      );
      final controller = LibraryCustomizationDraftController(
        repository: repository,
      );
      final visual = LibraryCustomization.forPreset(
        LibraryCustomizationPreset.visual,
      );
      controller.replaceDraft(visual);

      await expectLater(controller.apply(), throwsStateError);

      expect(controller.draft, visual);
      expect(controller.isDirty, isTrue);
      expect(controller.isSaving, isFalse);
    });
  });
}

class _MemoryStore implements LibraryCustomizationStore {
  _MemoryStore(this.value);

  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String encodedCustomization) async {
    value = encodedCustomization;
  }
}

class _FakeRepository extends ChangeNotifier
    implements LibraryCustomizationRepository {
  _FakeRepository(this._value, {this.failUpdates = false});

  LibraryCustomization _value;
  final bool failUpdates;

  @override
  LibraryCustomization get value => _value;

  @override
  Future<void> load() async {}

  @override
  Future<void> update(LibraryCustomization customization) async {
    if (failUpdates) throw StateError('write failed');
    _value = customization;
    notifyListeners();
  }
}
