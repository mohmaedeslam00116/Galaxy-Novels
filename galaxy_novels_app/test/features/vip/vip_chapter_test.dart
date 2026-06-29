import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/features/vip/domain/vip_chapter.dart';

void main() {
  test('parses a VIP chapter page', () {
    final page = VipChapterPage.fromJson({
      'items': [
        {
          'id': 11,
          'number': '164',
          'position': 164,
          'order': '164.000000',
          'title': 'الفصل 164',
          'url': 'https://galaxynovels.com/chapter-164/',
          'public_at': '2026/06/20 08:00',
          'views': 99,
          'comments': 4,
          'content_api': '/wp-json/wor-reader-app/v1/vip/chapters/11',
        },
      ],
      'has_more': true,
      'next_cursor': {'order': '164.000000', 'id': 11},
      'total_available': 40,
    });

    expect(page.items, hasLength(1));
    expect(page.items.single.id, 11);
    expect(page.items.single.displayLabel, 'الفصل 164');
    expect(page.hasMore, isTrue);
    expect(page.nextCursorOrder, '164.000000');
    expect(page.nextCursorId, 11);
    expect(page.totalAvailable, 40);
    expect(
      page.items.single.contentApi,
      '/wp-json/wor-reader-app/v1/vip/chapters/11',
    );
  });

  test('falls back to position when a VIP chapter has no number', () {
    final chapter = VipChapter.fromJson({
      'id': 7,
      'position': 3,
      'title': 'بداية خاصة',
    });

    expect(chapter.displayLabel, 'الفصل 3');
    expect(chapter.title, 'بداية خاصة');
  });
}
