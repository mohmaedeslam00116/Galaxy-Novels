import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/features/home/application/home_customization_draft_controller.dart';
import 'package:galaxy_novels_app/features/home/application/home_customization_repository.dart';
import 'package:galaxy_novels_app/features/home/domain/home_customization.dart';

void main() {
  test('replace and undo keep one previous customization snapshot', () {
    final repository = _MemoryRepository();
    final controller = HomeCustomizationDraftController(repository: repository);

    controller.replaceDraft(
      controller.draft.copyWith(density: HomeDensity.compact),
    );
    controller.replaceDraft(
      controller.draft.copyWith(cardTint: HomeCardTint.strong),
    );

    expect(controller.isDirty, isTrue);
    expect(controller.canUndo, isTrue);
    controller.undo();
    expect(controller.draft.density, HomeDensity.compact);
    expect(controller.draft.cardTint, HomeCardTint.neutral);
    expect(controller.canUndo, isFalse);
  });

  test('preset is one undoable style change and preserves structure', () {
    final initial = HomeCustomization.defaults.copyWith(
      sectionOrder: const [
        HomeSectionId.latestUpdates,
        HomeSectionId.continueReading,
        HomeSectionId.updatedNovels,
      ],
      hiddenSections: const {HomeSectionId.updatedNovels},
    );
    final controller = HomeCustomizationDraftController(
      repository: _MemoryRepository(initial),
    );

    controller.applyPreset(HomeCustomizationPreset.visual);

    expect(controller.draft.sectionOrder, initial.sectionOrder);
    expect(controller.draft.hiddenSections, initial.hiddenSections);
    expect(controller.draft.cardSurface, HomeCardSurface.elevated);
    controller.undo();
    expect(controller.draft, initial);
  });

  test('reset section changes its style without changing global settings', () {
    final initial = HomeCustomization.forPreset(HomeCustomizationPreset.visual);
    final controller = HomeCustomizationDraftController(
      repository: _MemoryRepository(initial),
    );

    controller.resetSection(HomeSectionId.latestUpdates);

    expect(controller.draft.cardSurface, HomeCardSurface.elevated);
    expect(
      controller.draft.latestUpdatesTemplate,
      LatestUpdateCardTemplate.detailed,
    );
    expect(
      controller.draft.coverPresentationFor(HomeSectionId.latestUpdates),
      HomeCoverPresentation.fill,
    );
  });

  test(
    'successful apply publishes marked customization and clears draft',
    () async {
      final repository = _MemoryRepository();
      final controller = HomeCustomizationDraftController(
        repository: repository,
      );
      controller.replaceDraft(
        controller.draft.copyWith(density: HomeDensity.comfortable),
      );

      await controller.apply();

      expect(repository.updateCount, 1);
      expect(repository.value.density, HomeDensity.comfortable);
      expect(controller.applied, repository.value);
      expect(controller.isDirty, isFalse);
      expect(controller.canUndo, isFalse);
      expect(controller.isSaving, isFalse);
    },
  );

  test(
    'apply exposes saving state while repository write is pending',
    () async {
      final pending = Completer<void>();
      final repository = _MemoryRepository()..pendingWrite = pending;
      final controller = HomeCustomizationDraftController(
        repository: repository,
      );
      controller.replaceDraft(
        controller.draft.copyWith(density: HomeDensity.compact),
      );

      final operation = controller.apply();
      expect(controller.isSaving, isTrue);
      pending.complete();
      await operation;
      expect(controller.isSaving, isFalse);
    },
  );

  test('failed apply keeps the draft and clears saving state', () async {
    final repository = _MemoryRepository()..writeError = StateError('failed');
    final controller = HomeCustomizationDraftController(repository: repository);
    controller.replaceDraft(
      controller.draft.copyWith(density: HomeDensity.compact),
    );

    await expectLater(controller.apply(), throwsStateError);

    expect(controller.applied, HomeCustomization.defaults);
    expect(controller.draft.density, HomeDensity.compact);
    expect(controller.isDirty, isTrue);
    expect(controller.isSaving, isFalse);
  });

  test('discard restores applied customization and clears undo', () {
    final controller = HomeCustomizationDraftController(
      repository: _MemoryRepository(),
    );
    controller.replaceDraft(
      controller.draft.copyWith(density: HomeDensity.compact),
    );

    controller.discard();

    expect(controller.draft, controller.applied);
    expect(controller.isDirty, isFalse);
    expect(controller.canUndo, isFalse);
  });
}

class _MemoryRepository extends ChangeNotifier
    implements HomeCustomizationRepository {
  _MemoryRepository([HomeCustomization? initial])
    : _value = initial ?? HomeCustomization.defaults;

  HomeCustomization _value;
  int updateCount = 0;
  Completer<void>? pendingWrite;
  Object? writeError;

  @override
  HomeCustomization get value => _value;

  @override
  Future<void> load() async {}

  @override
  Future<void> update(HomeCustomization customization) async {
    updateCount++;
    if (writeError case final error?) {
      throw error;
    }
    await pendingWrite?.future;
    _value = customization;
    notifyListeners();
  }
}
