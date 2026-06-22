import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/data/models/novel_details_data.dart';
import 'package:galaxy_novels_app/features/novel_details/domain/chapter_search_index.dart';

void main() {
  final chapters = [
    _chapter(1, 'الفصل 1', 'البداية'),
    _chapter(25, 'الفصل 25', 'بوابة النجوم'),
    _chapter(283, 'الفصل 283', 'العودة إلى القصر'),
  ];

  test('blank search keeps every chapter in source order', () {
    final result = ChapterSearchIndex(chapters).search('  ');

    expect(result.map((chapter) => chapter.id), [1, 25, 283]);
  });

  test('searches chapter numbers and Arabic titles locally', () {
    final index = ChapterSearchIndex(chapters);

    expect(index.search('283').single.id, 283);
    expect(index.search('بوابة النجوم').single.id, 25);
    expect(index.search('العوده الى القصر').single.id, 283);
  });

  test('returns an empty list when no chapter matches', () {
    expect(ChapterSearchIndex(chapters).search('غير موجود'), isEmpty);
  });
}

NovelChapter _chapter(int id, String label, String title) {
  return NovelChapter(
    id: id,
    position: id,
    number: '$id',
    label: label,
    title: title,
    url: '/chapter-$id/',
    contentApi: '/chapters/$id',
    dateLabel: 'اليوم',
    dateIso: null,
    views: 0,
    comments: 0,
    search: '$label $title',
  );
}
