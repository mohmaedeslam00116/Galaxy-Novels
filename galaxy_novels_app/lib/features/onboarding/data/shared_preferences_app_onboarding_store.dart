import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../application/app_onboarding_store.dart';
import '../domain/app_onboarding_state.dart';

class SharedPreferencesAppOnboardingStore implements AppOnboardingStore {
  SharedPreferencesAppOnboardingStore({SharedPreferencesAsync? preferences})
    : _preferences = preferences;

  static const key = 'app_onboarding.v1';

  SharedPreferencesAsync? _preferences;

  @override
  Future<AppOnboardingState?> read() async {
    final raw = await _safePreferences().getString(key);
    if (raw == null || raw.isEmpty) return null;

    Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return null;
    }
    if (decoded is! Map) return null;
    return AppOnboardingState.tryFromMap(
      decoded.map(
        (persistedKey, persistedValue) =>
            MapEntry(persistedKey.toString(), persistedValue),
      ),
    );
  }

  @override
  Future<void> write(AppOnboardingState state) =>
      _safePreferences().setString(key, jsonEncode(state.toJson()));

  SharedPreferencesAsync _safePreferences() =>
      _preferences ??= SharedPreferencesAsync();
}
