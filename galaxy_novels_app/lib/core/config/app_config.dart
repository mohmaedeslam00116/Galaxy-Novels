class AppConfig {
  const AppConfig({
    this.siteBaseUrl = galaxyNovelsBaseUrl,
    this.userAgent = 'WorReaderApp/1.0 Android',
  });

  static const galaxyNovelsBaseUrl = 'https://galaxynovels.com/';

  final String? siteBaseUrl;
  final String userAgent;

  Uri resolve(String urlOrPath) {
    final uri = Uri.parse(urlOrPath);
    if (uri.hasScheme) {
      return uri;
    }

    final base = siteBaseUrl;
    if (base == null || base.isEmpty) {
      throw const AppConfigException(
        'Cannot resolve a relative URL without siteBaseUrl.',
      );
    }

    return Uri.parse(base).replace(path: '').resolveUri(uri);
  }
}

class AppConfigException implements Exception {
  const AppConfigException(this.message);

  final String message;

  @override
  String toString() => 'AppConfigException: $message';
}
