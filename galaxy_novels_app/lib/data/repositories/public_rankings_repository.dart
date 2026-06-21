import '../../core/network/public_cache_client.dart';
import '../models/rankings_data.dart';
import 'bootstrap_repository.dart';
import 'rankings_repository.dart';

class PublicRankingsRepository implements RankingsRepository {
  const PublicRankingsRepository({
    required BootstrapRepository bootstrapRepository,
    required PublicCacheClient cacheClient,
  }) : _bootstrapRepository = bootstrapRepository,
       _cacheClient = cacheClient;

  final BootstrapRepository _bootstrapRepository;
  final PublicCacheClient _cacheClient;

  @override
  Future<RankingsData> loadRankings() async {
    final bootstrap = await _bootstrapRepository.loadBootstrap();
    final manifestPath = bootstrap.publicManifests.rankings;
    if (manifestPath.isEmpty) {
      throw const PublicCacheException(
        'Bootstrap does not contain rankings manifest.',
      );
    }

    final rankingsPack = await _cacheClient.loadPackFromManifest(manifestPath);
    return RankingsData.fromJson(rankingsPack);
  }
}
