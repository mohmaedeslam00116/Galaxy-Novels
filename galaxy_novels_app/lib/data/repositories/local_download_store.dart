import '../models/downloaded_chapter.dart';

abstract class LocalDownloadStore {
  const LocalDownloadStore();

  Future<List<DownloadedChapter>> readChapters();

  Future<void> writeChapters(List<DownloadedChapter> chapters);
}

abstract interface class ClearableDownloadStore {
  Future<void> clear();
}

abstract interface class DownloadContentStore {
  Future<String?> readChapterContent(DownloadedChapter chapter);
}
