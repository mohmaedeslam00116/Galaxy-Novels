import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/app_dependencies.dart';
import '../../../data/models/downloaded_chapter.dart';
import '../../../data/repositories/downloads_repository.dart';

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
    final repository =
        _repository ?? AppDependencies.of(context).downloadsRepository;

    return SafeArea(
      child: ValueListenableBuilder<DownloadsState>(
        valueListenable: repository.state,
        builder: (context, state, _) {
          final groups = _groupByNovel(state.chapters);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              const _DownloadsHeading(),
              const SizedBox(height: 14),
              _DownloadsCountBanner(state: state),
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
      ),
    );
  }
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
