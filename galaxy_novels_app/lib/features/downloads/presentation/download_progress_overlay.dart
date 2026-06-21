import 'package:flutter/material.dart';

import '../../../data/repositories/downloads_repository.dart';
import '../../../shared/widgets/novel_cover.dart';
import '../application/download_manager.dart';

class DownloadProgressOverlay extends StatelessWidget {
  const DownloadProgressOverlay({
    required this.progress,
    required this.onDismiss,
    this.status = DownloadJobStatus.running,
    this.errorMessage,
    this.onPause,
    this.onResume,
    this.onCancel,
    this.onRetry,
    super.key,
  });

  final DownloadBatchProgress progress;
  final VoidCallback onDismiss;
  final DownloadJobStatus status;
  final String? errorMessage;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final VoidCallback? onCancel;
  final VoidCallback? onRetry;

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
                                  _title(status, progress),
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
                            onPressed: onDismiss,
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      LinearProgressIndicator(
                        value: status == DownloadJobStatus.failed
                            ? null
                            : progress.fraction,
                        minHeight: 7,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _statusLabel(progress, status, errorMessage),
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
                      if (_hasControls) ...[
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (status == DownloadJobStatus.running &&
                                onPause != null)
                              TextButton.icon(
                                onPressed: onPause,
                                icon: const Icon(Icons.pause_rounded),
                                label: const Text('إيقاف مؤقت'),
                              ),
                            if (status == DownloadJobStatus.paused &&
                                onResume != null)
                              FilledButton.tonalIcon(
                                onPressed: onResume,
                                icon: const Icon(Icons.play_arrow_rounded),
                                label: const Text('استكمال'),
                              ),
                            if ((status == DownloadJobStatus.running ||
                                    status == DownloadJobStatus.paused) &&
                                onCancel != null)
                              IconButton(
                                onPressed: onCancel,
                                icon: const Icon(Icons.stop_circle_outlined),
                              ),
                            if ((status == DownloadJobStatus.failed ||
                                    progress.failed > 0) &&
                                onRetry != null)
                              FilledButton.tonalIcon(
                                onPressed: onRetry,
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('إعادة المحاولة'),
                              ),
                          ],
                        ),
                      ],
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

  bool get _hasControls {
    return (status == DownloadJobStatus.running && onPause != null) ||
        (status == DownloadJobStatus.paused && onResume != null) ||
        ((status == DownloadJobStatus.running ||
                status == DownloadJobStatus.paused) &&
            onCancel != null) ||
        ((status == DownloadJobStatus.failed || progress.failed > 0) &&
            onRetry != null);
  }
}

String _title(DownloadJobStatus status, DownloadBatchProgress progress) {
  return switch (status) {
    DownloadJobStatus.paused => 'التنزيل متوقف مؤقتا',
    DownloadJobStatus.failed => 'تعذر إكمال التنزيل',
    DownloadJobStatus.cancelled => 'تم إلغاء التنزيل',
    _ => progress.isComplete ? 'اكتمل التنزيل' : 'جاري تنزيل الفصول',
  };
}

String _statusLabel(
  DownloadBatchProgress progress, [
  DownloadJobStatus status = DownloadJobStatus.running,
  String? errorMessage,
]) {
  if (status == DownloadJobStatus.failed && errorMessage != null) {
    return errorMessage;
  }
  if (status == DownloadJobStatus.paused) {
    return 'تم تحميل ${progress.completed} من ${progress.total}';
  }
  if (status == DownloadJobStatus.cancelled) {
    return 'بقيت الفصول المكتملة محفوظة على الجهاز';
  }
  if (!progress.isComplete) {
    return 'جاري تحميل ${progress.completed + progress.failed} من '
        '${progress.total}';
  }
  if (progress.failed == 0) {
    return 'تم تحميل ${progress.completed} فصل بنجاح';
  }
  return 'تم تحميل ${progress.completed} فصل، وفشل ${progress.failed}';
}
