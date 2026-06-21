import '../models/search_index_data.dart';
import 'search_repository.dart';

class FakeSearchRepository implements SearchRepository {
  const FakeSearchRepository({this.index = const SearchIndex(items: [])});

  final SearchIndex index;

  @override
  Future<SearchIndex> loadSearchIndex() async => index;
}
