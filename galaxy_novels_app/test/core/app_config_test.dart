import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/core/config/app_config.dart';

void main() {
  test('resolves relative public cache paths against the site base url', () {
    const config = AppConfig(siteBaseUrl: 'https://example.com/ar/');

    final resolved = config.resolve(
      '/wp-content/uploads/wor-reader-cache/app/manifest/bootstrap.json',
    );

    expect(
      resolved,
      Uri.parse(
        'https://example.com/wp-content/uploads/wor-reader-cache/app/manifest/bootstrap.json',
      ),
    );
  });

  test('keeps absolute urls unchanged', () {
    const config = AppConfig(siteBaseUrl: 'https://example.com/');

    final resolved = config.resolve(
      'https://cdn.example.com/cache/app/packs/bootstrap-hash.json',
    );

    expect(
      resolved,
      Uri.parse('https://cdn.example.com/cache/app/packs/bootstrap-hash.json'),
    );
  });

  test('uses a platform-neutral user agent by default', () {
    const config = AppConfig();

    expect(config.userAgent, 'WorReaderApp/1.0');
  });

  test('uses Galaxy Novels as the default site base url', () {
    const config = AppConfig();

    final resolved = config.resolve(
      '/wp-content/uploads/wor-reader-cache/app/manifest/bootstrap.json',
    );

    expect(
      resolved,
      Uri.parse(
        'https://galaxynovels.com/wp-content/uploads/wor-reader-cache/app/manifest/bootstrap.json',
      ),
    );
  });
}
