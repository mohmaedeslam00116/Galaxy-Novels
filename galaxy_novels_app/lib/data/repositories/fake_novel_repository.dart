import '../models/novel_details_data.dart';
import 'novel_repository.dart';

class FakeNovelRepository implements NovelRepository {
  const FakeNovelRepository({required this.result, this.error});

  final NovelDetailsLoadResult? result;
  final Object? error;

  @override
  Future<NovelDetailsLoadResult> loadNovel(String manifestPath) async {
    final thrown = error;
    if (thrown != null) {
      throw thrown;
    }
    return result ??
        const NovelDetailsLoadResult(
          details: NovelDetails(
            id: 0,
            title: 'رواية تجريبية',
            originalTitle: '',
            url: '',
            coverThumbnail: '',
            coverMedium: '',
            coverLarge: '',
            statusKey: '',
            statusLabel: '',
            country: '',
            author: '',
            translator: '',
            genres: [],
            chaptersCount: 0,
            firstChapterId: 0,
            firstChapterUrl: '',
            ratingAverage: 0,
            ratingCount: 0,
            views: 0,
            updatedAt: null,
            summary: '',
            chaptersManifest: '',
            vipScheduleManifest: '',
            manifest: '',
          ),
          chapters: [],
        );
  }
}
