import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../application/app_review_prompt_store.dart';
import '../domain/app_review_prompt_state.dart';

class SharedPreferencesAppReviewPromptStore implements AppReviewPromptStore {
  SharedPreferencesAppReviewPromptStore({SharedPreferencesAsync? preferences})
    : _preferences = preferences;

  static const key = 'app_review_prompt.v1';

  SharedPreferencesAsync? _preferences;
  String? _fallbackValue;

  @override
  Future<AppReviewPromptState?> read() async {
    final encoded = await _readEncoded();
    if (encoded == null || encoded.isEmpty) return null;
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! Map) return null;
      return AppReviewPromptState.tryFromMap(
        decoded.map((key, value) => MapEntry(key.toString(), value)),
      );
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> write(AppReviewPromptState state) async {
    final encoded = jsonEncode(state.toJson());
    _fallbackValue = encoded;
    final preferences = _safePreferences();
    if (preferences == null) return;
    try {
      await preferences.setString(key, encoded);
    } on MissingPluginException {
      return;
    } on PlatformException {
      return;
    }
  }

  Future<String?> _readEncoded() async {
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

  SharedPreferencesAsync? _safePreferences() {
    try {
      return _preferences ??= SharedPreferencesAsync();
    } on StateError {
      return null;
    }
  }
}
