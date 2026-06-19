import '../../core/network/public_cache_client.dart';
import '../models/catalog_data.dart';
import 'bootstrap_repository.dart';
import 'catalog_repository.dart';

class PublicCatalogRepository implements CatalogRepository {
  const PublicCatalogRepository({
    required BootstrapRepository bootstrapRepository,
    required PublicCacheClient cacheClient,
  }) : _bootstrapRepository = bootstrapRepository,
       _cacheClient = cacheClient;

  final BootstrapRepository _bootstrapRepository;
  final PublicCacheClient _cacheClient;

  @override
  Stream<CatalogLoadState> watchCatalog() async* {
    final bootstrap = await _bootstrapRepository.loadBootstrap();
    final manifestPath = bootstrap.publicManifests.catalog;
    if (manifestPath.isEmpty) {
      throw const PublicCacheException(
        'Bootstrap does not contain catalog manifest.',
      );
    }

    final manifest = CatalogManifest.fromJson(
      await _cacheClient.loadJson(manifestPath),
    );
    if (manifest.packs.isEmpty) {
      yield const CatalogLoadState(
        items: [],
        loadedParts: 0,
        totalParts: 0,
        isLoadingMore: false,
      );
      return;
    }

    final items = <CatalogNovel>[];
    final totalParts = manifest.packs.length;

    for (var index = 0; index < manifest.packs.length; index += 1) {
      final packPath = manifest.packs[index];
      try {
        final pack = CatalogPack.fromJson(
          await _cacheClient.loadJson(packPath),
        );
        items.addAll(pack.items);
        yield CatalogLoadState(
          items: List.unmodifiable(items),
          loadedParts: index + 1,
          totalParts: totalParts,
          isLoadingMore: index + 1 < totalParts,
        );
      } on Object catch (error) {
        if (items.isEmpty) {
          rethrow;
        }

        yield CatalogLoadState(
          items: List.unmodifiable(items),
          loadedParts: index,
          totalParts: totalParts,
          isLoadingMore: false,
          backgroundError: error.toString(),
        );
        return;
      }
    }
  }
}
