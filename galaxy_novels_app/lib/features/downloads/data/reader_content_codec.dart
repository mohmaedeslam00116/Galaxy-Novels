import 'dart:convert';

import '../../../data/models/reader_content_data.dart';

class ReaderContentCodec {
  const ReaderContentCodec();

  String encode(ReaderChapterContent content) {
    return jsonEncode({
      'version': 1,
      'data': {
        'id': content.id,
        'novel_id': content.novelId,
        'label': content.label,
        'title': content.title,
        'display_title': content.displayTitle,
        'position': content.position,
        'total': content.total,
        'content_html': content.contentHtml,
        'navigation': {
          'previous_api': content.navigation.previousApi,
          'next_api': content.navigation.nextApi,
          'previous_id': content.navigation.previousId,
          'next_id': content.navigation.nextId,
        },
      },
    });
  }

  ReaderChapterContent decode(String encoded) {
    final decoded = jsonDecode(encoded);
    if (decoded is! Map<String, dynamic> || decoded['version'] != 1) {
      throw const FormatException('Unsupported downloaded chapter payload.');
    }
    final data = decoded['data'];
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Missing downloaded chapter data.');
    }
    return ReaderChapterContent.fromJson(data);
  }
}
