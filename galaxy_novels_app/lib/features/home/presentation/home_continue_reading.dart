import 'package:flutter/material.dart';

import '../../../data/models/home_data.dart';
import '../../../data/models/reading_progress.dart' as local_progress;
import '../../../shared/widgets/novel_list_row.dart';

class HomeContinueReadingEntry {
  const HomeContinueReadingEntry({
    required this.novelTitle,
    required this.chapterTitle,
    required this.completionPercent,
    required this.contentApi,
    this.coverUrl = '',
  });

  factory HomeContinueReadingEntry.fromHome(ReadingProgress progress) {
    return HomeContinueReadingEntry(
      novelTitle: progress.novelTitle,
      chapterTitle: progress.chapterLabel,
      completionPercent: progress.progress,
      contentApi: '',
      coverUrl: progress.coverUrl,
    );
  }

  factory HomeContinueReadingEntry.fromLocal(
    local_progress.ReadingProgress progress,
  ) {
    return HomeContinueReadingEntry(
      novelTitle: progress.displayNovelTitle,
      chapterTitle: progress.displayChapterTitle,
      completionPercent: progress.completionPercent,
      contentApi: progress.contentApi,
      coverUrl: progress.coverUrl,
    );
  }

  final String novelTitle;
  final String chapterTitle;
  final int? completionPercent;
  final String contentApi;
  final String coverUrl;

  String get leadingLabel =>
      completionPercent == null ? 'متابعة' : '$completionPercent%';

  String get meta => completionPercent == null
      ? 'آخر موضع محفوظ'
      : 'تقدم القراءة $completionPercent%';
}

class HomeContinueReadingTile extends StatelessWidget {
  const HomeContinueReadingTile({
    required this.progress,
    required this.onTap,
    super.key,
  });

  final HomeContinueReadingEntry progress;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return NovelListRow(
      title: progress.novelTitle,
      subtitle: progress.chapterTitle,
      meta: progress.meta,
      imageUrl: progress.coverUrl,
      leadingLabel: progress.coverUrl.isEmpty ? progress.leadingLabel : null,
      onTap: onTap,
    );
  }
}
