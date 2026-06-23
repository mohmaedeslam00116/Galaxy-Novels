import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/data/models/reading_progress.dart';
import 'package:galaxy_novels_app/features/history/domain/reading_history_merge.dart';

void main() {
  test('keeps the newest entry and preserves richer same-chapter data', () {
    final local = _progress(
      novelId: 7,
      chapterId: 12,
      updatedAt: DateTime.utc(2026, 6, 23, 10),
      chapterPosition: 12,
      chaptersTotal: 180,
    );
    final remote = _progress(
      novelId: 7,
      chapterId: 12,
      updatedAt: DateTime.utc(2026, 6, 23, 11),
      novelTitle: 'عنوان الحساب',
      chapterTitle: 'الفصل الثاني عشر',
    );

    final merged = mergeReadingHistory([local], [remote]);

    expect(merged.single.updatedAt, remote.updatedAt);
    expect(merged.single.novelTitle, 'عنوان الحساب');
    expect(merged.single.chapterPosition, 12);
    expect(merged.single.chaptersTotal, 180);
    expect(merged.single.completionPercent, 7);
  });

  test('prefers local on equal timestamps and sorts all novels by recency', () {
    final timestamp = DateTime.utc(2026, 6, 23, 10);
    final local = _progress(novelId: 1, chapterId: 4, updatedAt: timestamp);
    final remoteAtSameTime = _progress(
      novelId: 1,
      chapterId: 5,
      updatedAt: timestamp,
    );
    final remoteNewest = _progress(
      novelId: 2,
      chapterId: 8,
      updatedAt: timestamp.add(const Duration(hours: 1)),
    );

    final merged = mergeReadingHistory(
      [local],
      [remoteAtSameTime, remoteNewest],
    );

    expect(merged.map((item) => item.novelId), [2, 1]);
    expect(merged.last.chapterId, 4);
  });
}

ReadingProgress _progress({
  required int novelId,
  required int chapterId,
  required DateTime updatedAt,
  String novelTitle = 'رواية',
  String chapterTitle = 'فصل',
  int chapterPosition = 0,
  int chaptersTotal = 0,
}) {
  return ReadingProgress(
    novelId: novelId,
    novelTitle: novelTitle,
    chapterId: chapterId,
    chapterTitle: chapterTitle,
    contentApi: '/wp-json/wor-reader-app/v1/chapters/$chapterId',
    updatedAt: updatedAt,
    chapterPosition: chapterPosition,
    chaptersTotal: chaptersTotal,
  );
}
