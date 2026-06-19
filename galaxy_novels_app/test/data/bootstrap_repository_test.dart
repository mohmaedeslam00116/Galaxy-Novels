import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/core/config/app_config.dart';
import 'package:galaxy_novels_app/core/network/public_cache_client.dart';
import 'package:galaxy_novels_app/data/repositories/bootstrap_repository.dart';

void main() {
  test('loads bootstrap pack and extracts public API configuration', () async {
    final requests = <Uri>[];
    final cacheClient = PublicCacheClient(
      config: const AppConfig(siteBaseUrl: 'https://example.com/'),
      jsonGet: (uri, headers) async {
        requests.add(uri);

        if (uri.path.endsWith('/manifest/bootstrap.json')) {
          return {
            'schema': 1,
            'version': 'bootstrap-hash',
            'pack':
                '/wp-content/uploads/wor-reader-cache/app/packs/bootstrap-hash.json',
          };
        }

        return {
          'schema': 1,
          'data': {
            'site': {
              'name': 'مجرة الروايات',
              'url': 'https://example.com/',
              'locale': 'ar',
              'rtl': true,
            },
            'api': {
              'base': 'https://example.com/wp-json/wor-reader-app/v1',
              'legacy_base': 'https://example.com/wp-json/wor-reader/v1',
            },
            'public': {
              'search_manifest': '/cache/search/manifest.json',
              'home_manifest': '/cache/app/manifest/home.json',
              'catalog_manifest': '/cache/app/manifest/catalog.json',
              'rankings_manifest': '/cache/app/manifest/rankings.json',
              'store_manifest': '/cache/app/manifest/store.json',
            },
            'features': {
              'vip': true,
              'comments': true,
              'ratings': true,
              'xp': true,
              'translator_awards': false,
              'html_app_reader': true,
            },
          },
        };
      },
    );

    final bootstrap = await BootstrapRepository(cacheClient).loadBootstrap();

    expect(requests.first.path, BootstrapRepository.bootstrapManifestPath);
    expect(bootstrap.siteName, 'مجرة الروايات');
    expect(bootstrap.siteUrl, Uri.parse('https://example.com/'));
    expect(
      bootstrap.apiBase,
      Uri.parse('https://example.com/wp-json/wor-reader-app/v1'),
    );
    expect(bootstrap.publicManifests.home, '/cache/app/manifest/home.json');
    expect(
      bootstrap.publicManifests.catalog,
      '/cache/app/manifest/catalog.json',
    );
    expect(bootstrap.publicManifests.search, '/cache/search/manifest.json');
    expect(
      bootstrap.publicManifests.rankings,
      '/cache/app/manifest/rankings.json',
    );
    expect(bootstrap.publicManifests.store, '/cache/app/manifest/store.json');
    expect(bootstrap.features.vip, isTrue);
    expect(bootstrap.features.comments, isTrue);
    expect(bootstrap.features.ratings, isTrue);
    expect(bootstrap.features.xp, isTrue);
    expect(bootstrap.features.translatorAwards, isFalse);
    expect(bootstrap.features.htmlAppReader, isTrue);
  });
}
