import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../application/reader_preferences_repository.dart';
import '../domain/reader_preferences.dart';

abstract class ReaderPreferencesStore {
  Future<String?> read();

  Future<void> write(String value);
}

class StoredReaderPreferencesRepository extends ChangeNotifier
    implements ReaderPreferencesRepository {
  StoredReaderPreferencesRepository({required ReaderPreferencesStore store})
    : _store = store;

  final ReaderPreferencesStore _store;

  ReaderPreferences _value = ReaderPreferences.defaults;
  Future<void>? _loadOperation;
  Future<void> _pendingWrite = Future.value();
  bool _didLoad = false;
  int _revision = 0;

  @override
  ReaderPreferences get value => _value;

  @override
  Future<void> load() {
    if (_didLoad) {
      return Future.value();
    }
    return _loadOperation ??= _loadFromStore();
  }

  @override
  Future<void> update(ReaderPreferences preferences) {
    if (_value != preferences) {
      _value = preferences;
      _revision++;
      notifyListeners();
    }

    final encoded = jsonEncode(preferences.toJson());
    _pendingWrite = _pendingWrite
        .catchError((Object _) {})
        .then((_) => _store.write(encoded));
    return _pendingWrite;
  }

  Future<void> _loadFromStore() async {
    final revisionBeforeLoad = _revision;
    try {
      final raw = await _store.read();
      if (raw == null || raw.isEmpty || revisionBeforeLoad != _revision) {
        return;
      }

      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return;
      }

      final preferences = ReaderPreferences.fromJson(
        decoded.map((key, value) => MapEntry(key.toString(), value)),
      );
      if (_value != preferences) {
        _value = preferences;
        notifyListeners();
      }
    } catch (_) {
      // Local preference failures should never prevent the reader from opening.
    } finally {
      _didLoad = true;
    }
  }
}
