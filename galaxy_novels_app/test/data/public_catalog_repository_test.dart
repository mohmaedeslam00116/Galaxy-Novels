import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/core/config/app_config.dart';
import 'package:galaxy_novels_app/core/network/public_cache_client.dart';
import 'package:galaxy_novels_app/data/repositories/bootstrap_repository.dart';
import 'package:galaxy_novels_app/data/repositories/public_catalog_repository.dart';

void main() {
  test('emits after the first catalog pack then after remaining packs', () async {
    final requests = <Uri>[];
    final cacheClient = PublicCacheClient(
      config: const AppConfig(siteBaseUrl: 'https://example.com/'),
      jsonGet: (uri, headers) async {
        requests.add(uri);

        if (uri.path.endsWith('/manifest/bootstrap.json')) {
          return {
            'pack':
                '/wp-content/uploads/wor-reader-cache/app/packs/bootstrap.json',
          };
        }

        if (uri.path.endsWith('/packs/bootstrap.json')) {
          return {
            'data': {
              'site': {'name': 'Galaxy', 'url': 'https://example.com/'},
              'api': {},
              'public': {
                'catalog_manifest':
                    '/wp-content/uploads/wor-reader-cache/app/manifest/catalog.json',
              },
              'features': {},
            },
          };
        }

        if (uri.path.endsWith('/manifest/catalog.json')) {
          return {
            'version': 'catalog-v1',
            'count': 2,
            'part_size': 1,
            'packs': ['/packs/catalog-1.json', '/packs/catalog-2.json'],
          };
        }

        if (uri.path.endsWith('/packs/catalog-1.json')) {
          return {
            'part': 1,
            'total_parts': 2,
            'items': [
              {
                'id': 1,
                'title': 'الأولى',
                'updated_at': '2026-06-18T10:00:00Z',
              },
            ],
          };
        }

        return {
          'part': 2,
          'total_parts': 2,
          'items': [
            {'id': 2, 'title': 'الثانية', 'updated_at': '2026-06-19T10:00:00Z'},
          ],
        };
      },
    );

    final repository = PublicCatalogRepository(
      bootstrapRepository: BootstrapRepository(cacheClient),
      cacheClient: cacheClient,
    );

    final states = await repository.watchCatalog().toList();

    expect(states, hasLength(2));
    expect(states.first.items.map((novel) => novel.title), ['الأولى']);
    expect(states.first.isLoadingMore, isTrue);
    expect(states.last.items.map((novel) => novel.title), [
      'الأولى',
      'الثانية',
    ]);
    expect(states.last.isLoadingMore, isFalse);
    expect(states.last.loadedParts, 2);
    expect(states.last.totalParts, 2);
    expect(
      requests.any((uri) => uri.path.endsWith('/manifest/catalog.json')),
      isTrue,
    );
  });

  test('keeps loaded items when a later pack fails', () async {
    final cacheClient = PublicCacheClient(
      config: const AppConfig(siteBaseUrl: 'https://example.com/'),
      jsonGet: (uri, headers) async {
        if (uri.path.endsWith('/manifest/bootstrap.json')) {
          return {'pack': '/bootstrap.json'};
        }

        if (uri.path.endsWith('/bootstrap.json')) {
          return {
            'data': {
              'site': {},
              'api': {},
              'public': {'catalog_manifest': '/catalog.json'},
              'features': {},
            },
          };
        }

        if (uri.path.endsWith('/catalog.json')) {
          return {
            'packs': ['/catalog-1.json', '/catalog-2.json'],
          };
        }

        if (uri.path.endsWith('/catalog-1.json')) {
          return {
            'part': 1,
            'total_parts': 2,
            'items': [
              {'id': 1, 'title': 'المحفوظة'},
            ],
          };
        }

        throw const PublicCacheException('Second pack failed.');
      },
    );

    final repository = PublicCatalogRepository(
      bootstrapRepository: BootstrapRepository(cacheClient),
      cacheClient: cacheClient,
    );

    final states = await repository.watchCatalog().toList();

    expect(states, hasLength(2));
    expect(states.last.items.map((novel) => novel.title), ['المحفوظة']);
    expect(states.last.backgroundError, contains('Second pack failed'));
    expect(states.last.isLoadingMore, isFalse);
  });
}
