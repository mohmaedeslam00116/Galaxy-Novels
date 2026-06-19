import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/core/config/app_config.dart';
import 'package:galaxy_novels_app/core/network/public_cache_client.dart';
import 'package:galaxy_novels_app/data/repositories/public_novel_repository.dart';

void main() {
  test('loads novel details then chapter pack', () async {
    final client = PublicCacheClient(
      config: const AppConfig(siteBaseUrl: 'https://example.com/'),
      jsonGet: (uri, headers) async {
        if (uri.path.endsWith('/novel-1.json')) {
          return {'pack': '/packs/novel-1-pack.json', 'novel_id': 1};
        }
        if (uri.path.endsWith('/packs/novel-1-pack.json')) {
          return {
            'data': {
              'id': 1,
              'title': 'رواية كاملة',
              'summary': 'ملخص',
              'first_chapter_url': '/chapter-1/',
              'links': {'chapters_manifest': '/chapters/manifest-1.json'},
            },
          };
        }
        if (uri.path.endsWith('/chapters/manifest-1.json')) {
          return {
            'total': 1,
            'pack_url': 'https://example.com/chapters/pack-1.json',
          };
        }
        if (uri.path.endsWith('/chapters/pack-1.json')) {
          return {
            'total': 1,
            'chapters': [
              {
                'id': 10,
                'position': 1,
                'label': 'الفصل 1',
                'url': '/chapter-1/',
              },
            ],
          };
        }
        throw PublicCacheException('Unexpected $uri');
      },
    );

    final repository = PublicNovelRepository(cacheClient: client);
    final result = await repository.loadNovel('/novel-1.json');

    expect(result.details.title, 'رواية كاملة');
    expect(result.chapters, hasLength(1));
    expect(result.chaptersError, isNull);
  });

  test('keeps details visible when chapter loading fails', () async {
    final client = PublicCacheClient(
      config: const AppConfig(siteBaseUrl: 'https://example.com/'),
      jsonGet: (uri, headers) async {
        if (uri.path.endsWith('/novel-1.json')) {
          return {'pack': '/novel-pack.json'};
        }
        if (uri.path.endsWith('/novel-pack.json')) {
          return {
            'data': {
              'id': 1,
              'title': 'رواية بدون فصول',
              'links': {'chapters_manifest': '/chapters.json'},
            },
          };
        }
        throw const PublicCacheException('chapters failed');
      },
    );

    final repository = PublicNovelRepository(cacheClient: client);
    final result = await repository.loadNovel('/novel-1.json');

    expect(result.details.title, 'رواية بدون فصول');
    expect(result.chapters, isEmpty);
    expect(result.chaptersError, contains('chapters failed'));
  });

  test('returns empty chapters when no chapters manifest exists', () async {
    final client = PublicCacheClient(
      config: const AppConfig(siteBaseUrl: 'https://example.com/'),
      jsonGet: (uri, headers) async {
        if (uri.path.endsWith('/novel-1.json')) {
          return {'pack': '/novel-pack.json'};
        }
        return {
          'data': {'id': 1, 'title': 'رواية جديدة'},
        };
      },
    );

    final repository = PublicNovelRepository(cacheClient: client);
    final result = await repository.loadNovel('/novel-1.json');

    expect(result.details.title, 'رواية جديدة');
    expect(result.chapters, isEmpty);
    expect(result.chaptersError, isNull);
  });
}
