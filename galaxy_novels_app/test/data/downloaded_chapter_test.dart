import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/data/models/downloaded_chapter.dart';
import 'package:galaxy_novels_app/data/repositories/downloads_repository.dart';

void main() {
  test('downloaded chapter serializes and restores from json', () {
    final downloadedAt = DateTime.utc(2026, 6, 20, 12);
    final chapter = DownloadedChapter(
      novelId: 10,
      novelTitle: 'رواية الاختبار',
      novelCover: '/cover.jpg',
      chapterId: 55,
      chapterTitle: 'البداية',
      chapterLabel: 'الفصل 1',
      chapterPosition: 1,
      chaptersTotal: 120,
      contentApi: '/wp-json/wor-reader-app/v1/chapters/55',
      contentHtml: '<p>نص الفصل</p>',
      plainTextPreview: 'نص الفصل',
      downloadedAt: downloadedAt,
      lastOpenedAt: null,
    );

    final restored = DownloadedChapter.fromJson(chapter.toJson());

    expect(restored.novelId, 10);
    expect(restored.novelTitle, 'رواية الاختبار');
    expect(restored.chapterId, 55);
    expect(restored.contentApi, '/wp-json/wor-reader-app/v1/chapters/55');
    expect(restored.contentHtml, '<p>نص الفصل</p>');
    expect(restored.downloadedAt, downloadedAt);
    expect(restored.lastOpenedAt, isNull);
  });

  test('download state exposes total and remaining slots', () {
    final chapters = List.generate(
      3,
      (index) => DownloadedChapter(
        novelId: 1,
        novelTitle: 'رواية',
        novelCover: '',
        chapterId: index + 1,
        chapterTitle: 'الفصل ${index + 1}',
        chapterLabel: 'الفصل ${index + 1}',
        chapterPosition: index + 1,
        chaptersTotal: 10,
        contentApi: '/chapters/${index + 1}',
        contentHtml: '<p>الفصل</p>',
        plainTextPreview: 'الفصل',
        downloadedAt: DateTime.utc(2026, 6, 20),
        lastOpenedAt: null,
      ),
    );

    final state = DownloadsState(chapters: chapters);

    expect(state.downloadedCount, 3);
    expect(state.remainingSlots, 97);
    expect(state.isFull, isFalse);
  });

  test('download state does not change when source list is mutated', () {
    final chapters = [_downloadedChapter(1)];
    final state = DownloadsState(chapters: chapters);

    chapters.add(_downloadedChapter(2));

    expect(state.downloadedCount, 1);
  });

  test('download state uses configured max chapter limit', () {
    final chapters = List.generate(3, (index) => _downloadedChapter(index + 1));
    final state = DownloadsState(chapters: chapters, maxChapters: 5);

    expect(state.downloadedCount, 3);
    expect(state.remainingSlots, 2);
    expect(state.isFull, isFalse);
  });

  test('download limit policy blocks requests above remaining slots', () {
    const policy = DownloadLimitPolicy(maxChapters: 100);

    expect(policy.canDownload(currentCount: 99, requestedCount: 1), isTrue);
    expect(policy.canDownload(currentCount: 99, requestedCount: 2), isFalse);
    expect(policy.remainingSlots(currentCount: 101), 0);
  });

  test('download limit policy exposes the default max chapter limit', () {
    expect(DownloadLimitPolicy.defaultMaxChapters, 100);
    expect(
      DownloadsState().maxChapters,
      DownloadLimitPolicy.defaultMaxChapters,
    );
  });
}

DownloadedChapter _downloadedChapter(int id) {
  return DownloadedChapter(
    novelId: 1,
    novelTitle: 'رواية',
    novelCover: '',
    chapterId: id,
    chapterTitle: 'الفصل $id',
    chapterLabel: 'الفصل $id',
    chapterPosition: id,
    chaptersTotal: 10,
    contentApi: '/chapters/$id',
    contentHtml: '<p>الفصل</p>',
    plainTextPreview: 'الفصل',
    downloadedAt: DateTime.utc(2026, 6, 20),
    lastOpenedAt: null,
  );
}
