import '../../../data/models/downloaded_chapter.dart';

class DownloadedNovelGroup {
  DownloadedNovelGroup({
    required this.novelId,
    required List<DownloadedChapter> chapters,
  }) : chapters = List.unmodifiable(
         [...chapters]
           ..sort((a, b) => a.chapterPosition.compareTo(b.chapterPosition)),
       );

  final int novelId;
  final List<DownloadedChapter> chapters;

  int get downloadedCount => chapters.length;

  int get totalBytes =>
      chapters.fold(0, (total, chapter) => total + chapter.contentByteSize);

  String get novelTitle {
    return chapters
        .map((chapter) => chapter.novelTitle)
        .firstWhere(
          (title) => title.isNotEmpty,
          orElse: () => 'رواية بدون عنوان',
        );
  }

  String get novelCover {
    return chapters
        .map((chapter) => chapter.novelCover)
        .firstWhere((cover) => cover.isNotEmpty, orElse: () => '');
  }

  DownloadedChapter get latestChapter => chapters.last;

  DateTime get lastActivity {
    return chapters
        .map((chapter) => chapter.lastOpenedAt ?? chapter.downloadedAt)
        .reduce((latest, value) => value.isAfter(latest) ? value : latest);
  }
}

List<DownloadedNovelGroup> groupDownloadedChapters(
  List<DownloadedChapter> chapters,
) {
  final grouped = <int, List<DownloadedChapter>>{};
  for (final chapter in chapters) {
    grouped.putIfAbsent(chapter.novelId, () => []).add(chapter);
  }

  final groups = grouped.entries
      .map(
        (entry) =>
            DownloadedNovelGroup(novelId: entry.key, chapters: entry.value),
      )
      .toList(growable: false);
  groups.sort((a, b) => b.lastActivity.compareTo(a.lastActivity));
  return groups;
}

String formatDownloadSize(int bytes) {
  if (bytes <= 0) {
    return '0 KB';
  }
  if (bytes < 1024) {
    return '$bytes B';
  }
  final kilobytes = bytes / 1024;
  if (kilobytes < 1024) {
    return '${kilobytes.toStringAsFixed(kilobytes >= 100 ? 0 : 1)} KB';
  }
  final megabytes = kilobytes / 1024;
  return '${megabytes.toStringAsFixed(megabytes >= 100 ? 0 : 1)} MB';
}
