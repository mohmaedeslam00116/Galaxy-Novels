import '../../core/network/public_cache_client.dart';

class BootstrapRepository {
  const BootstrapRepository(this._cacheClient);

  static const bootstrapManifestPath =
      '/wp-content/uploads/wor-reader-cache/app/manifest/bootstrap.json';

  final PublicCacheClient _cacheClient;

  Future<BootstrapData> loadBootstrap() async {
    final pack = await _cacheClient.loadPackFromManifest(bootstrapManifestPath);
    return BootstrapData.fromJson(pack);
  }
}

class BootstrapData {
  const BootstrapData({
    required this.siteName,
    required this.siteUrl,
    required this.apiBase,
    required this.legacyApiBase,
    required this.publicManifests,
    required this.features,
  });

  factory BootstrapData.fromJson(Map<String, dynamic> json) {
    final data = _asMap(json['data']);
    final site = _asMap(data['site']);
    final api = _asMap(data['api']);

    return BootstrapData(
      siteName: _asString(site['name']),
      siteUrl: _asUri(site['url']),
      apiBase: _asUri(api['base']),
      legacyApiBase: _asUri(api['legacy_base']),
      publicManifests: PublicManifests.fromJson(_asMap(data['public'])),
      features: FeatureFlags.fromJson(_asMap(data['features'])),
    );
  }

  final String siteName;
  final Uri? siteUrl;
  final Uri? apiBase;
  final Uri? legacyApiBase;
  final PublicManifests publicManifests;
  final FeatureFlags features;
}

class PublicManifests {
  const PublicManifests({
    required this.home,
    required this.catalog,
    required this.search,
    required this.rankings,
    required this.store,
  });

  factory PublicManifests.fromJson(Map<String, dynamic> json) {
    return PublicManifests(
      home: _asString(json['home_manifest']),
      catalog: _asString(json['catalog_manifest']),
      search: _asString(json['search_manifest']),
      rankings: _asString(json['rankings_manifest']),
      store: _asString(json['store_manifest']),
    );
  }

  final String home;
  final String catalog;
  final String search;
  final String rankings;
  final String store;
}

class FeatureFlags {
  const FeatureFlags({
    required this.vip,
    required this.comments,
    required this.ratings,
    required this.xp,
    required this.translatorAwards,
    required this.htmlAppReader,
  });

  factory FeatureFlags.fromJson(Map<String, dynamic> json) {
    return FeatureFlags(
      vip: _asBool(json['vip']),
      comments: _asBool(json['comments']),
      ratings: _asBool(json['ratings']),
      xp: _asBool(json['xp']),
      translatorAwards: _asBool(json['translator_awards']),
      htmlAppReader: _asBool(json['html_app_reader']),
    );
  }

  final bool vip;
  final bool comments;
  final bool ratings;
  final bool xp;
  final bool translatorAwards;
  final bool htmlAppReader;
}

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }

  return const {};
}

String _asString(Object? value) => value?.toString() ?? '';

Uri? _asUri(Object? value) {
  final text = _asString(value);
  if (text.isEmpty) {
    return null;
  }

  return Uri.parse(text);
}

bool _asBool(Object? value) => value == true;
