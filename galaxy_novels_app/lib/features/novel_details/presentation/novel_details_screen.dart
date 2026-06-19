import 'package:flutter/material.dart';

import '../../../app/app_dependencies.dart';
import '../../../data/models/novel_details_data.dart';
import '../../../data/repositories/novel_repository.dart';
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

  void _openReader(String chapterUrl) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ReaderScreen(chapterUrl: chapterUrl),
      ),
    );
  }
}

class _NovelDetailsContent extends StatelessWidget {
  const _NovelDetailsContent({required this.result, required this.onRead});

  final NovelDetailsLoadResult result;
  final ValueChanged<String> onRead;

  @override
  Widget build(BuildContext context) {
    final details = result.details;
    final firstReadableUrl = result.chapters.isNotEmpty
        ? result.chapters.first.url
        : details.firstChapterUrl;

    return ListView(
      padding: const EdgeInsets.only(bottom: 28),
      children: [
        NovelDetailsHeader(details: details),
        if (firstReadableUrl.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: FilledButton.icon(
              onPressed: () => onRead(firstReadableUrl),
              icon: const Icon(Icons.menu_book_outlined),
              label: const Text('ابدأ القراءة'),
            ),
          ),
        if (details.summary.isNotEmpty)
          _SummarySection(summary: details.summary),
        if (details.genres.isNotEmpty) _GenresSection(genres: details.genres),
        _ChaptersSection(result: result, onRead: onRead),
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(title: 'عن الرواية'),
          const SizedBox(height: 10),
          Text(
            widget.summary,
            maxLines: isLong && !_expanded ? 5 : null,
            overflow: isLong && !_expanded ? TextOverflow.ellipsis : null,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.65,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.84),
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
    );
  }
}

class _GenresSection extends StatelessWidget {
  const _GenresSection({required this.genres});

  final List<NovelGenre> genres;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 22),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final genre in genres)
            Chip(
              label: Text(genre.name),
              side: BorderSide(color: Theme.of(context).dividerColor),
            ),
        ],
      ),
    );
  }
}

class _ChaptersSection extends StatelessWidget {
  const _ChaptersSection({required this.result, required this.onRead});

  final NovelDetailsLoadResult result;
  final ValueChanged<String> onRead;

  @override
  Widget build(BuildContext context) {
    final chapters = result.chapters;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: _SectionTitle(
            title: chapters.isEmpty ? 'الفصول' : 'الفصول (${chapters.length})',
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
                if (chapter.url.isNotEmpty) {
                  onRead(chapter.url);
                }
              },
            ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          width: 4,
          height: 28,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.dividerColor),
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
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
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
