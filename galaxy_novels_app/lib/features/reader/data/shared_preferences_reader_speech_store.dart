import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'stored_reader_speech_repository.dart';

class SharedPreferencesReaderSpeechStore implements ReaderSpeechStore {
  SharedPreferencesReaderSpeechStore({SharedPreferencesAsync? preferences})
    : _preferences = preferences;

  static const key = 'reader_speech.v1';

  SharedPreferencesAsync? _preferences;
  String? _fallbackState;

  @override
  Future<String?> read() async {
    final preferences = _safePreferences();
    if (preferences == null) return _fallbackState;
    try {
      return await preferences.getString(key) ?? _fallbackState;
    } on MissingPluginException {
      return _fallbackState;
    } on PlatformException {
      return _fallbackState;
    }
  }

  @override
  Future<void> write(String encodedState) async {
    _fallbackState = encodedState;
    final preferences = _safePreferences();
    if (preferences == null) return;
    try {
      await preferences.setString(key, encodedState);
    } on MissingPluginException {
      return;
    } on PlatformException {
      return;
    }
  }

  SharedPreferencesAsync? _safePreferences() {
    try {
      return _preferences ??= SharedPreferencesAsync();
    } on StateError {
      return null;
    }
  }
}
