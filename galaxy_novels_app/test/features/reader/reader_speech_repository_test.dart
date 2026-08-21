import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/features/reader/data/stored_reader_speech_repository.dart';
import 'package:galaxy_novels_app/features/reader/domain/reader_speech_models.dart';

void main() {
  test(
    'stored speech repository restores preferences and checkpoint',
    () async {
      final store = _MemoryReaderSpeechStore();
      final repository = StoredReaderSpeechRepository(store: store);
      final preferences = ReaderSpeechPreferences.defaults.copyWith(
        engineId: 'engine',
        voiceName: 'arabic',
        voiceLocale: 'ar-EG',
        rate: 1.4,
        autoNextChapter: false,
      );
      const checkpoint = ReaderSpeechCheckpoint(
        novelId: 9,
        chapterId: 33,
        contentApi: '/chapter/33',
        blockIndex: 5,
        characterOffset: 11,
        contentFingerprint: 'fingerprint',
      );

      await repository.updatePreferences(preferences);
      await repository.saveCheckpoint(checkpoint);

      final restored = StoredReaderSpeechRepository(store: store);
      await restored.load();

      expect(restored.value, preferences);
      expect(restored.checkpoint, checkpoint);
    },
  );

  test(
    'malformed speech storage falls back without losing availability',
    () async {
      final repository = StoredReaderSpeechRepository(
        store: _MemoryReaderSpeechStore(raw: '{broken'),
      );

      await repository.load();

      expect(repository.value, ReaderSpeechPreferences.defaults);
      expect(repository.checkpoint, isNull);
    },
  );

  test('new speech preference wins over an older pending load', () async {
    final store = _DelayedReaderSpeechStore();
    final repository = StoredReaderSpeechRepository(store: store);
    final load = repository.load();
    final updated = ReaderSpeechPreferences.defaults.copyWith(rate: 1.7);

    await repository.updatePreferences(updated);
    store.completeRead();
    await load;

    expect(repository.value, updated);
  });
}

class _MemoryReaderSpeechStore implements ReaderSpeechStore {
  _MemoryReaderSpeechStore({this.raw});

  String? raw;

  @override
  Future<String?> read() async => raw;

  @override
  Future<void> write(String encodedState) async {
    raw = encodedState;
  }
}

class _DelayedReaderSpeechStore implements ReaderSpeechStore {
  final _readCompleter = Completer<String?>();

  void completeRead() {
    _readCompleter.complete('{"preferences":{"rate":0.8},"checkpoint":null}');
  }

  @override
  Future<String?> read() => _readCompleter.future;

  @override
  Future<void> write(String encodedState) async {}
}
