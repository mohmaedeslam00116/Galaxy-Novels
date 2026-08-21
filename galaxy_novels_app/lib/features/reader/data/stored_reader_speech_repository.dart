import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../application/reader_speech_repository.dart';
import '../domain/reader_speech_models.dart';

abstract interface class ReaderSpeechStore {
  Future<String?> read();

  Future<void> write(String encodedState);
}

class StoredReaderSpeechRepository extends ChangeNotifier
    implements ReaderSpeechRepository {
  StoredReaderSpeechRepository({required ReaderSpeechStore store})
    : _store = store;

  final ReaderSpeechStore _store;

  ReaderSpeechPreferences _preferences = ReaderSpeechPreferences.defaults;
  ReaderSpeechCheckpoint? _checkpoint;
  Future<void>? _loadOperation;
  Future<void> _pendingWrite = Future.value();
  int _revision = 0;
  bool _didLoad = false;

  @override
  ReaderSpeechPreferences get value => _preferences;

  @override
  ReaderSpeechCheckpoint? get checkpoint => _checkpoint;

  @override
  Future<void> load() {
    if (_didLoad) return Future.value();
    return _loadOperation ??= _loadFromStore();
  }

  @override
  Future<void> updatePreferences(ReaderSpeechPreferences preferences) {
    if (_preferences != preferences) {
      _preferences = preferences;
      _revision += 1;
      notifyListeners();
    }
    return _enqueueWrite();
  }

  @override
  Future<void> saveCheckpoint(ReaderSpeechCheckpoint checkpoint) {
    if (_checkpoint != checkpoint) {
      _checkpoint = checkpoint;
      _revision += 1;
    }
    return _enqueueWrite();
  }

  @override
  Future<void> clearCheckpoint() {
    if (_checkpoint != null) {
      _checkpoint = null;
      _revision += 1;
    }
    return _enqueueWrite();
  }

  Future<void> _loadFromStore() async {
    final revisionBeforeLoad = _revision;
    try {
      final encodedState = await _store.read();
      if (encodedState == null || encodedState.isEmpty) return;
      final decoded = jsonDecode(encodedState);
      if (decoded is! Map || revisionBeforeLoad != _revision) return;
      _restoreState(decoded);
    } on FormatException {
      return;
    } finally {
      _didLoad = true;
    }
  }

  void _restoreState(Map<dynamic, dynamic> decoded) {
    final encodedPreferences = decoded['preferences'];
    if (encodedPreferences is Map) {
      _preferences = ReaderSpeechPreferences.fromJson(
        _stringKeyedMap(encodedPreferences),
      );
    }
    final encodedCheckpoint = decoded['checkpoint'];
    if (encodedCheckpoint is Map) {
      _checkpoint = ReaderSpeechCheckpoint.fromJson(
        _stringKeyedMap(encodedCheckpoint),
      );
    }
    notifyListeners();
  }

  Future<void> _enqueueWrite() {
    final previousWrite = _pendingWrite;
    final encodedState = jsonEncode({
      'preferences': _preferences.toJson(),
      'checkpoint': _checkpoint?.toJson(),
    });
    _pendingWrite = _writeAfter(previousWrite, encodedState);
    return _pendingWrite;
  }

  Future<void> _writeAfter(
    Future<void> previousWrite,
    String encodedState,
  ) async {
    try {
      await previousWrite;
    } on Exception {
      // A failed local write must not prevent a later preference from saving.
    }
    await _store.write(encodedState);
  }
}

Map<String, dynamic> _stringKeyedMap(Map<dynamic, dynamic> source) {
  return source.map((key, value) => MapEntry(key.toString(), value));
}
