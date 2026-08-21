enum ChapterTextBlockType { paragraph, heading }

class ChapterTextBlock {
  const ChapterTextBlock({required this.type, required this.text});

  final ChapterTextBlockType type;
  final String text;
}

typedef ChapterHtmlParser = List<ChapterTextBlock> Function(String html);

List<ChapterTextBlock> parseChapterHtml(String html) {
  final blocks = <ChapterTextBlock>[];
  final pattern = RegExp(
    r'<(p|h[1-6]|blockquote|li)\b[^>]*>(.*?)</\1>',
    caseSensitive: false,
    dotAll: true,
  );

  for (final match in pattern.allMatches(html)) {
    final tag = (match.group(1) ?? '').toLowerCase();
    final raw = match.group(2) ?? '';
    final text = _decodeHtmlEntities(_stripTags(raw)).trim();
    if (text.isEmpty) {
      continue;
    }
    blocks.add(
      ChapterTextBlock(
        type: tag.startsWith('h')
            ? ChapterTextBlockType.heading
            : ChapterTextBlockType.paragraph,
        text: text,
      ),
    );
  }

  if (blocks.isNotEmpty) {
    return blocks;
  }

  final fallback = _decodeHtmlEntities(_stripTags(html)).trim();
  return fallback.isEmpty
      ? const []
      : [
          ChapterTextBlock(
            type: ChapterTextBlockType.paragraph,
            text: fallback,
          ),
        ];
}

String _stripTags(String html) {
  return html
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<[^>]+>'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ');
}

String _decodeHtmlEntities(String text) {
  var result = text
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#8220;', '"')
      .replaceAll('&#8221;', '"')
      .replaceAll('&#8216;', "'")
      .replaceAll('&#8217;', "'");

  result = result.replaceAllMapped(RegExp(r'&#(\d+);'), (match) {
    final value = int.tryParse(match.group(1) ?? '');
    if (value == null) {
      return match.group(0) ?? '';
    }
    return String.fromCharCode(value);
  });

  result = result.replaceAllMapped(RegExp(r'&#x([0-9a-fA-F]+);'), (match) {
    final value = int.tryParse(match.group(1) ?? '', radix: 16);
    if (value == null) {
      return match.group(0) ?? '';
    }
    return String.fromCharCode(value);
  });

  return result.replaceAll(RegExp(r'[ \t]+'), ' ');
}
