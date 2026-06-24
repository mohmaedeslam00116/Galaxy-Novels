import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/reading_activity_event.dart';
import 'reading_activity_store.dart';

class SharedPreferencesReadingActivityStore implements ReadingActivityStore {
  SharedPreferencesReadingActivityStore({SharedPreferencesAsync? preferences})
    : _preferences = preferences;

  static const _keyPrefix = 'reading_activity_queue.v1.';
  static const _maxEvents = 500;

  SharedPreferencesAsync? _preferences;
  final Map<int, String> _fallbackValues = {};

  @override
  Future<List<ReadingActivityEvent>> read(int userId) async {
    final encoded = await _readEncoded(userId);
    if (encoded == null || encoded.isEmpty) {
      return const [];
    }
    try {
      final decoded = jsonDecode(encoded);
      final json = _asMap(decoded);
      if (json['version'] != 1) {
        throw const FormatException('Unsupported activity queue.');
      }
      return _asList(json['events'])
          .map((entry) => ReadingActivityEvent.fromStorageJson(_asMap(entry)))
          .where((event) => event.ownerUserId == userId)
          .toList(growable: false);
    } on FormatException {
      await _remove(userId);
      return const [];
    }
  }

  @override
  Future<void> write(int userId, List<ReadingActivityEvent> events) async {
    final retained = events.length <= _maxEvents
        ? events
        : events.sublist(events.length - _maxEvents);
    final encoded = jsonEncode({
      'version': 1,
      'events': retained.map((event) => event.toStorageJson()).toList(),
    });
    final preferences = _safePreferences();
    if (preferences == null) {
      _fallbackValues[userId] = encoded;
      return;
    }
    try {
      await preferences.setString(_keyFor(userId), encoded);
    } on PlatformException {
      throw const ReadingActivityStoreException();
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
      throw const ReadingActivityStoreException();
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
      throw const ReadingActivityStoreException();
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
