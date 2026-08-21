import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../application/reader_advanced_terminology_repository.dart';

class SharedPreferencesReaderAdvancedTerminologyAccessStore
    implements ReaderAdvancedTerminologyAccessStore {
  SharedPreferencesReaderAdvancedTerminologyAccessStore({
    SharedPreferencesAsync? preferences,
  }) : _preferences = preferences;

  static const key = 'reader_advanced_terminology_access.v1';

  SharedPreferencesAsync? _preferences;
  bool _fallbackValue = false;

  @override
  Future<bool> read() async {
    final preferences = _safePreferences();
    if (preferences == null) return _fallbackValue;
    try {
      return await preferences.getBool(key) ?? _fallbackValue;
    } on MissingPluginException {
      return _fallbackValue;
    } on PlatformException {
      return _fallbackValue;
    }
  }

  @override
  Future<void> write(bool value) async {
    _fallbackValue = value;
    final preferences = _safePreferences();
    if (preferences == null) return;
    try {
      await preferences.setBool(key, value);
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
