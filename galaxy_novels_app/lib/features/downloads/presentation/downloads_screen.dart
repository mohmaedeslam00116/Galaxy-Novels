import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/app_dependencies.dart';
import '../../../app/app_theme.dart';
import '../../../data/models/downloaded_chapter.dart';
import '../../../data/repositories/downloads_repository.dart';
import '../../../shared/widgets/section_title.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

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
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              const SectionTitle(
                title: 'التنزيلات',
                leadingIcon: Icons.download_rounded,
              ),
              _DownloadsCountBanner(state: state),
              if (groups.isEmpty)
                const _DownloadsEmptyState()
              else
                for (final group in groups) _DownloadedNovelRow(group: group),
            ],
          );
        },
      ),
    );
  }
}

class _DownloadsCountBanner extends StatelessWidget {
  const _DownloadsCountBanner({required this.state});

  final DownloadsState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tokens.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: tokens.border),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(Icons.offline_pin_rounded, color: tokens.accent),
              const SizedBox(width: 10),
              Text(
                '${state.downloadedCount} / ${state.maxChapters} فصل محمل',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: tokens.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
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
    final tokens = theme.extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tokens.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: tokens.border),
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
                  color: tokens.surfaceRaised,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.menu_book_rounded, color: tokens.primary),
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
                        color: tokens.textSecondary,
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
                  color: tokens.accent,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DownloadsEmptyState extends StatelessWidget {
  const _DownloadsEmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 0),
      child: Column(
        children: [
          Icon(
            Icons.download_for_offline_outlined,
            color: tokens.accent,
            size: 44,
          ),
          const SizedBox(height: 16),
          Text(
            'الفصول التي تحملها ستظهر هنا للقراءة بدون إنترنت',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              color: tokens.textSecondary,
              fontWeight: FontWeight.w800,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          OutlinedButton(onPressed: () {}, child: const Text('فتح المكتبة')),
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
