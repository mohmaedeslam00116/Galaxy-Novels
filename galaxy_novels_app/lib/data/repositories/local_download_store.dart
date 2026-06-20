import '../models/downloaded_chapter.dart';

abstract class LocalDownloadStore {
  const LocalDownloadStore();

  Future<List<DownloadedChapter>> readChapters();

  Future<void> writeChapters(List<DownloadedChapter> chapters);
}
