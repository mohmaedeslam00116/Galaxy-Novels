import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/core/config/app_config.dart';
import 'package:galaxy_novels_app/core/network/public_cache_client.dart';

void main() {
  test('loads manifest then pack and sends public cache headers', () async {
    final requests = <_Request>[];
    final client = PublicCacheClient(
      config: const AppConfig(siteBaseUrl: 'https://example.com/'),
      jsonGet: (uri, headers) async {
        requests.add(_Request(uri, headers));

        if (uri.path.endsWith('/manifest/home.json')) {
          return {
            'schema': 1,
            'version': 'hash',
            'pack':
                '/wp-content/uploads/wor-reader-cache/app/packs/home-hash.json',
          };
        }

        return {
          'schema': 1,
          'data': {'latest_chapters': [], 'recent_novels': []},
        };
      },
    );

    final pack = await client.loadPackFromManifest(
      '/wp-content/uploads/wor-reader-cache/app/manifest/home.json',
    );

    expect(pack['schema'], 1);
    expect(pack['data'], isA<Map<String, dynamic>>());
    expect(requests, hasLength(2));
    expect(
      requests.first.uri,
      Uri.parse(
        'https://example.com/wp-content/uploads/wor-reader-cache/app/manifest/home.json',
      ),
    );
    expect(
      requests.last.uri,
      Uri.parse(
        'https://example.com/wp-content/uploads/wor-reader-cache/app/packs/home-hash.json',
      ),
    );
    expect(requests.first.headers['Accept'], 'application/json');
    expect(requests.first.headers['User-Agent'], 'WorReaderApp/1.0');
  });

  test('uses pack_url before pack when both are present', () async {
    final requests = <Uri>[];
    final client = PublicCacheClient(
      config: const AppConfig(siteBaseUrl: 'https://example.com/'),
      jsonGet: (uri, headers) async {
        requests.add(uri);
        if (requests.length == 1) {
          return {
            'pack': '/relative-pack.json',
            'pack_url': 'https://cdn.example.com/absolute-pack.json',
          };
        }
        return {'data': <String, dynamic>{}};
      },
    );

    await client.loadPackFromManifest('/manifest.json');

    expect(
      requests.last,
      Uri.parse('https://cdn.example.com/absolute-pack.json'),
    );
  });

  test('loadJsonValue supports top-level arrays', () async {
    final client = PublicCacheClient(
      config: const AppConfig(siteBaseUrl: 'https://example.com/'),
      jsonGet: (uri, headers) async {
        expect(uri.toString(), 'https://example.com/chapters.json');
        expect(headers['Accept'], 'application/json');
        return [
          {'id': 1, 'label': 'الفصل 1'},
        ];
      },
    );

    final value = await client.loadJsonValue('/chapters.json');

    expect(value, isA<List<Object?>>());
    expect((value as List).single, isA<Map<String, dynamic>>());
  });

  test('stores successful public JSON responses in the local cache', () async {
    final store = _FakePublicCacheStore();
    final client = PublicCacheClient(
      config: const AppConfig(siteBaseUrl: 'https://example.com/'),
      cacheStore: store,
      jsonGet: (uri, headers) async {
        return {
          'pack': '/wp-content/uploads/wor-reader-cache/app/packs/home.json',
        };
      },
    );

    await client.loadJson(
      '/wp-content/uploads/wor-reader-cache/app/manifest/home.json',
    );

    expect(
      store.values.keys,
      contains(
        'https://example.com/wp-content/uploads/wor-reader-cache/app/manifest/home.json',
      ),
    );
    expect(
      store.values.values.single,
      contains('/wp-content/uploads/wor-reader-cache/app/packs/home.json'),
    );
  });

  test(
    'falls back to cached public JSON when the network request fails',
    () async {
      final store = _FakePublicCacheStore();
      await store.write(
        'https://example.com/wp-content/uploads/wor-reader-cache/app/packs/home.json',
        '{"data":{"recent_novels":[{"title":"من الكاش"}]}}',
      );
      final client = PublicCacheClient(
        config: const AppConfig(siteBaseUrl: 'https://example.com/'),
        cacheStore: store,
        jsonGet: (uri, headers) async {
          throw const PublicCacheException('Network failed.');
        },
      );

      final json = await client.loadJson(
        '/wp-content/uploads/wor-reader-cache/app/packs/home.json',
      );

      expect(json['data'], isA<Map<String, dynamic>>());
      expect(
        ((json['data'] as Map<String, dynamic>)['recent_novels'] as List)
            .single,
        containsPair('title', 'من الكاش'),
      );
    },
  );

  test('times out an injected JSON getter and falls back to cache', () async {
    final store = _FakePublicCacheStore();
    final networkResponse = Completer<Object?>();
    await store.write(
      'https://example.com/slow.json',
      '{"data":{"source":"cache"}}',
    );
    final client = PublicCacheClient(
      config: const AppConfig(siteBaseUrl: 'https://example.com/'),
      cacheStore: store,
      requestTimeout: const Duration(milliseconds: 10),
      jsonGet: (uri, headers) => networkResponse.future,
    );

    final json = await client.loadJson('/slow.json');
    networkResponse.complete({
      'data': {'source': 'network'},
    });

    expect(json['data'], {'source': 'cache'});
  });
}

class _FakePublicCacheStore implements PublicCacheStore {
  final values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }
}

class _Request {
  const _Request(this.uri, this.headers);

  final Uri uri;
  final Map<String, String> headers;
}
