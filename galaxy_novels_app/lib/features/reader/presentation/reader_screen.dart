import 'package:flutter/material.dart';

import '../../../app/app_dependencies.dart';
import '../../../data/models/reader_content_data.dart';
import '../../../data/repositories/reader_repository.dart';
import '../data/chapter_html_parser.dart';

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({required this.contentApi, this.chapterTitle, super.key});

  final String contentApi;
  final String? chapterTitle;

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  late String _contentApi;
  String? _chapterTitle;
  Future<ReaderChapterContent>? _future;
  ReaderRepository? _repository;

  @override
  void initState() {
    super.initState();
    _contentApi = widget.contentApi;
    _chapterTitle = widget.chapterTitle;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final repository = AppDependencies.of(context).readerRepository;
    if (_repository != repository) {
      _repository = repository;
      _future = repository.loadChapter(_contentApi);
    }
  }

  @override
  void didUpdateWidget(covariant ReaderScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.contentApi != oldWidget.contentApi ||
        widget.chapterTitle != oldWidget.chapterTitle) {
      _contentApi = widget.contentApi;
      _chapterTitle = widget.chapterTitle;
      final repository = _repository;
      if (repository != null) {
        _future = repository.loadChapter(_contentApi);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_chapterTitle ?? 'القارئ')),
      body: FutureBuilder<ReaderChapterContent>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const _ReaderLoadingView();
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return _ReaderErrorView(
              message: 'تعذر تحميل الفصل',
              details: snapshot.error?.toString(),
              onRetry: _retry,
            );
          }

          return _NativeReaderContent(
            content: snapshot.data!,
            onOpenChapter: _openChapter,
          );
        },
      ),
    );
  }

  void _retry() {
    final repository = AppDependencies.of(context).readerRepository;
    setState(() {
      _future = repository.loadChapter(_contentApi);
    });
  }

  void _openChapter(String contentApi, String title) {
    if (contentApi.isEmpty) {
      return;
    }

    final repository = AppDependencies.of(context).readerRepository;
    setState(() {
      _contentApi = contentApi;
      _chapterTitle = title;
      _future = repository.loadChapter(contentApi);
    });
  }
}

class _NativeReaderContent extends StatefulWidget {
  const _NativeReaderContent({
    required this.content,
    required this.onOpenChapter,
  });

  final ReaderChapterContent content;
  final void Function(String contentApi, String title) onOpenChapter;

  @override
  State<_NativeReaderContent> createState() => _NativeReaderContentState();
}

class _NativeReaderContentState extends State<_NativeReaderContent> {
  bool _controlsVisible = false;

  @override
  void didUpdateWidget(covariant _NativeReaderContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.content.id != widget.content.id) {
      _controlsVisible = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = widget.content;
    final blocks = parseChapterHtml(content.contentHtml);
    final hasPrevious = content.navigation.previousApi.isNotEmpty;
    final hasNext = content.navigation.nextApi.isNotEmpty;

    return Stack(
      children: [
        GestureDetector(
          key: const ValueKey('reader-content-tap-area'),
          behavior: HitTestBehavior.opaque,
          onTap: _toggleControls,
          child: ListView(
            key: ValueKey(content.id),
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
            children: [
              if (content.effectiveTitle.isNotEmpty) ...[
                Text(
                  content.effectiveTitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 18),
              ],
              for (final block in blocks)
                Padding(
                  padding: EdgeInsets.only(
                    bottom: block.type == ChapterTextBlockType.heading
                        ? 14
                        : 16,
                  ),
                  child: Text(
                    block.text,
                    textAlign: TextAlign.start,
                    style: block.type == ChapterTextBlockType.heading
                        ? theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            height: 1.55,
                          )
                        : theme.textTheme.titleMedium?.copyWith(
                            height: 2.05,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.92,
                            ),
                          ),
                  ),
                ),
            ],
          ),
        ),
        if (hasPrevious || hasNext)
          PositionedDirectional(
            start: 16,
            end: 16,
            bottom: 16,
            child: SafeArea(
              top: false,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  final offset = Tween<Offset>(
                    begin: const Offset(0, 0.18),
                    end: Offset.zero,
                  ).animate(animation);

                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(position: offset, child: child),
                  );
                },
                child: _controlsVisible
                    ? _ReaderFloatingControls(
                        key: const ValueKey('reader-controls-visible'),
                        hasPrevious: hasPrevious,
                        hasNext: hasNext,
                        onPrevious: () => widget.onOpenChapter(
                          content.navigation.previousApi,
                          'الفصل السابق',
                        ),
                        onNext: () => widget.onOpenChapter(
                          content.navigation.nextApi,
                          'الفصل التالي',
                        ),
                      )
                    : const SizedBox.shrink(
                        key: ValueKey('reader-controls-hidden'),
                      ),
              ),
            ),
          ),
      ],
    );
  }

  void _toggleControls() {
    setState(() {
      _controlsVisible = !_controlsVisible;
    });
  }
}

class _ReaderFloatingControls extends StatelessWidget {
  const _ReaderFloatingControls({
    required this.hasPrevious,
    required this.hasNext,
    required this.onPrevious,
    required this.onNext,
    super.key,
  });

  final bool hasPrevious;
  final bool hasNext;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.72),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: hasPrevious ? onPrevious : null,
                icon: const Icon(Icons.chevron_right),
                label: const Text('السابق'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: hasNext ? onNext : null,
                icon: const Icon(Icons.chevron_left),
                label: const Text('التالي'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReaderLoadingView extends StatelessWidget {
  const _ReaderLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 36,
        height: 36,
        child: CircularProgressIndicator(strokeWidth: 3),
      ),
    );
  }
}

class _ReaderErrorView extends StatelessWidget {
  const _ReaderErrorView({required this.message, this.details, this.onRetry});

  final String message;
  final String? details;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.menu_book_outlined,
              color: theme.colorScheme.primary,
              size: 40,
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            if (details != null && details!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                details!,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
