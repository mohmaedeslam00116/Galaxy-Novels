import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../application/app_update_snooze_store.dart';

abstract interface class AppUpdateSnoozePersistence {
  Future<String?> read();

  Future<void> write(String encodedSnooze);

  Future<void> clear();
}

class SharedPreferencesAppUpdateSnoozeStore implements AppUpdateSnoozeStore {
  SharedPreferencesAppUpdateSnoozeStore({
    AppUpdateSnoozePersistence? persistence,
  }) : _persistence = persistence ?? _SharedPreferencesSnoozePersistence();

  final AppUpdateSnoozePersistence _persistence;

  @override
  Future<AppUpdateSnooze?> read() async {
    final encoded = await _persistence.read();
    if (encoded == null || encoded.isEmpty) return null;
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! Map) return null;
      return AppUpdateSnooze.tryFromMap(
        decoded.map((key, value) => MapEntry(key.toString(), value)),
      );
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> write(AppUpdateSnooze snooze) {
    return _persistence.write(jsonEncode(snooze.toJson()));
  }

  @override
  Future<void> clear() => _persistence.clear();
}

class _SharedPreferencesSnoozePersistence
    implements AppUpdateSnoozePersistence {
  static const key = 'app_update_snooze.v1';

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
  Future<void> write(String encodedSnooze) async {
    _fallbackValue = encodedSnooze;
    final preferences = _safePreferences();
    if (preferences == null) return;
    try {
      await preferences.setString(key, encodedSnooze);
    } on MissingPluginException {
      return;
    } on PlatformException {
      return;
    }
  }

  @override
  Future<void> clear() async {
    _fallbackValue = null;
    final preferences = _safePreferences();
    if (preferences == null) return;
    try {
      await preferences.remove(key);
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
