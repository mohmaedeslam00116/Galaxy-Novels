import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/core/config/app_config.dart';
import 'package:galaxy_novels_app/core/network/public_cache_client.dart';
import 'package:galaxy_novels_app/data/repositories/bootstrap_repository.dart';
import 'package:galaxy_novels_app/data/repositories/public_home_repository.dart';

void main() {
  test('loads home data from the manifest provided by bootstrap', () async {
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
                'site': {'name': 'مجرة الروايات'},
                'api': {
                  'base': 'https://example.com/wp-json/wor-reader-app/v1',
                },
                'public': {
                  'home_manifest':
                      '/wp-content/uploads/wor-reader-cache/app/manifest/home.json',
                },
                'features': {},
              },
            };
          case '/wp-content/uploads/wor-reader-cache/app/manifest/home.json':
            return {
              'pack':
                  '/wp-content/uploads/wor-reader-cache/app/packs/home-hash.json',
            };
          case '/wp-content/uploads/wor-reader-cache/app/packs/home-hash.json':
            return {
              'data': {
                'continue_reading': {
                  'novel_title': 'ظلال المجرة',
                  'chapter_label': 'الفصل 24',
                  'progress': 68,
                },
                'latest_chapters': [
                  {
                    'id': 82,
                    'novel_id': 10,
                    'novel_title': 'حارس النجوم',
                    'label': 'الفصل 82',
                    'date': 'منذ 12 دقيقة',
                    'url': '/chapter-82/',
                  },
                ],
                'recent_novels': [
                  {
                    'id': 123,
                    'title': 'بوابة الشمال',
                    'genres': [
                      {'name': 'خيال'},
                      {'name': 'أكشن'},
                    ],
                    'chapters_count': 126,
                  },
                ],
              },
            };
        }

        fail('Unexpected request: $uri');
      },
    );

    final repository = PublicHomeRepository(
      bootstrapRepository: BootstrapRepository(cacheClient),
      cacheClient: cacheClient,
    );

    final home = await repository.loadHome();

    expect(home.continueReading?.novelTitle, 'ظلال المجرة');
    expect(home.latestChapters.single.novelTitle, 'حارس النجوم');
    expect(home.recentNovels.single.title, 'بوابة الشمال');
    expect(requests.map((request) => request.path), [
      BootstrapRepository.bootstrapManifestPath,
      '/wp-content/uploads/wor-reader-cache/app/packs/bootstrap-hash.json',
      '/wp-content/uploads/wor-reader-cache/app/manifest/home.json',
      '/wp-content/uploads/wor-reader-cache/app/packs/home-hash.json',
    ]);
  });
}
