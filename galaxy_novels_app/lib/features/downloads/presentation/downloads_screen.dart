import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/app_dependencies.dart';
import '../../../data/models/downloaded_chapter.dart';
import '../../../data/repositories/downloads_repository.dart';
import '../application/download_manager.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({this.onOpenLibrary, super.key});

  final VoidCallback? onOpenLibrary;

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  DownloadsRepository? _repository;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final repository = AppDependencies.of(context).downloadsRepository;
    if (_repository == repository) {
      return;
    }

    _repository = repository;
    unawaited(repository.load());
  }

  @override
  Widget build(BuildContext context) {
    final dependencies = AppDependencies.of(context);
    final repository = _repository ?? dependencies.downloadsRepository;
    final downloadManager = dependencies.downloadManager;

    return SafeArea(
      child: ValueListenableBuilder<DownloadManagerState>(
        valueListenable: downloadManager.state,
        builder: (context, jobState, _) {
          return ValueListenableBuilder<DownloadsState>(
            valueListenable: repository.state,
            builder: (context, downloadsState, _) {
              final groups = _groupByNovel(downloadsState.chapters);

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  const _DownloadsHeading(),
                  const SizedBox(height: 14),
                  _DownloadsCountBanner(state: downloadsState),
                  if (_showJobBanner(jobState)) ...[
                    const SizedBox(height: 10),
                    _DownloadJobBanner(
                      state: jobState,
                      onTap: downloadManager.showOverlay,
                    ),
                  ],
                  const SizedBox(height: 16),
                  if (groups.isEmpty)
                    _DownloadsEmptyState(onOpenLibrary: widget.onOpenLibrary)
                  else
                    for (final group in groups) ...[
                      _DownloadedNovelRow(group: group),
                      const SizedBox(height: 12),
                    ],
                ],
              );
            },
          );
        },
      ),
    );
  }
}

bool _showJobBanner(DownloadManagerState state) {
  return state.progress != null &&
      (state.isActive || state.status == DownloadJobStatus.failed);
}

class _DownloadsHeading extends StatelessWidget {
  const _DownloadsHeading();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.secondary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.download_rounded, color: colors.secondary),
        ),
        const SizedBox(width: 12),
        Text(
          'التنزيلات',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _DownloadsCountBanner extends StatelessWidget {
  const _DownloadsCountBanner({required this.state});

  final DownloadsState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(Icons.offline_pin_rounded, color: colors.secondary),
            const SizedBox(width: 10),
            Text(
              '${state.downloadedCount} / ${state.maxChapters} فصل محمل',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DownloadJobBanner extends StatelessWidget {
  const _DownloadJobBanner({required this.state, required this.onTap});

  final DownloadManagerState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final progress = state.progress!;
    final isPaused = state.status == DownloadJobStatus.paused;
    final isFailed = state.status == DownloadJobStatus.failed;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Ink(
        decoration: BoxDecoration(
          color: colors.secondaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(
              isFailed
                  ? Icons.error_outline_rounded
                  : isPaused
                  ? Icons.pause_circle_outline_rounded
                  : Icons.downloading_rounded,
              color: isFailed ? colors.error : colors.onSecondaryContainer,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isFailed
                    ? 'تعذر إكمال التنزيل'
                    : isPaused
                    ? 'التنزيل متوقف مؤقتا'
                    : 'جاري تحميل ${progress.completed + progress.failed} من ${progress.total}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: isFailed ? colors.error : colors.onSecondaryContainer,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.open_in_new_rounded, size: 18),
          ],
        ),
      ),
    );
  }
}

class _DownloadedNovelRow extends StatelessWidget {
  const _DownloadedNovelRow({required this.group});

  final _DownloadedNovelGroup group;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.menu_book_rounded, color: colors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.novelTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    group.chapterLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${group.downloadedCount} فصل',
              style: theme.textTheme.labelLarge?.copyWith(
                color: colors.secondary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DownloadsEmptyState extends StatelessWidget {
  const _DownloadsEmptyState({required this.onOpenLibrary});

  final VoidCallback? onOpenLibrary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 48, 8, 0),
      child: Column(
        children: [
          Icon(
            Icons.download_for_offline_outlined,
            color: colors.secondary,
            size: 44,
          ),
          const SizedBox(height: 16),
          Text(
            'الفصول التي تحملها ستظهر هنا للقراءة بدون إنترنت',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w800,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          OutlinedButton(
            onPressed: onOpenLibrary,
            child: const Text('فتح المكتبة'),
          ),
        ],
      ),
    );
  }
}

class _DownloadedNovelGroup {
  const _DownloadedNovelGroup({
    required this.novelId,
    required this.novelTitle,
    required this.chapters,
  });

  final int novelId;
  final String novelTitle;
  final List<DownloadedChapter> chapters;

  int get downloadedCount => chapters.length;

  String get chapterLabel {
    if (chapters.isEmpty) {
      return '';
    }

    final first = chapters.first.chapterLabel;
    final last = chapters.last.chapterLabel;
    if (first.isEmpty) {
      return last;
    }
    if (last.isEmpty || first == last) {
      return first;
    }
    return '$first - $last';
  }
}

List<_DownloadedNovelGroup> _groupByNovel(List<DownloadedChapter> chapters) {
  final grouped = <int, List<DownloadedChapter>>{};
  for (final chapter in chapters) {
    grouped.putIfAbsent(chapter.novelId, () => []).add(chapter);
  }

  return grouped.entries.map((entry) {
    final sortedChapters = [...entry.value]
      ..sort((a, b) => a.chapterPosition.compareTo(b.chapterPosition));
    final title = sortedChapters
        .map((chapter) => chapter.novelTitle)
        .firstWhere(
          (title) => title.isNotEmpty,
          orElse: () => 'رواية بدون عنوان',
        );

    return _DownloadedNovelGroup(
      novelId: entry.key,
      novelTitle: title,
      chapters: sortedChapters,
    );
  }).toList();
}
