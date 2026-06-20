import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/data/models/reader_content_data.dart';

void main() {
  test('parses reader chapter content response', () {
    final content = ReaderChapterContent.fromJson({
      'schema': 1,
      'generated': 1781905835,
      'data': {
        'id': 128523,
        'novel_id': 125414,
        'label': 'الفصل 1',
        'display_title': 'الفصل 1: البداية',
        'position': 1,
        'total': 120,
        'navigation': {
          'previous_api': '',
          'next_api': '/wp-json/wor-reader-app/v1/chapters/128524',
        },
        'content_html':
            '<p>الفصل 1: البداية</p><p>&#8220;مرحبا&#8221; بالعالم</p>',
      },
    });

    expect(content.id, 128523);
    expect(content.novelId, 125414);
    expect(content.displayTitle, 'الفصل 1: البداية');
    expect(
      content.navigation.nextApi,
      '/wp-json/wor-reader-app/v1/chapters/128524',
    );
    expect(content.contentHtml, contains('مرحبا'));
  });
}
