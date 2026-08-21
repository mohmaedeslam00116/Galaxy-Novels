import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../application/library_customization_repository.dart';
import '../domain/library_customization.dart';

abstract class LibraryCustomizationStore {
  Future<String?> read();

  Future<void> write(String encodedCustomization);
}

class StoredLibraryCustomizationRepository extends ChangeNotifier
    implements LibraryCustomizationRepository {
  StoredLibraryCustomizationRepository({
    required LibraryCustomizationStore store,
  }) : _store = store;

  final LibraryCustomizationStore _store;

  LibraryCustomization _value = LibraryCustomization.defaults;
  Future<void>? _loadOperation;
  Future<void> _pendingWrite = Future.value();
  bool _didLoad = false;
  int _revision = 0;

  @override
  LibraryCustomization get value => _value;

  @override
  Future<void> load() {
    if (_didLoad) return Future.value();
    return _loadOperation ??= _loadFromStore();
  }

  @override
  Future<void> update(LibraryCustomization customization) {
    if (_value != customization) {
      _value = customization;
      _revision++;
      notifyListeners();
    }
    final encoded = jsonEncode(customization.toJson());
    _pendingWrite = _pendingWrite.then((_) => _store.write(encoded));
    return _pendingWrite;
  }

  Future<void> _loadFromStore() async {
    final revisionBeforeLoad = _revision;
    try {
      final encoded = await _store.read();
      if (encoded == null ||
          encoded.isEmpty ||
          revisionBeforeLoad != _revision) {
        return;
      }
      final decoded = jsonDecode(encoded);
      if (decoded is! Map) return;
      final customization = LibraryCustomization.fromJson(
        decoded.map((key, value) => MapEntry(key.toString(), value)),
      );
      if (_value != customization) {
        _value = customization;
        notifyListeners();
      }
    } on FormatException {
      return;
    } finally {
      _didLoad = true;
    }
  }
}
