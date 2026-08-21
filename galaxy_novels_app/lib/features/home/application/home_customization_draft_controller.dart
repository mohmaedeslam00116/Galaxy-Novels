import 'package:flutter/foundation.dart';

import '../domain/home_customization.dart';
import 'home_customization_repository.dart';

class HomeCustomizationDraftController extends ChangeNotifier {
  HomeCustomizationDraftController({
    required HomeCustomizationRepository repository,
  }) : _repository = repository,
       _applied = repository.value,
       _draft = repository.value;

  final HomeCustomizationRepository _repository;

  HomeCustomization _applied;
  HomeCustomization _draft;
  HomeCustomization? _previous;
  bool _isSaving = false;

  HomeCustomization get applied => _applied;
  HomeCustomization get draft => _draft;
  bool get isDirty => _draft != _applied;
  bool get canUndo => _previous != null;
  bool get isSaving => _isSaving;

  void replaceDraft(HomeCustomization customization) {
    if (_isSaving || customization == _draft) {
      return;
    }
    _previous = _draft;
    _draft = customization;
    notifyListeners();
  }

  void applyPreset(HomeCustomizationPreset preset) {
    replaceDraft(_draft.applyPreset(preset));
  }

  void resetSection(HomeSectionId section) {
    replaceDraft(_draft.resetSection(section));
  }

  void undo() {
    final previous = _previous;
    if (_isSaving || previous == null) {
      return;
    }
    _draft = previous;
    _previous = null;
    notifyListeners();
  }

  void discard() {
    if (_isSaving) {
      return;
    }
    _draft = _applied;
    _previous = null;
    notifyListeners();
  }

  Future<void> apply() async {
    if (_isSaving || !isDirty) {
      return;
    }
    _isSaving = true;
    notifyListeners();
    final customization = _draft.markAllSectionsKnown();
    try {
      await _repository.update(customization);
      _applied = customization;
      _draft = customization;
      _previous = null;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
