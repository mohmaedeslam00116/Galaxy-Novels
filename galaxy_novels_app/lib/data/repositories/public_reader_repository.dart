import '../../core/network/public_cache_client.dart';
import '../models/reader_content_data.dart';
import 'reader_repository.dart';

class PublicReaderRepository implements ReaderRepository {
  const PublicReaderRepository({required PublicCacheClient cacheClient})
    : _cacheClient = cacheClient;

  final PublicCacheClient _cacheClient;

  @override
  Future<ReaderChapterContent> loadChapter(String contentApi) async {
    if (contentApi.isEmpty) {
      throw const PublicCacheException('Chapter content API path is empty.');
    }

    final json = await _cacheClient.loadJson(contentApi);
    return ReaderChapterContent.fromJson(json);
  }
}
