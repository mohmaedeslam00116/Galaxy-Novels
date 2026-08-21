import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'stored_library_customization_repository.dart';

class SharedPreferencesLibraryCustomizationStore
    implements LibraryCustomizationStore {
  SharedPreferencesLibraryCustomizationStore({
    SharedPreferencesAsync? preferences,
  }) : _preferences = preferences;

  static const key = 'library_customization.v1';

  SharedPreferencesAsync? _preferences;
  String? _fallbackValue;

  @override
  Future<String?> read() async {
    final preferences = _safePreferences();
    if (preferences == null) return _fallbackValue;
    try {
      return await preferences.getString(key) ?? _fallbackValue;
    } on MissingPluginException {
      return _fallbackValue;
    } on PlatformException {
      return _fallbackValue;
    }
  }

  @override
  Future<void> write(String encodedCustomization) async {
    _fallbackValue = encodedCustomization;
    final preferences = _safePreferences();
    if (preferences == null) return;
    try {
      await preferences.setString(key, encodedCustomization);
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
