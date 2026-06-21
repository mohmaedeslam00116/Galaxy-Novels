import 'package:flutter/material.dart';

import '../../../app/app_dependencies.dart';
import '../../../app/app_theme.dart';
import '../../../data/models/novel_details_data.dart';
import '../../../data/repositories/novel_repository.dart';
import '../../../shared/widgets/section_title.dart';
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final repository = AppDependencies.of(context).novelRepository;
    if (_repository != repository) {
      _repository = repository;
      _future = repository.loadNovel(widget.manifestPath);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل الرواية')),
      body: FutureBuilder<NovelDetailsLoadResult>(
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
          );
        },
      ),
    );
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
}

class _NovelDetailsContent extends StatelessWidget {
  const _NovelDetailsContent({required this.result, required this.onRead});

  final NovelDetailsLoadResult result;
  final void Function(NovelChapter chapter, String novelTitle) onRead;

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
            _ChaptersSection(result: result, onRead: onRead),
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
  const _ChaptersSection({required this.result, required this.onRead});

  final NovelDetailsLoadResult result;
  final void Function(NovelChapter chapter, String novelTitle) onRead;

  @override
  Widget build(BuildContext context) {
    final chapters = result.chapters;
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(
          title: 'آخر الفصول',
          leadingIcon: Icons.menu_book_outlined,
          action: chapters.isEmpty
              ? null
              : Text(
                  '${chapters.length} فصل',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: tokens.textSecondary,
                    fontWeight: FontWeight.w800,
                  ),
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
          for (final chapter in chapters)
            NovelChapterTile(
              chapter: chapter,
              onTap: () {
                if (chapter.effectiveContentApi.isNotEmpty) {
                  onRead(chapter, result.details.title);
                }
              },
            ),
      ],
    );
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
