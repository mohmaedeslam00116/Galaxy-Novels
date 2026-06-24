import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/app_dependencies.dart';
import '../../../data/repositories/downloads_repository.dart';
import '../../../shared/widgets/novel_cover.dart';
import '../application/download_manager.dart';
import '../domain/downloaded_novel_group.dart';
import 'downloaded_novel_screen.dart';

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
      top: false,
      child: ValueListenableBuilder<DownloadManagerState>(
        valueListenable: downloadManager.state,
        builder: (context, jobState, _) {
          return ValueListenableBuilder<DownloadsState>(
            valueListenable: repository.state,
            builder: (context, downloadsState, _) {
              final groups = groupDownloadedChapters(downloadsState.chapters);
              final totalBytes = groups.fold(
                0,
                (total, group) => total + group.totalBytes,
              );

              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                        sliver: SliverList.list(
                          children: [
                            _DownloadsCountBanner(
                              state: downloadsState,
                              totalBytes: totalBytes,
                            ),
                            if (_showJobBanner(jobState)) ...[
                              const SizedBox(height: 10),
                              _DownloadJobBanner(
                                state: jobState,
                                onTap: downloadManager.showOverlay,
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (groups.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: _DownloadsEmptyState(
                            onOpenLibrary: widget.onOpenLibrary,
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          sliver: SliverList.builder(
                            itemCount: groups.length,
                            itemBuilder: (context, index) {
                              final group = groups[index];
                              return Column(
                                children: [
                                  _DownloadedNovelRow(
                                    group: group,
                                    onTap: () => _openNovel(group.novelId),
                                  ),
                                  if (index < groups.length - 1)
                                    const Divider(height: 1),
                                ],
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _openNovel(int novelId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => DownloadedNovelScreen(novelId: novelId),
      ),
    );
  }
}

bool _showJobBanner(DownloadManagerState state) {
  return state.progress != null &&
      (state.isActive || state.status == DownloadJobStatus.failed);
}

class _DownloadsCountBanner extends StatelessWidget {
  const _DownloadsCountBanner({required this.state, required this.totalBytes});

  final DownloadsState state;
  final int totalBytes;

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
            Expanded(
              child: Text(
                '${state.downloadedCount} / ${state.maxChapters} فصل محمل',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              formatDownloadSize(totalBytes),
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
  const _DownloadedNovelRow({required this.group, required this.onTap});

  final DownloadedNovelGroup group;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            NovelCover.list(
              title: group.novelTitle,
              imageUrl: group.novelCover,
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
                    '${group.downloadedCount} فصل  •  ${formatDownloadSize(group.totalBytes)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'الأحدث: ${group.latestChapter.chapterLabel}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.secondary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_left_rounded, color: colors.onSurfaceVariant),
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
