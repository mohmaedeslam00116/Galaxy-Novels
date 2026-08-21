import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/core/config/app_config.dart';
import 'package:galaxy_novels_app/core/network/public_cache_client.dart';
import 'package:galaxy_novels_app/data/repositories/public_reader_repository.dart';

void main() {
  test('loads chapter content through content api', () async {
    final client = PublicCacheClient(
      config: const AppConfig(siteBaseUrl: 'https://example.com/'),
      jsonGet: (uri, headers) async {
        expect(headers['User-Agent'], 'WorReaderApp/1.0');
        expect(
          uri.toString(),
          'https://example.com/wp-json/wor-reader-app/v1/chapters/10',
        );
        return {
          'schema': 1,
          'generated': 123,
          'data': {
            'id': 10,
            'novel_id': 1,
            'display_title': 'الفصل 10',
            'content_html': '<p>نص الفصل</p>',
            'navigation': {
              'next_api': '/wp-json/wor-reader-app/v1/chapters/11',
            },
          },
        };
      },
    );

    final repository = PublicReaderRepository(cacheClient: client);
    final content = await repository.loadChapter(
      '/wp-json/wor-reader-app/v1/chapters/10',
    );

    expect(content.id, 10);
    expect(content.contentHtml, '<p>نص الفصل</p>');
    expect(
      content.navigation.nextApi,
      '/wp-json/wor-reader-app/v1/chapters/11',
    );
  });
}
