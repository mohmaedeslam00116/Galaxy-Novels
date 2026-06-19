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
    expect(requests.first.headers['User-Agent'], 'WorReaderApp/1.0 Android');
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
}

class _Request {
  const _Request(this.uri, this.headers);

  final Uri uri;
  final Map<String, String> headers;
}
