import 'package:flutter/material.dart';

import '../../domain/readable_chapter.dart';
import '../chapter_download_state.dart';
import '../novel_details_visual_tokens.dart';

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
    final theme = Theme.of(context);
    final tokens = NovelDetailsVisualTokens.of(context);
    final number = chapter.number.isNotEmpty
        ? chapter.number
        : '${chapter.sortPosition}';
    final borderColor = chapter.isVip
        ? const Color(0xFFEDC156).withValues(alpha: 0.36)
        : tokens.border;
    final accentColor = chapter.isVip
        ? const Color(0xFFEDC156)
        : tokens.primary;
    final unavailableReason = chapter.isVip && onTap == null
        ? 'مسار القراءة غير متاح حاليًا'
        : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: selectionMode ? onToggleSelection : onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: tokens.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 82),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.only(start: 10),
                    child: Container(
                      width: 46,
                      height: 46,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: chapter.isVip
                            ? const Color(0xFFEDC156).withValues(alpha: 0.10)
                            : tokens.surfaceHigh,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.28),
                        ),
                      ),
                      child: Text(
                        number,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: accentColor,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                chapter.label,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            if (chapter.isVip) ...[
                              const SizedBox(width: 8),
                              const _VipBadge(color: Color(0xFFEDC156)),
                            ],
                          ],
                        ),
                        if (chapter.title.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            chapter.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: tokens.textSecondary,
                              height: 1.2,
                            ),
                          ),
                        ] else if (chapter.dateLabel.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            chapter.dateLabel,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: tokens.textSecondary,
                              height: 1.2,
                            ),
                          ),
                        ],
                        if (unavailableReason != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            unavailableReason,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: tokens.textSecondary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (selectionMode)
                    Checkbox(
                      value: selected,
                      onChanged: (_) => onToggleSelection?.call(),
                    )
                  else ...[
                    if (onDownload != null ||
                        downloadState.status != ChapterDownloadStatus.available)
                      _ChapterDownloadAction(
                        actionKey: ValueKey(
                          'chapter-download-${chapter.isVip ? 'vip' : 'public'}:${chapter.id}',
                        ),
                        state: downloadState,
                        onDownload: onDownload,
                        onRetry: onRetryDownload,
                      ),
                    Icon(
                      unavailableReason == null
                          ? Icons.chevron_left_rounded
                          : Icons.lock_outline_rounded,
                      size: 24,
                      color: accentColor,
                    ),
                  ],
                  const SizedBox(width: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChapterDownloadAction extends StatelessWidget {
  const _ChapterDownloadAction({
    required this.actionKey,
    required this.state,
    required this.onDownload,
    required this.onRetry,
  });

  final Key actionKey;
  final ChapterDownloadState state;
  final VoidCallback? onDownload;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => switch (state.status) {
    ChapterDownloadStatus.available => IconButton(
      key: actionKey,
      tooltip: 'تنزيل الفصل',
      onPressed: onDownload,
      icon: const Icon(Icons.download_rounded),
    ),
    ChapterDownloadStatus.pending => Semantics(
      key: actionKey,
      container: true,
      excludeSemantics: true,
      label: 'الفصل قيد التنزيل',
      child: const Tooltip(
        message: 'الفصل قيد التنزيل',
        child: SizedBox.square(
          dimension: 48,
          child: Center(
            child: SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
          ),
        ),
      ),
    ),
    ChapterDownloadStatus.downloaded => IconButton(
      key: actionKey,
      tooltip: 'تم تنزيل الفصل',
      onPressed: null,
      disabledColor: NovelDetailsVisualTokens.of(context).primary,
      icon: const Icon(Icons.download_done_rounded),
    ),
    ChapterDownloadStatus.failed => IconButton(
      key: actionKey,
      tooltip: 'إعادة محاولة تنزيل الفصل',
      onPressed: onRetry,
      color: Theme.of(context).colorScheme.error,
      icon: const Icon(Icons.refresh_rounded),
    ),
  };
}

class _VipBadge extends StatelessWidget {
  const _VipBadge({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        child: Text(
          'VIP',
          style: theme.textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
