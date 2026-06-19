import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/core/config/app_config.dart';
import 'package:galaxy_novels_app/features/reader/data/reader_url_builder.dart';

void main() {
  const config = AppConfig(siteBaseUrl: 'https://galaxynovels.com/');

  test('resolves a relative chapter URL and enables app reader mode', () {
    final uri = buildPublicReaderUri(
      config: config,
      chapterUrl: '/novel/example/chapter-1/',
    );

    expect(
      uri.toString(),
      'https://galaxynovels.com/novel/example/chapter-1/?wr_app_reader=1',
    );
  });

  test('preserves existing query parameters', () {
    final uri = buildPublicReaderUri(
      config: config,
      chapterUrl: '/novel/example/chapter-1/?from=app',
    );

    expect(uri.queryParameters['from'], 'app');
    expect(uri.queryParameters['wr_app_reader'], '1');
  });

  test('normalizes an existing app reader query value', () {
    final uri = buildPublicReaderUri(
      config: config,
      chapterUrl:
          'https://galaxynovels.com/novel/example/chapter-1/?wr_app_reader=0',
    );

    expect(uri.queryParameters['wr_app_reader'], '1');
  });
}
