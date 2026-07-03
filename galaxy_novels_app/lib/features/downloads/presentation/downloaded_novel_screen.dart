import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/app_dependencies.dart';
import '../../../app/app_theme.dart';
import '../../../data/models/downloaded_chapter.dart';
import '../../../data/repositories/downloads_repository.dart';
import '../../../shared/widgets/novel_cover.dart';
import '../../reader/presentation/reader_screen.dart';
import '../domain/downloaded_novel_group.dart';

class DownloadedNovelScreen extends StatefulWidget {
  const DownloadedNovelScreen({required this.novelId, super.key});

  final int novelId;

  @override
  State<DownloadedNovelScreen> createState() => _DownloadedNovelScreenState();
}

class _DownloadedNovelScreenState extends State<DownloadedNovelScreen> {
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('الفصول المحملة'),
        actions: [
          IconButton(
            tooltip: 'حذف تنزيلات الرواية',
            onPressed: () => _confirmDeleteNovel(repository),
            icon: const Icon(Icons.delete_sweep_outlined),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ValueListenableBuilder<DownloadsState>(
              valueListenable: repository.state,
              builder: (context, state, _) {
                final group = _findGroup(state.chapters);
                if (group == null) {
                  return _DownloadsRemovedState(
                    onBack: () => Navigator.of(context).pop(),
                  );
                }
                return _DownloadedChaptersList(
                  group: group,
                  onOpen: _openChapter,
                  onDelete: (chapter) => _confirmDeleteChapter(
                    repository,
                    chapter,
                    group.downloadedCount,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  DownloadedNovelGroup? _findGroup(List<DownloadedChapter> chapters) {
    for (final group in groupDownloadedChapters(chapters)) {
      if (group.novelId == widget.novelId) {
        return group;
      }
    }
    return null;
  }

  void _openChapter(DownloadedChapter chapter) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ReaderScreen(
          contentApi: chapter.contentApi,
          chapterTitle: chapter.chapterLabel,
          novelTitle: chapter.novelTitle,
          coverUrl: chapter.novelCover,
        ),
      ),
    );
  }

  Future<void> _confirmDeleteChapter(
    DownloadsRepository repository,
    DownloadedChapter chapter,
    int chapterCount,
  ) async {
    final confirmed = await _showDeleteConfirmation(
      title: 'حذف الفصل المحمل؟',
      message: 'سيُحذف ${chapter.chapterLabel} من الجهاز.',
      actionLabel: 'حذف الفصل',
    );
    if (!confirmed) {
      return;
    }

    try {
      await repository.deleteChapter(chapter.contentApi);
    } on Object {
      _showDeleteError();
      return;
    }
    if (!mounted) {
      return;
    }
    if (chapterCount == 1) {
      Navigator.of(context).pop();
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('تم حذف الفصل المحمل')));
  }

  Future<void> _confirmDeleteNovel(DownloadsRepository repository) async {
    final group = _findGroup(repository.state.value.chapters);
    if (group == null) {
      return;
    }
    final confirmed = await _showDeleteConfirmation(
      title: 'حذف كل الفصول؟',
      message: 'سيُحذف ${group.downloadedCount} فصل من ${group.novelTitle}.',
      actionLabel: 'حذف الكل',
    );
    if (!confirmed) {
      return;
    }

    try {
      await repository.deleteNovelDownloads(widget.novelId);
    } on Object {
      _showDeleteError();
      return;
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<bool> _showDeleteConfirmation({
    required String title,
    required String message,
    required String actionLabel,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final tokens =
            Theme.of(context).extension<AppThemeTokens>() ??
            AppTheme.galaxyNoir;
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: tokens.danger),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(actionLabel),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  void _showDeleteError() {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تعذر حذف التنزيل، حاول مجددا')),
    );
  }
}

class _DownloadedChaptersList extends StatelessWidget {
  const _DownloadedChaptersList({
    required this.group,
    required this.onOpen,
    required this.onDelete,
  });

  final DownloadedNovelGroup group;
  final ValueChanged<DownloadedChapter> onOpen;
  final ValueChanged<DownloadedChapter> onDelete;

  @override
  Widget build(BuildContext context) {
    final chapters = group.chapters.reversed.toList(growable: false);
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: chapters.length + 1,
      separatorBuilder: (context, index) {
        if (index == 0) {
          return const SizedBox(height: 8);
        }
        return const Divider(height: 1, indent: 16, endIndent: 16);
      },
      itemBuilder: (context, index) {
        if (index == 0) {
          return _DownloadedNovelHeader(group: group);
        }
        final chapter = chapters[index - 1];
        return _DownloadedChapterRow(
          chapter: chapter,
          onOpen: () => onOpen(chapter),
          onDelete: () => onDelete(chapter),
        );
      },
    );
  }
}

class _DownloadedNovelHeader extends StatelessWidget {
  const _DownloadedNovelHeader({required this.group});

  final DownloadedNovelGroup group;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NovelCover(
            title: group.novelTitle,
            imageUrl: group.novelCover,
            width: 82,
            height: 118,
            borderRadius: 8,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.novelTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${group.downloadedCount} فصل متاح دون إنترنت',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: tokens.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.storage_outlined,
                      size: 18,
                      color: tokens.accent,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      formatDownloadSize(group.totalBytes),
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: tokens.accent,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DownloadedChapterRow extends StatelessWidget {
  const _DownloadedChapterRow({
    required this.chapter,
    required this.onOpen,
    required this.onDelete,
  });

  final DownloadedChapter chapter;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;
    final rawTitle = chapter.chapterLabel.isNotEmpty
        ? chapter.chapterLabel
        : chapter.chapterTitle;
    final title = rawTitle.isNotEmpty ? rawTitle : 'فصل محمل';
    final subtitle =
        chapter.chapterTitle.isNotEmpty && chapter.chapterTitle != title
        ? chapter.chapterTitle
        : 'محمل ${_dateLabel(chapter.downloadedAt)}';

    return InkWell(
      onTap: onOpen,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 10, 8, 10),
        child: Row(
          children: [
            SizedBox.square(
              dimension: 44,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: tokens.surfaceRaised,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.menu_book_outlined, color: tokens.primary),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: tokens.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatDownloadSize(chapter.contentByteSize),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: tokens.accent,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_left_rounded, color: tokens.textSecondary),
            IconButton(
              tooltip: 'حذف الفصل',
              onPressed: onDelete,
              icon: Icon(Icons.delete_outline_rounded, color: tokens.danger),
            ),
          ],
        ),
      ),
    );
  }
}

class _DownloadsRemovedState extends StatelessWidget {
  const _DownloadsRemovedState({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.download_done_rounded, size: 44),
            const SizedBox(height: 14),
            const Text('لم تعد هناك فصول محملة لهذه الرواية'),
            const SizedBox(height: 18),
            OutlinedButton(onPressed: onBack, child: const Text('رجوع')),
          ],
        ),
      ),
    );
  }
}

String _dateLabel(DateTime value) {
  final local = value.toLocal();
  return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
}
