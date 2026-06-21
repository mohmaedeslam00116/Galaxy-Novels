import 'dart:convert';
import 'dart:io';

import '../config/app_config.dart';

typedef JsonGet =
    Future<Object?> Function(Uri uri, Map<String, String> headers);

abstract class PublicCacheStore {
  Future<String?> read(String key);

  Future<void> write(String key, String value);
}

class PublicCacheClient {
  PublicCacheClient({
    required this.config,
    JsonGet? jsonGet,
    PublicCacheStore? cacheStore,
  }) : _jsonGet = jsonGet ?? _defaultJsonGet,
       _cacheStore = cacheStore;

  final AppConfig config;
  final JsonGet _jsonGet;
  final PublicCacheStore? _cacheStore;

  Map<String, String> get publicJsonHeaders => {
    'Accept': 'application/json',
    'User-Agent': config.userAgent,
  };

  Future<Object?> loadJsonValue(String urlOrPath) async {
    final uri = config.resolve(urlOrPath);
    final cacheKey = uri.toString();
    try {
      final value = await _jsonGet(uri, publicJsonHeaders);
      await _writeCache(cacheKey, value);
      return value;
    } on Object {
      final cached = await _readCache(cacheKey);
      if (cached != null) {
        return cached;
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> loadJson(String urlOrPath) async {
    final value = await loadJsonValue(urlOrPath);
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }

    throw PublicCacheException(
      'GET ${config.resolve(urlOrPath)} did not return a JSON object.',
    );
  }

  Future<Map<String, dynamic>> loadPackFromManifest(String manifestPath) async {
    final manifest = await loadJson(manifestPath);
    final packPath = _readPackPath(manifest);
    return loadJson(packPath);
  }

  String _readPackPath(Map<String, dynamic> manifest) {
    final packPath = manifest['pack_url'] ?? manifest['pack'];
    if (packPath is String && packPath.isNotEmpty) {
      return packPath;
    }

    throw const PublicCacheException('Manifest does not contain a pack URL.');
  }

  static Future<Object?> _defaultJsonGet(
    Uri uri,
    Map<String, String> headers,
  ) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(uri);
      headers.forEach(request.headers.set);

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw PublicCacheException(
          'GET $uri failed with HTTP ${response.statusCode}.',
        );
      }

      return jsonDecode(body);
    } finally {
      client.close(force: true);
    }
  }

  Future<void> _writeCache(String key, Object? value) async {
    final store = _cacheStore;
    if (store == null) {
      return;
    }

    try {
      await store.write(key, jsonEncode(value));
    } on Object {
      // Cache writes must not break fresh network data.
    }
  }

  Future<Object?> _readCache(String key) async {
    final store = _cacheStore;
    if (store == null) {
      return null;
    }

    try {
      final raw = await store.read(key);
      if (raw == null || raw.isEmpty) {
        return null;
      }
      return jsonDecode(raw);
    } on Object {
      return null;
    }
  }
}

class PublicCacheException implements Exception {
  const PublicCacheException(this.message);

  final String message;

  @override
  String toString() => 'PublicCacheException: $message';
}
