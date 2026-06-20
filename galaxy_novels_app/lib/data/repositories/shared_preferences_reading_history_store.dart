import 'package:shared_preferences/shared_preferences.dart';

import 'stored_reading_history_repository.dart';

class SharedPreferencesReadingHistoryStore implements ReadingHistoryStore {
  SharedPreferencesReadingHistoryStore({SharedPreferencesAsync? preferences})
    : _preferences = preferences;

  static const key = 'reading_history.v1';

  SharedPreferencesAsync? _preferences;
  String? _fallbackValue;

  @override
  Future<String?> read() {
    final preferences = _safePreferences();
    if (preferences == null) {
      return Future.value(_fallbackValue);
    }
    return preferences.getString(key);
  }

  @override
  Future<void> write(String value) {
    final preferences = _safePreferences();
    if (preferences == null) {
      _fallbackValue = value;
      return Future.value();
    }
    return preferences.setString(key, value);
  }

  SharedPreferencesAsync? _safePreferences() {
    try {
      return _preferences ??= SharedPreferencesAsync();
    } on StateError {
      return null;
    }
  }
}
