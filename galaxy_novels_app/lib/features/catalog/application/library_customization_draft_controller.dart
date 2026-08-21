import 'package:flutter/foundation.dart';

import '../domain/library_customization.dart';
import 'library_customization_repository.dart';

class LibraryCustomizationDraftController extends ChangeNotifier {
  LibraryCustomizationDraftController({
    required LibraryCustomizationRepository repository,
  }) : _repository = repository,
       _applied = repository.value,
       _draft = repository.value;

  final LibraryCustomizationRepository _repository;

  LibraryCustomization _applied;
  LibraryCustomization _draft;
  LibraryCustomization? _previous;
  bool _isSaving = false;

  LibraryCustomization get applied => _applied;
  LibraryCustomization get draft => _draft;
  bool get isDirty => _draft != _applied;
  bool get canUndo => _previous != null;
  bool get isSaving => _isSaving;

  void replaceDraft(LibraryCustomization customization) {
    if (_isSaving || customization == _draft) return;
    _previous = _draft;
    _draft = customization;
    notifyListeners();
  }

  void applyPreset(LibraryCustomizationPreset preset) {
    replaceDraft(_draft.applyPreset(preset));
  }

  void reset() => replaceDraft(LibraryCustomization.defaults);

  void undo() {
    final previous = _previous;
    if (_isSaving || previous == null) return;
    _draft = previous;
    _previous = null;
    notifyListeners();
  }

  void discard() {
    if (_isSaving) return;
    _draft = _applied;
    _previous = null;
    notifyListeners();
  }

  Future<void> apply() async {
    if (_isSaving || !isDirty) return;
    _isSaving = true;
    notifyListeners();
    try {
      await _repository.update(_draft);
      _applied = _draft;
      _previous = null;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
