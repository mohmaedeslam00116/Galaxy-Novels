import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/features/reader/data/chapter_html_parser.dart';

void main() {
  test('converts basic chapter html into native text blocks', () {
    final blocks = parseChapterHtml(
      '<h2>عنوان</h2><p>&#8220;مرحبا&#8221; &amp; أهلا</p><p>سطر&nbsp;آخر</p>',
    );

    expect(blocks, hasLength(3));
    expect(blocks[0].type, ChapterTextBlockType.heading);
    expect(blocks[0].text, 'عنوان');
    expect(blocks[1].text, '"مرحبا" & أهلا');
    expect(blocks[2].text, 'سطر آخر');
  });
}
