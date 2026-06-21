import 'package:flutter/material.dart';

import '../../../data/repositories/downloads_repository.dart';
import '../../../shared/widgets/novel_cover.dart';

class DownloadProgressOverlay extends StatelessWidget {
  const DownloadProgressOverlay({
    required this.progress,
    required this.onDismiss,
    super.key,
  });

  final DownloadBatchProgress progress;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final processed = progress.completed + progress.failed;

    return Material(
      color: colors.scrim.withValues(alpha: 0.58),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Material(
                color: colors.surfaceContainerHigh,
                elevation: 10,
                borderRadius: BorderRadius.circular(8),
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          NovelCover(
                            title: progress.novelTitle,
                            imageUrl: progress.novelCover,
                            width: 58,
                            height: 84,
                            borderRadius: 6,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  progress.isComplete
                                      ? 'اكتمل التنزيل'
                                      : 'جاري تنزيل الفصول',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  progress.novelTitle,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colors.onSurfaceVariant,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: progress.isComplete ? 'إغلاق' : 'إخفاء',
                            onPressed: onDismiss,
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      LinearProgressIndicator(
                        value: progress.fraction,
                        minHeight: 7,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _statusLabel(progress),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: progress.failed > 0
                                    ? colors.error
                                    : colors.onSurfaceVariant,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Text(
                            '$processed / ${progress.total}',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _statusLabel(DownloadBatchProgress progress) {
  if (!progress.isComplete) {
    return 'جاري تحميل ${progress.completed + progress.failed} من '
        '${progress.total}';
  }
  if (progress.failed == 0) {
    return 'تم تحميل ${progress.completed} فصل بنجاح';
  }
  return 'تم تحميل ${progress.completed} فصل، وفشل ${progress.failed}';
}
