import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/app_dependencies.dart';
import '../../../app/app_theme.dart';
import '../../../data/models/novel_details_data.dart';
import '../../../data/repositories/downloads_repository.dart';
import '../../../data/repositories/novel_repository.dart';
import '../../../shared/widgets/section_title.dart';
import '../../downloads/presentation/chapter_download_button.dart';
import '../../downloads/presentation/download_chapters_sheet.dart';
import '../../downloads/presentation/download_progress_overlay.dart';
import '../../reader/presentation/reader_screen.dart';
import 'widgets/novel_chapter_tile.dart';
import 'widgets/novel_details_header.dart';

class NovelDetailsScreen extends StatefulWidget {
  const NovelDetailsScreen({required this.manifestPath, super.key});

  final String manifestPath;

  @override
  State<NovelDetailsScreen> createState() => _NovelDetailsScreenState();
}

class _NovelDetailsScreenState extends State<NovelDetailsScreen> {
  Future<NovelDetailsLoadResult>? _future;
  NovelRepository? _repository;
  DownloadsRepository? _downloadsRepository;
  StreamSubscription<DownloadBatchProgress>? _downloadSubscription;
  DownloadBatchProgress? _downloadProgress;
  bool _isDownloadOverlayVisible = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final repository = AppDependencies.of(context).novelRepository;
    if (_repository != repository) {
      _repository = repository;
      _future = repository.loadNovel(widget.manifestPath);
    }

    final downloadsRepository = AppDependencies.of(context).downloadsRepository;
    if (_downloadsRepository != downloadsRepository) {
      _downloadsRepository = downloadsRepository;
      unawaited(downloadsRepository.load());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل الرواية')),
      body: Stack(
        children: [
          FutureBuilder<NovelDetailsLoadResult>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const _NovelDetailsSkeleton();
              }

              if (snapshot.hasError || !snapshot.hasData) {
                return _DetailsMessage(
                  title: 'تعذر تحميل تفاصيل الرواية الآن',
                  actionLabel: 'إعادة المحاولة',
                  onAction: _retry,
                );
              }

              return _NovelDetailsContent(
                result: snapshot.data!,
                onRead: _openReader,
                onDownloadChapters: () => _openDownloadSheet(snapshot.data!),
              );
            },
          ),
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: _isDownloadOverlayVisible && _downloadProgress != null
                  ? DownloadProgressOverlay(
                      key: const ValueKey('download-progress-overlay'),
                      progress: _downloadProgress!,
                      onDismiss: _dismissDownloadOverlay,
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _downloadSubscription?.cancel();
    super.dispose();
  }

  void _retry() {
    final repository = _repository;
    if (repository == null) {
      return;
    }
    setState(() {
      _future = repository.loadNovel(widget.manifestPath);
    });
  }

  void _openReader(NovelChapter chapter, String novelTitle) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ReaderScreen(
          contentApi: chapter.effectiveContentApi,
          chapterTitle: chapter.label,
          novelTitle: novelTitle,
        ),
      ),
    );
  }

  Future<void> _openDownloadSheet(NovelDetailsLoadResult result) async {
    final repository = _downloadsRepository;
    if (repository == null || result.chapters.isEmpty) {
      return;
    }
    if (_downloadProgress != null && !_downloadProgress!.isComplete) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('يوجد تنزيل جار بالفعل')));
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return ValueListenableBuilder<DownloadsState>(
          valueListenable: repository.state,
          builder: (context, downloadsState, _) {
            return DownloadChaptersSheet(
              details: result.details,
              chapters: result.chapters,
              downloadsState: downloadsState,
              onStart: (chapters) => _startBatchDownload(result, chapters),
            );
          },
        );
      },
    );
  }

  void _startBatchDownload(
    NovelDetailsLoadResult result,
    List<NovelChapter> chapters,
  ) {
    final repository = _downloadsRepository;
    if (repository == null || chapters.isEmpty) {
      return;
    }

    final requests = chapters
        .map(
          (chapter) => ChapterDownloadRequest(
            novelId: result.details.id,
            novelTitle: result.details.title,
            novelCover: result.details.bestCover,
            chapter: chapter,
          ),
        )
        .toList(growable: false);

    _downloadSubscription?.cancel();
    setState(() {
      _downloadProgress = DownloadBatchProgress(
        novelTitle: result.details.title,
        novelCover: result.details.bestCover,
        total: requests.length,
        completed: 0,
        failed: 0,
        isComplete: false,
      );
      _isDownloadOverlayVisible = true;
    });

    _downloadSubscription = repository
        .downloadChaptersBatch(requests)
        .listen(
          (progress) {
            if (!mounted) {
              return;
            }
            setState(() => _downloadProgress = progress);
          },
          onError: (Object error, StackTrace stackTrace) {
            if (!mounted) {
              return;
            }
            setState(() {
              _downloadProgress = null;
              _isDownloadOverlayVisible = false;
            });
            final message = error is DownloadLimitExceededException
                ? 'وصلت إلى حد 100 فصل محمل'
                : 'تعذر إكمال تنزيل الفصول';
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(message)));
          },
        );
  }

  void _dismissDownloadOverlay() {
    setState(() {
      _isDownloadOverlayVisible = false;
    });
    final progress = _downloadProgress;
    if (progress != null && progress.isComplete) {
      final message = progress.failed == 0
          ? 'اكتمل تحميل ${progress.completed} فصل'
          : 'تم تحميل ${progress.completed} فصل، فشل ${progress.failed}';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }
}

class _NovelDetailsContent extends StatelessWidget {
  const _NovelDetailsContent({
    required this.result,
    required this.onRead,
    required this.onDownloadChapters,
  });

  final NovelDetailsLoadResult result;
  final void Function(NovelChapter chapter, String novelTitle) onRead;
  final VoidCallback onDownloadChapters;

  @override
  Widget build(BuildContext context) {
    final details = result.details;
    final firstReadableChapter = result.chapters.isNotEmpty
        ? result.chapters.first
        : null;
    final canRead =
        firstReadableChapter != null &&
        firstReadableChapter.effectiveContentApi.isNotEmpty;

    return Stack(
      children: [
        ListView(
          padding: EdgeInsets.only(bottom: canRead ? 118 : 28),
          children: [
            NovelDetailsHeader(details: details),
            if (details.summary.isNotEmpty)
              _SummarySection(summary: details.summary),
            _ChaptersSection(
              result: result,
              onRead: onRead,
              onDownloadChapters: onDownloadChapters,
            ),
          ],
        ),
        if (canRead)
          PositionedDirectional(
            start: 0,
            end: 0,
            bottom: 0,
            child: _DetailsBottomBar(
              onRead: () => onRead(firstReadableChapter, details.title),
            ),
          ),
      ],
    );
  }
}

class _SummarySection extends StatefulWidget {
  const _SummarySection({required this.summary});

  final String summary;

  @override
  State<_SummarySection> createState() => _SummarySectionState();
}

class _SummarySectionState extends State<_SummarySection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final isLong = widget.summary.length > 220;
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: 'عن الرواية'),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: tokens.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: tokens.border),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.summary,
                    maxLines: isLong && !_expanded ? 6 : null,
                    overflow: isLong && !_expanded
                        ? TextOverflow.ellipsis
                        : null,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.75,
                      color: tokens.textPrimary.withValues(alpha: 0.88),
                    ),
                  ),
                  if (isLong)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => setState(() => _expanded = !_expanded),
                        child: Text(_expanded ? 'عرض أقل' : 'عرض المزيد'),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailsBottomBar extends StatelessWidget {
  const _DetailsBottomBar({required this.onRead});

  final VoidCallback onRead;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.background,
        border: Border(top: BorderSide(color: tokens.border)),
        boxShadow: [
          BoxShadow(
            color: tokens.primary.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              SizedBox(
                width: 56,
                height: 56,
                child: IconButton(
                  tooltip: 'إضافة للمفضلة',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('سيتم تفعيل المفضلة في مرحلة لاحقة'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.bookmark_add_outlined),
                  style: IconButton.styleFrom(
                    backgroundColor: tokens.surface,
                    foregroundColor: tokens.accent,
                    side: BorderSide(
                      color: tokens.accent.withValues(alpha: 0.26),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onRead,
                  icon: const Icon(Icons.menu_book_outlined),
                  label: const Text('ابدأ القراءة'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    textStyle: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChaptersSection extends StatelessWidget {
  const _ChaptersSection({
    required this.result,
    required this.onRead,
    required this.onDownloadChapters,
  });

  final NovelDetailsLoadResult result;
  final void Function(NovelChapter chapter, String novelTitle) onRead;
  final VoidCallback onDownloadChapters;

  @override
  Widget build(BuildContext context) {
    final chapters = result.chapters;
    final downloadsRepository = AppDependencies.of(context).downloadsRepository;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(
          title: 'آخر الفصول',
          leadingIcon: Icons.menu_book_outlined,
          action: chapters.isEmpty
              ? null
              : TextButton.icon(
                  onPressed: onDownloadChapters,
                  icon: const Icon(Icons.download_outlined),
                  label: const Text('تحميل الفصول'),
                ),
        ),
        if (result.chaptersError != null)
          _InlineMessage(
            title: 'تعذر تحميل الفصول الآن',
            subtitle: result.chaptersError,
          )
        else if (chapters.isEmpty)
          _InlineMessage(
            title: 'لا توجد فصول متاحة للعرض الآن',
            subtitle: result.details.chaptersCount > 0
                ? 'قد تكون الفصول غير منشورة في الفهرس العام بعد'
                : null,
          )
        else
          ValueListenableBuilder<DownloadsState>(
            valueListenable: downloadsRepository.state,
            builder: (context, downloadsState, _) {
              return Column(
                children: [
                  for (final chapter in chapters)
                    NovelChapterTile(
                      chapter: chapter,
                      trailingAction: ChapterDownloadButton(
                        isDownloaded: downloadsState.contains(
                          chapter.effectiveContentApi,
                        ),
                        isEnabled: chapter.effectiveContentApi.isNotEmpty,
                        onPressed: () => _downloadChapter(
                          context,
                          downloadsRepository,
                          chapter,
                        ),
                      ),
                      onTap: () {
                        if (chapter.effectiveContentApi.isNotEmpty) {
                          onRead(chapter, result.details.title);
                        }
                      },
                    ),
                ],
              );
            },
          ),
      ],
    );
  }

  Future<void> _downloadChapter(
    BuildContext context,
    DownloadsRepository repository,
    NovelChapter chapter,
  ) async {
    try {
      await repository.downloadChapter(
        ChapterDownloadRequest(
          novelId: result.details.id,
          novelTitle: result.details.title,
          novelCover: result.details.bestCover,
          chapter: chapter,
        ),
      );
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم تحميل الفصل')));
      }
    } on DownloadLimitExceededException {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('وصلت إلى حد 100 فصل محمل')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر تحميل الفصل، حاول مجددا')),
        );
      }
    }
  }
}

class _InlineMessage extends StatelessWidget {
  const _InlineMessage({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: tokens.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: tokens.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: tokens.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NovelDetailsSkeleton extends StatelessWidget {
  const _NovelDetailsSkeleton();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary.withValues(alpha: 0.10);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      children: [
        Center(
          child: Container(
            width: 150,
            height: 224,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Center(child: Container(width: 210, height: 22, color: color)),
        const SizedBox(height: 10),
        Center(child: Container(width: 160, height: 14, color: color)),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(child: Container(height: 72, color: color)),
            const SizedBox(width: 8),
            Expanded(child: Container(height: 72, color: color)),
            const SizedBox(width: 8),
            Expanded(child: Container(height: 72, color: color)),
          ],
        ),
        const SizedBox(height: 24),
        Container(height: 14, color: color),
        const SizedBox(height: 8),
        Container(height: 14, color: color),
        const SizedBox(height: 8),
        Container(height: 14, width: 180, color: color),
      ],
    );
  }
}

class _DetailsMessage extends StatelessWidget {
  const _DetailsMessage({required this.title, this.actionLabel, this.onAction});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, textAlign: TextAlign.center),
            if (actionLabel != null) ...[
              const SizedBox(height: 12),
              OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
