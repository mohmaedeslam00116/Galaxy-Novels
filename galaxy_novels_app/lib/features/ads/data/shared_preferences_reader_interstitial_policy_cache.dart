import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'stored_reader_interstitial_policy_repository.dart';

class SharedPreferencesReaderInterstitialPolicyCache
    implements ReaderInterstitialPolicyCache {
  SharedPreferencesReaderInterstitialPolicyCache({
    SharedPreferencesAsync? preferences,
  }) : _preferences = preferences;

  static const key = 'reader_interstitial_policy.v1';

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
  Future<void> write(String encodedPolicy) async {
    _fallbackValue = encodedPolicy;
    final preferences = _safePreferences();
    if (preferences == null) return;
    try {
      await preferences.setString(key, encodedPolicy);
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
