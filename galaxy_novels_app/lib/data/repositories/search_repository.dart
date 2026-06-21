import '../models/search_index_data.dart';

abstract class SearchRepository {
  Future<SearchIndex> loadSearchIndex();
}
