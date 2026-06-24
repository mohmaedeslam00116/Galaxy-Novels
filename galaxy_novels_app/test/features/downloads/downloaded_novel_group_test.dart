import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/data/models/downloaded_chapter.dart';
import 'package:galaxy_novels_app/features/downloads/domain/downloaded_novel_group.dart';

void main() {
  test('groups chapters and sorts novels by latest activity', () {
    final groups = groupDownloadedChapters([
      _chapter(1, novelId: 10, downloadedHour: 1, bytes: 1024),
      _chapter(2, novelId: 10, downloadedHour: 2, bytes: 2048),
      _chapter(3, novelId: 20, downloadedHour: 3, bytes: 4096),
    ]);

    expect(groups.map((group) => group.novelId), [20, 10]);
    expect(groups.last.chapters.map((chapter) => chapter.chapterId), [1, 2]);
    expect(groups.last.totalBytes, 3072);
    expect(groups.last.latestChapter.chapterId, 2);
  });

  test('formats download sizes for compact display', () {
    expect(formatDownloadSize(0), '0 KB');
    expect(formatDownloadSize(1024), '1.0 KB');
    expect(formatDownloadSize(3 * 1024 * 1024), '3.0 MB');
  });
}

DownloadedChapter _chapter(
  int id, {
  required int novelId,
  required int downloadedHour,
  required int bytes,
}) {
  return DownloadedChapter(
    novelId: novelId,
    novelTitle: 'رواية $novelId',
    novelCover: '',
    chapterId: id,
    chapterTitle: 'الفصل $id',
    chapterLabel: 'الفصل $id',
    chapterPosition: id,
    chaptersTotal: 10,
    contentApi: '/chapters/$id',
    contentHtml: '<p>الفصل</p>',
    plainTextPreview: 'الفصل',
    contentByteSize: bytes,
    downloadedAt: DateTime.utc(2026, 6, 21, downloadedHour),
    lastOpenedAt: null,
  );
}
