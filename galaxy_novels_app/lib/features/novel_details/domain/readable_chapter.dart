import '../../../data/models/novel_details_data.dart';
import '../../../core/text/arabic_search_normalizer.dart';
import '../../vip/data/vip_reader_request.dart';
import '../../vip/domain/vip_chapter.dart';

const chaptersPerPage = 50;

class ReadableChapter {
  const ReadableChapter._({
    required this.id,
    required this.position,
    required this.number,
    required this.label,
    required this.title,
    required this.dateLabel,
    required this.contentApi,
    required this.isVip,
    required this.publicChapter,
    required this.vipChapter,
  });

  factory ReadableChapter.public(NovelChapter chapter) {
    return ReadableChapter._(
      id: chapter.id,
      position: chapter.position,
      number: chapter.number,
      label: chapter.label.isNotEmpty
          ? chapter.label
          : 'الفصل ${chapter.number}',
      title: chapter.displayTitle,
      dateLabel: chapter.dateLabel,
      contentApi: chapter.effectiveContentApi,
      isVip: false,
      publicChapter: chapter,
      vipChapter: null,
    );
  }

  factory ReadableChapter.vip(VipChapter chapter) {
    return ReadableChapter._(
      id: chapter.id,
      position: chapter.position,
      number: chapter.number,
      label: chapter.displayLabel,
      title: chapter.title,
      dateLabel: chapter.publicAt,
      contentApi: chapter.contentApi.isNotEmpty
          ? chapter.contentApi
          : '/wp-json/wor-reader-app/v1/vip/chapters/${chapter.id}',
      isVip: true,
      publicChapter: null,
      vipChapter: chapter,
    );
  }

  final int id;
  final int position;
  final String number;
  final String label;
  final String title;
  final String dateLabel;
  final String contentApi;
  final bool isVip;
  final NovelChapter? publicChapter;
  final VipChapter? vipChapter;

  int get sortPosition {
    if (position > 0) {
      return position;
    }
    return int.tryParse(number) ?? id;
  }

  String get dedupeKey {
    final normalizedNumber = number.trim();
    if (normalizedNumber.isNotEmpty) {
      return 'number:$normalizedNumber';
    }
    final normalizedPosition = position;
    if (normalizedPosition > 0) {
      return 'position:$normalizedPosition';
    }
    return isVip ? 'vip:$id' : 'public:$id';
  }
}

List<ReadableChapter> mergeReadableChapters({
  required List<NovelChapter> publicChapters,
  required List<VipChapter> vipChapters,
}) {
  final byKey = <String, ReadableChapter>{};

  for (final chapter in vipChapters) {
    final readable = ReadableChapter.vip(chapter);
    byKey[readable.dedupeKey] = readable;
  }

  for (final chapter in publicChapters) {
    final readable = ReadableChapter.public(chapter);
    byKey[readable.dedupeKey] = readable;
  }

  final merged = byKey.values.toList(growable: false)
    ..sort((a, b) {
      final positionCompare = a.sortPosition.compareTo(b.sortPosition);
      if (positionCompare != 0) {
        return positionCompare;
      }
      if (a.isVip == b.isVip) {
        return a.id.compareTo(b.id);
      }
      return a.isVip ? 1 : -1;
    });

  return List.unmodifiable(merged);
}

List<ReadableChapter> readableChaptersForDisplay(
  Iterable<ReadableChapter> chapters, {
  required String query,
  required bool descending,
}) {
  final normalizedQuery = normalizeArabicSearch(query);
  final matchingChapters = chapters
      .where((chapter) {
        if (normalizedQuery.isEmpty) return true;
        final searchable = normalizeArabicSearch(
          [
            chapter.number,
            chapter.label,
            chapter.title,
            chapter.dateLabel,
            if (chapter.isVip) 'vip',
          ].join(' '),
        );
        return searchable.contains(normalizedQuery);
      })
      .toList(growable: false);

  if (descending) return List.unmodifiable(matchingChapters.reversed);
  return List.unmodifiable(matchingChapters);
}

List<ReadableChapter> readableChaptersInPositionRange(
  Iterable<ReadableChapter> chapters, {
  required int start,
  required int end,
}) {
  if (start <= 0 || end < start) {
    return const [];
  }

  return List.unmodifiable(
    chapters.where((chapter) {
      final position = chapter.sortPosition;
      return position >= start && position <= end;
    }),
  );
}

int chapterPageCount(List<ReadableChapter> chapters) {
  if (chapters.isEmpty) {
    return 0;
  }
  return ((chapters.length - 1) ~/ chaptersPerPage) + 1;
}

List<ReadableChapter> chapterPageItems(
  List<ReadableChapter> chapters,
  int pageIndex,
) {
  if (pageIndex < 0 || chapters.isEmpty) {
    return const [];
  }

  final start = pageIndex * chaptersPerPage;
  if (start >= chapters.length) {
    return const [];
  }

  final end = (start + chaptersPerPage).clamp(0, chapters.length);
  return List.unmodifiable(chapters.sublist(start, end));
}

String readableChapterOpenContentApi(
  List<ReadableChapter> chapters,
  int index, {
  required bool directVipChapterRouteAvailable,
}) {
  if (index < 0 || index >= chapters.length) {
    return '';
  }

  final chapter = chapters[index];
  if (!chapter.isVip) {
    return chapter.contentApi;
  }

  final directApi = chapter.contentApi;
  if (directVipChapterRouteAvailable || !_isDirectVipChapterApi(directApi)) {
    return directApi;
  }

  return '';
}

bool _isDirectVipChapterApi(String contentApi) {
  final request = VipReaderRequest.tryParse(contentApi);
  return request?.kind == VipReaderRequestKind.chapter;
}
