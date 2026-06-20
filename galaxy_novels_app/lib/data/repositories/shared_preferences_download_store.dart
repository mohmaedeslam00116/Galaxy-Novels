import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/downloaded_chapter.dart';
import 'local_download_store.dart';

class SharedPreferencesDownloadStore implements LocalDownloadStore {
  SharedPreferencesDownloadStore({SharedPreferencesAsync? preferences})
    : _preferences = preferences;

  static const key = 'downloads.v1';

  SharedPreferencesAsync? _preferences;
  String? _fallbackValue;

  @override
  Future<List<DownloadedChapter>> readChapters() async {
    final raw = await _readRaw();
    if (raw == null || raw.isEmpty) {
      return const [];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const [];
      }

      return decoded
          .whereType<Map>()
          .map((item) => DownloadedChapter.fromJson(_asMap(item)))
          .where((chapter) => chapter.contentApi.isNotEmpty)
          .toList(growable: false);
    } on FormatException {
      return const [];
    } on TypeError {
      return const [];
    }
  }

  @override
  Future<void> writeChapters(List<DownloadedChapter> chapters) {
    final value = jsonEncode(
      chapters.map((chapter) => chapter.toJson()).toList(),
    );
    final preferences = _safePreferences();
    if (preferences == null) {
      _fallbackValue = value;
      return Future.value();
    }
    return preferences.setString(key, value);
  }

  Future<String?> _readRaw() {
    final preferences = _safePreferences();
    if (preferences == null) {
      return Future.value(_fallbackValue);
    }
    return preferences.getString(key);
  }

  SharedPreferencesAsync? _safePreferences() {
    try {
      return _preferences ??= SharedPreferencesAsync();
    } on StateError {
      return null;
    }
  }
}

Map<String, dynamic> _asMap(Map value) {
  return value.map((key, value) => MapEntry(key.toString(), value));
}
