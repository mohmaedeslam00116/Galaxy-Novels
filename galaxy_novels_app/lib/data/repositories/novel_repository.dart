import '../models/novel_details_data.dart';

abstract interface class NovelRepository {
  Future<NovelDetailsLoadResult> loadNovel(String manifestPath);
}

class NovelDetailsLoadResult {
  const NovelDetailsLoadResult({
    required this.details,
    required this.chapters,
    this.chaptersError,
  });

  final NovelDetails details;
  final List<NovelChapter> chapters;
  final String? chaptersError;

  bool get hasReadableChapter =>
      chapters.isNotEmpty || details.firstChapterUrl.isNotEmpty;
}
