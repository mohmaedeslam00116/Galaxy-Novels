import 'package:flutter/foundation.dart';

import '../domain/reader_speech_models.dart';

abstract interface class ReaderSpeechRepository
    implements ValueListenable<ReaderSpeechPreferences> {
  ReaderSpeechCheckpoint? get checkpoint;

  Future<void> load();

  Future<void> updatePreferences(ReaderSpeechPreferences preferences);

  Future<void> saveCheckpoint(ReaderSpeechCheckpoint checkpoint);

  Future<void> clearCheckpoint();
}
