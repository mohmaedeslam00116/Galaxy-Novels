import '../models/catalog_data.dart';
import 'catalog_repository.dart';

class FakeCatalogRepository implements CatalogRepository {
  const FakeCatalogRepository([this.items = _defaultItems]);

  final List<CatalogNovel> items;

  @override
  Stream<CatalogLoadState> watchCatalog() async* {
    yield CatalogLoadState(
      items: items,
      loadedParts: 1,
      totalParts: 1,
      isLoadingMore: false,
    );
  }
}

const _defaultItems = [
  CatalogNovel(
    id: 1,
    title: 'حارس النجوم',
    originalTitle: '',
    url: '/novel/star-guard/',
    coverThumbnail: '',
    coverMedium: '',
    statusKey: 'ongoing',
    statusLabel: 'مستمرة',
    genres: [CatalogGenre(id: 1, name: 'أكشن', slug: 'action')],
    chaptersCount: 82,
    ratingAverage: 4.4,
    ratingCount: 20,
    views: 14000,
    updatedAt: null,
    manifest: '',
  ),
  CatalogNovel(
    id: 2,
    title: 'بوابة الشمال',
    originalTitle: '',
    url: '/novel/north-gate/',
    coverThumbnail: '',
    coverMedium: '',
    statusKey: 'completed',
    statusLabel: 'مكتملة',
    genres: [CatalogGenre(id: 2, name: 'فانتازيا', slug: 'fantasy')],
    chaptersCount: 126,
    ratingAverage: 4.8,
    ratingCount: 45,
    views: 25000,
    updatedAt: null,
    manifest: '',
  ),
];
