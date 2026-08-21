import '../../downloads/domain/download_models.dart';
import '../domain/readable_chapter.dart';

String chapterDownloadKey(ReadableChapter chapter) =>
    '${chapter.isVip ? 'vip' : 'public'}:${chapter.id}';

DownloadChapterRequest chapterDownloadRequest(ReadableChapter chapter) {
  return DownloadChapterRequest(
    chapterKey: chapterDownloadKey(chapter),
    chapterId: chapter.id,
    label: chapter.label,
    contentApi: chapter.contentApi,
    isVip: chapter.isVip,
  );
}
