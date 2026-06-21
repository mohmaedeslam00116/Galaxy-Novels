import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'stored_reader_preferences_repository.dart';

class SharedPreferencesReaderPreferencesStore
    implements ReaderPreferencesStore {
  SharedPreferencesReaderPreferencesStore({SharedPreferencesAsync? preferences})
    : _preferences = preferences;

  static const key = 'reader_preferences.v1';

  SharedPreferencesAsync? _preferences;
  String? _fallbackValue;

  @override
  Future<String?> read() async {
    final preferences = _safePreferences();
    if (preferences == null) {
      return _fallbackValue;
    }

    try {
      return await preferences.getString(key) ?? _fallbackValue;
    } on MissingPluginException {
      return _fallbackValue;
    } on PlatformException {
      return _fallbackValue;
    }
  }

  @override
  Future<void> write(String value) async {
    _fallbackValue = value;
    final preferences = _safePreferences();
    if (preferences == null) {
      return;
    }

    try {
      await preferences.setString(key, value);
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
