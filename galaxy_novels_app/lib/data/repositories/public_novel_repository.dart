import '../../core/network/public_cache_client.dart';
import '../models/novel_details_data.dart';
import 'novel_repository.dart';

class PublicNovelRepository implements NovelRepository {
  const PublicNovelRepository({required PublicCacheClient cacheClient})
    : _cacheClient = cacheClient;

  final PublicCacheClient _cacheClient;

  @override
  Future<NovelDetailsLoadResult> loadNovel(String manifestPath) async {
    if (manifestPath.isEmpty) {
      throw const PublicCacheException('Novel manifest path is empty.');
    }

    final novelPack = await _cacheClient.loadPackFromManifest(manifestPath);
    final details = NovelDetails.fromJson(_asMap(novelPack['data']));

    if (details.chaptersManifest.isEmpty) {
      return NovelDetailsLoadResult(details: details, chapters: const []);
    }

    try {
      final chapterManifestJson = await _cacheClient.loadJson(
        details.chaptersManifest,
      );
      final chapterManifest = ChapterManifest.fromJson(chapterManifestJson);
      if (chapterManifest.packUrl.isEmpty) {
        return NovelDetailsLoadResult(details: details, chapters: const []);
      }

      final chapterPackValue = await _cacheClient.loadJsonValue(
        chapterManifest.packUrl,
      );
      final chapterPack = ChapterPack.fromJsonValue(chapterPackValue);
      return NovelDetailsLoadResult(
        details: details,
        chapters: chapterPack.chapters,
      );
    } on Object catch (error) {
      return NovelDetailsLoadResult(
        details: details,
        chapters: const [],
        chaptersError: error.toString(),
      );
    }
  }
}

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return const {};
}
