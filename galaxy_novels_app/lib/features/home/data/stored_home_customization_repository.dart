import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../application/home_customization_repository.dart';
import '../domain/home_customization.dart';

abstract class HomeCustomizationStore {
  Future<String?> read();

  Future<void> write(String encodedCustomization);
}

class StoredHomeCustomizationRepository extends ChangeNotifier
    implements HomeCustomizationRepository {
  StoredHomeCustomizationRepository({required HomeCustomizationStore store})
    : _store = store;

  final HomeCustomizationStore _store;

  HomeCustomization _value = HomeCustomization.defaults;
  Future<void>? _loadOperation;
  Future<void> _pendingWrite = Future.value();
  bool _didLoad = false;
  int _revision = 0;

  @override
  HomeCustomization get value => _value;

  @override
  Future<void> load() {
    if (_didLoad) {
      return Future.value();
    }
    return _loadOperation ??= _loadFromStore();
  }

  @override
  Future<void> update(HomeCustomization customization) {
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
      if (decoded is! Map) {
        return;
      }
      _publishLoaded(_stringKeyedMap(decoded));
    } on FormatException {
      return;
    } finally {
      _didLoad = true;
    }
  }

  void _publishLoaded(Map<String, dynamic> decoded) {
    final customization = HomeCustomization.fromJson(decoded);
    if (_value != customization) {
      _value = customization;
      notifyListeners();
    }
  }
}

Map<String, dynamic> _stringKeyedMap(Map<dynamic, dynamic> source) {
  return source.map((key, value) => MapEntry(key.toString(), value));
}
