import '../../../core/text/arabic_search_normalizer.dart';
import '../../../data/models/novel_details_data.dart';

class ChapterSearchIndex {
  ChapterSearchIndex(Iterable<NovelChapter> chapters)
    : _entries = List.unmodifiable(
        chapters.map(
          (chapter) => _IndexedChapter(
            chapter: chapter,
            normalizedText: normalizeArabicSearch(
              [
                chapter.number,
                chapter.label,
                chapter.title,
                chapter.displayTitle,
                chapter.search,
              ].join(' '),
            ),
          ),
        ),
      );

  final List<_IndexedChapter> _entries;

  List<NovelChapter> search(String query) {
    final normalizedQuery = normalizeArabicSearch(query);
    if (normalizedQuery.isEmpty) {
      return List.unmodifiable(_entries.map((entry) => entry.chapter));
    }

    return List.unmodifiable(
      _entries
          .where((entry) => entry.normalizedText.contains(normalizedQuery))
          .map((entry) => entry.chapter),
    );
  }
}

class _IndexedChapter {
  const _IndexedChapter({required this.chapter, required this.normalizedText});

  final NovelChapter chapter;
  final String normalizedText;
}
