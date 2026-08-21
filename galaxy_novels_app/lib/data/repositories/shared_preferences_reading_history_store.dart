import 'package:shared_preferences/shared_preferences.dart';

import 'reading_history_repository.dart';
import 'stored_reading_history_repository.dart';

class SharedPreferencesReadingHistoryStore implements ReadingHistoryStore {
  SharedPreferencesReadingHistoryStore({SharedPreferencesAsync? preferences})
    : _preferences = preferences;

  static const legacyKey = 'reading_history.v1';
  static const keyPrefix = 'reading_history.v2.';

  SharedPreferencesAsync? _preferences;
  final Map<String, String> _fallbackValues = {};
  Future<void>? _guestMigrationInFlight;

  @override
  Future<String?> read(ReadingHistoryScope scope) async {
    if (scope == ReadingHistoryScope.guest) {
      await _ensureGuestMigration();
    }
    return _readKey(_keyFor(scope));
  }

  @override
  Future<void> write(ReadingHistoryScope scope, String value) {
    return _writeKey(_keyFor(scope), value);
  }

  Future<void> _ensureGuestMigration() {
    final pendingMigration = _guestMigrationInFlight;
    if (pendingMigration != null) {
      return pendingMigration;
    }

    late final Future<void> migration;
    migration = _migrateGuestHistory().whenComplete(() {
      if (identical(_guestMigrationInFlight, migration)) {
        _guestMigrationInFlight = null;
      }
    });
    _guestMigrationInFlight = migration;
    return migration;
  }

  Future<void> _migrateGuestHistory() async {
    final guestKey = _keyFor(ReadingHistoryScope.guest);
    final currentGuestValue = await _readKey(guestKey);
    final legacyValue = await _readKey(legacyKey);
    if (currentGuestValue != null) {
      if (legacyValue != null) {
        await _removeKey(legacyKey);
      }
      return;
    }
    if (legacyValue == null) {
      return;
    }
    await _writeKey(guestKey, legacyValue);
    await _removeKey(legacyKey);
  }

  Future<String?> _readKey(String key) {
    final preferences = _safePreferences();
    if (preferences == null) {
      return Future.value(_fallbackValues[key]);
    }
    return preferences.getString(key);
  }

  Future<void> _writeKey(String key, String value) {
    final preferences = _safePreferences();
    if (preferences == null) {
      _fallbackValues[key] = value;
      return Future.value();
    }
    return preferences.setString(key, value);
  }

  Future<void> _removeKey(String key) {
    final preferences = _safePreferences();
    if (preferences == null) {
      _fallbackValues.remove(key);
      return Future.value();
    }
    return preferences.remove(key);
  }

  SharedPreferencesAsync? _safePreferences() {
    try {
      return _preferences ??= SharedPreferencesAsync();
    } on StateError {
      return null;
    }
  }

  String _keyFor(ReadingHistoryScope scope) {
    return '$keyPrefix${scope.storageSuffix}';
  }
}
