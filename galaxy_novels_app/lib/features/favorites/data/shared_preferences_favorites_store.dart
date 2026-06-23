import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/favorite_item.dart';
import 'favorites_local_store.dart';

class SharedPreferencesFavoritesStore implements FavoritesLocalStore {
  SharedPreferencesFavoritesStore({SharedPreferencesAsync? preferences})
    : _preferences = preferences;

  static const _keyPrefix = 'favorites.v1.user.';

  SharedPreferencesAsync? _preferences;
  final Map<int, String> _fallbackValues = {};

  @override
  Future<FavoriteLocalSnapshot> read(int userId) async {
    final encoded = await _readEncoded(userId);
    if (encoded == null || encoded.isEmpty) {
      return FavoriteLocalSnapshot();
    }

    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! Map) {
        throw const FormatException('Invalid favorites snapshot.');
      }
      final json = _asMap(decoded);
      if (json['version'] != 1) {
        throw const FormatException('Unsupported favorites snapshot.');
      }
      return FavoriteLocalSnapshot(
        items: _asList(json['items'])
            .map((item) => FavoriteItem.fromJson(_asMap(item)))
            .where((item) => item.id > 0 && item.title.isNotEmpty)
            .toList(growable: false),
        pendingChanges: _asList(json['pending_changes'])
            .map((item) => FavoriteChange.fromJson(_asMap(item)))
            .where((change) => change.novelId > 0)
            .toList(growable: false),
      );
    } on FormatException {
      await _remove(userId);
      return FavoriteLocalSnapshot();
    }
  }

  @override
  Future<void> write(int userId, FavoriteLocalSnapshot snapshot) async {
    final encoded = jsonEncode({
      'version': 1,
      'items': snapshot.items.map((item) => item.toJson()).toList(),
      'pending_changes': snapshot.pendingChanges
          .map((change) => change.toJson())
          .toList(),
    });
    final preferences = _safePreferences();
    if (preferences == null) {
      _fallbackValues[userId] = encoded;
      return;
    }
    try {
      await preferences.setString(_keyFor(userId), encoded);
    } on PlatformException {
      throw const FavoritesStoreException();
    }
  }

  Future<String?> _readEncoded(int userId) async {
    final preferences = _safePreferences();
    if (preferences == null) {
      return _fallbackValues[userId];
    }
    try {
      return await preferences.getString(_keyFor(userId));
    } on PlatformException {
      throw const FavoritesStoreException();
    }
  }

  Future<void> _remove(int userId) async {
    final preferences = _safePreferences();
    if (preferences == null) {
      _fallbackValues.remove(userId);
      return;
    }
    try {
      await preferences.remove(_keyFor(userId));
    } on PlatformException {
      throw const FavoritesStoreException();
    }
  }

  SharedPreferencesAsync? _safePreferences() {
    try {
      return _preferences ??= SharedPreferencesAsync();
    } on StateError {
      return null;
    }
  }

  String _keyFor(int userId) => '$_keyPrefix$userId';
}

Map<String, dynamic> _asMap(Object? input) {
  if (input is Map<String, dynamic>) {
    return input;
  }
  if (input is Map) {
    return input.map((key, value) => MapEntry(key.toString(), value));
  }
  return const {};
}

List<Object?> _asList(Object? input) {
  return input is List ? input.cast<Object?>() : const [];
}
