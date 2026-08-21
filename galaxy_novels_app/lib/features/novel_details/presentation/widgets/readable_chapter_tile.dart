import 'package:flutter/material.dart';

import '../../../../design_system/novel/galaxy_chapter_row.dart';
import '../../domain/readable_chapter.dart';
import '../chapter_download_state.dart';

class ReadableChapterTile extends StatelessWidget {
  const ReadableChapterTile({
    required this.chapter,
    required this.onTap,
    this.onDownload,
    this.downloadState = ChapterDownloadState.available,
    this.onRetryDownload,
    this.selectionMode = false,
    this.selected = false,
    this.onToggleSelection,
    super.key,
  });

  final ReadableChapter chapter;
  final VoidCallback? onTap;
  final VoidCallback? onDownload;
  final ChapterDownloadState downloadState;
  final VoidCallback? onRetryDownload;
  final bool selectionMode;
  final bool selected;
  final VoidCallback? onToggleSelection;

  @override
  Widget build(BuildContext context) {
    final number = chapter.number.isNotEmpty
        ? chapter.number
        : '${chapter.sortPosition}';
    final unavailableReason = chapter.isVip && onTap == null
        ? 'مسار القراءة غير متاح حاليًا'
        : null;
    final state = switch (downloadState.status) {
      ChapterDownloadStatus.available => GalaxyChapterState.available,
      ChapterDownloadStatus.queued => GalaxyChapterState.queued,
      ChapterDownloadStatus.downloading => GalaxyChapterState.downloading,
      ChapterDownloadStatus.paused => GalaxyChapterState.paused,
      ChapterDownloadStatus.downloaded => GalaxyChapterState.downloaded,
      ChapterDownloadStatus.failed => GalaxyChapterState.failed,
    };
    final showsDownloadAction =
        onDownload != null ||
        downloadState.status != ChapterDownloadStatus.available;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: GalaxyChapterRow(
        chapter: GalaxyChapterRowData(
          title: chapter.label,
          subtitle: chapter.title.isNotEmpty
              ? chapter.title
              : chapter.dateLabel.isNotEmpty
              ? chapter.dateLabel
              : null,
          leadingLabel: number,
          state: showsDownloadAction ? state : GalaxyChapterState.available,
          isVip: chapter.isVip,
          unavailableReason: unavailableReason,
        ),
        onTap: onTap,
        onAction: showsDownloadAction
            ? downloadState.status == ChapterDownloadStatus.failed
                  ? onRetryDownload
                  : onDownload
            : null,
        actionKey: showsDownloadAction
            ? ValueKey(
                'chapter-download-${chapter.isVip ? 'vip' : 'public'}:${chapter.id}',
              )
            : null,
        selectionMode: selectionMode,
        selected: selected,
        onSelectionChanged: onToggleSelection == null
            ? null
            : (_) => onToggleSelection!(),
        showAction: showsDownloadAction,
        showNavigationIndicator: !selectionMode,
      ),
    );
  }
}
