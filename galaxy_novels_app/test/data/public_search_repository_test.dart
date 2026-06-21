import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/core/config/app_config.dart';
import 'package:galaxy_novels_app/core/network/public_cache_client.dart';
import 'package:galaxy_novels_app/data/repositories/bootstrap_repository.dart';
import 'package:galaxy_novels_app/data/repositories/public_search_repository.dart';

void main() {
  test('loads search index from the manifest provided by bootstrap', () async {
    final requests = <Uri>[];
    final cacheClient = PublicCacheClient(
      config: const AppConfig(siteBaseUrl: 'https://example.com/'),
      jsonGet: (uri, headers) async {
        requests.add(uri);

        switch (uri.path) {
          case BootstrapRepository.bootstrapManifestPath:
            return {'pack': '/packs/bootstrap.json'};
          case '/packs/bootstrap.json':
            return {
              'data': {
                'site': {'name': 'Galaxy'},
                'api': {},
                'public': {'search_manifest': '/search/manifest.json'},
                'features': {},
              },
            };
          case '/search/manifest.json':
            return {
              'version': 'search-v1',
              'count': 1,
              'index': '/search/novels-v1.json',
            };
          case '/search/novels-v1.json':
            return {
              'v': 1,
              'items': [
                {'id': 1, 't': 'بحث الاختبار', 's': 'بحث الاختبار'},
              ],
            };
        }

        fail('Unexpected request: $uri');
      },
    );

    final repository = PublicSearchRepository(
      bootstrapRepository: BootstrapRepository(cacheClient),
      cacheClient: cacheClient,
    );

    final index = await repository.loadSearchIndex();

    expect(index.search('بحث').single.title, 'بحث الاختبار');
    expect(requests.map((request) => request.path), [
      BootstrapRepository.bootstrapManifestPath,
      '/packs/bootstrap.json',
      '/search/manifest.json',
      '/search/novels-v1.json',
    ]);
  });
}
