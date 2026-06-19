import '../../core/network/public_cache_client.dart';
import '../models/home_data.dart';
import 'bootstrap_repository.dart';
import 'home_repository.dart';

class PublicHomeRepository implements HomeRepository {
  const PublicHomeRepository({
    required BootstrapRepository bootstrapRepository,
    required PublicCacheClient cacheClient,
  }) : _bootstrapRepository = bootstrapRepository,
       _cacheClient = cacheClient;

  final BootstrapRepository _bootstrapRepository;
  final PublicCacheClient _cacheClient;

  @override
  Future<HomeData> loadHome() async {
    final bootstrap = await _bootstrapRepository.loadBootstrap();
    final homePack = await _cacheClient.loadPackFromManifest(
      bootstrap.publicManifests.home,
    );

    return HomeData.fromJson(homePack);
  }
}
