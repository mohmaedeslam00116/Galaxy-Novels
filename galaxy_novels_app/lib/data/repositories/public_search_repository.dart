import '../../core/network/public_cache_client.dart';
import '../models/search_index_data.dart';
import 'bootstrap_repository.dart';
import 'search_repository.dart';

class PublicSearchRepository implements SearchRepository {
  const PublicSearchRepository({
    required BootstrapRepository bootstrapRepository,
    required PublicCacheClient cacheClient,
  }) : _bootstrapRepository = bootstrapRepository,
       _cacheClient = cacheClient;

  final BootstrapRepository _bootstrapRepository;
  final PublicCacheClient _cacheClient;

  @override
  Future<SearchIndex> loadSearchIndex() async {
    final bootstrap = await _bootstrapRepository.loadBootstrap();
    final manifestPath = bootstrap.publicManifests.search;
    if (manifestPath.isEmpty) {
      throw const PublicCacheException(
        'Bootstrap does not contain search manifest.',
      );
    }

    final manifest = SearchManifest.fromJson(
      await _cacheClient.loadJson(manifestPath),
    );
    if (manifest.index.isEmpty) {
      return const SearchIndex(items: []);
    }

    final indexJson = await _cacheClient.loadJson(manifest.index);
    return SearchIndex.fromJson(indexJson);
  }
}
