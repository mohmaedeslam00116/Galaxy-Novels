import '../models/catalog_data.dart';
import '../models/rankings_data.dart';
import 'rankings_repository.dart';

class FakeRankingsRepository implements RankingsRepository {
  const FakeRankingsRepository();

  @override
  Future<RankingsData> loadRankings() async {
    return const RankingsData(
      period: 'month',
      items: [
        CatalogNovel(
          id: 1,
          title: 'حارس النجوم',
          originalTitle: '',
          url: '/novel/star-guard/',
          coverThumbnail: '',
          coverMedium: '',
          statusKey: 'ongoing',
          statusLabel: 'مستمرة',
          genres: [CatalogGenre(id: 1, name: 'خيال', slug: 'fantasy')],
          chaptersCount: 82,
          ratingAverage: 0,
          ratingCount: 0,
          views: 0,
          updatedAt: null,
          manifest: '',
        ),
      ],
    );
  }
}
