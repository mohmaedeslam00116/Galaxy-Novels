import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/core/config/app_config.dart';
import 'package:galaxy_novels_app/core/network/public_cache_client.dart';
import 'package:galaxy_novels_app/data/repositories/bootstrap_repository.dart';
import 'package:galaxy_novels_app/data/repositories/public_rankings_repository.dart';

void main() {
  test('loads rankings from the manifest provided by bootstrap', () async {
    final requests = <Uri>[];
    final cacheClient = PublicCacheClient(
      config: const AppConfig(siteBaseUrl: 'https://example.com/'),
      jsonGet: (uri, headers) async {
        requests.add(uri);

        switch (uri.path) {
          case BootstrapRepository.bootstrapManifestPath:
            return {
              'pack':
                  '/wp-content/uploads/wor-reader-cache/app/packs/bootstrap-hash.json',
            };
          case '/wp-content/uploads/wor-reader-cache/app/packs/bootstrap-hash.json':
            return {
              'data': {
                'site': {'name': 'Galaxy'},
                'api': {},
                'public': {
                  'rankings_manifest':
                      '/wp-content/uploads/wor-reader-cache/app/manifest/rankings.json',
                },
                'features': {},
              },
            };
          case '/wp-content/uploads/wor-reader-cache/app/manifest/rankings.json':
            return {
              'pack':
                  '/wp-content/uploads/wor-reader-cache/app/packs/rankings-hash.json',
            };
          case '/wp-content/uploads/wor-reader-cache/app/packs/rankings-hash.json':
            return {
              'period': 'month',
              'items': [
                {
                  'id': 7,
                  'title': 'ترتيب الاختبار',
                  'chapters_count': 90,
                  'stats': {'views': 5000},
                },
              ],
            };
        }

        fail('Unexpected request: $uri');
      },
    );

    final repository = PublicRankingsRepository(
      bootstrapRepository: BootstrapRepository(cacheClient),
      cacheClient: cacheClient,
    );

    final rankings = await repository.loadRankings();

    expect(rankings.items.single.title, 'ترتيب الاختبار');
    expect(rankings.items.single.views, 5000);
    expect(requests.map((request) => request.path), [
      BootstrapRepository.bootstrapManifestPath,
      '/wp-content/uploads/wor-reader-cache/app/packs/bootstrap-hash.json',
      '/wp-content/uploads/wor-reader-cache/app/manifest/rankings.json',
      '/wp-content/uploads/wor-reader-cache/app/packs/rankings-hash.json',
    ]);
  });
}
