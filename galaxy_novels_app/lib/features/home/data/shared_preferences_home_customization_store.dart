import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'stored_home_customization_repository.dart';

class SharedPreferencesHomeCustomizationStore
    implements HomeCustomizationStore {
  SharedPreferencesHomeCustomizationStore({SharedPreferencesAsync? preferences})
    : _preferences = preferences;

  static const key = 'home_customization.v4';
  static const v3Key = 'home_customization.v3';
  static const v2Key = 'home_customization.v2';
  static const legacyKey = 'home_customization.v1';

  SharedPreferencesAsync? _preferences;
  String? _fallbackValue;

  @override
  Future<String?> read() async {
    final preferences = _safePreferences();
    if (preferences == null) {
      return await _readLegacyValue() ?? _fallbackValue;
    }
    try {
      return await preferences.getString(key) ??
          await preferences.getString(v3Key) ??
          await preferences.getString(v2Key) ??
          await preferences.getString(legacyKey) ??
          await _readLegacyValue() ??
          _fallbackValue;
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
    if (preferences == null) {
      return;
    }
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

  Future<String?> _readLegacyValue() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      return preferences.getString(v3Key) ??
          preferences.getString(v2Key) ??
          preferences.getString(legacyKey);
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }
}
