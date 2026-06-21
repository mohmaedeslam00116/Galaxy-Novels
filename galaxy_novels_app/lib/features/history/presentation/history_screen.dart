import 'package:flutter/material.dart';

import '../../../app/app_dependencies.dart';
import '../../../app/app_theme.dart';
import '../../../data/models/reading_progress.dart';
import '../../../data/repositories/reading_history_repository.dart';
import '../../../shared/widgets/section_title.dart';
import '../../reader/presentation/reader_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  ReadingHistoryRepository? _repository;
  Future<List<ReadingProgress>>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final repository = AppDependencies.of(context).readingHistoryRepository;
    if (_repository != repository) {
      _repository?.removeListener(_refresh);
      _repository = repository;
      _repository?.addListener(_refresh);
      _future = repository.load();
    }
  }

  @override
  void dispose() {
    _repository?.removeListener(_refresh);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ReadingProgress>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const _HistoryMessage(title: 'تعذر تحميل سجل القراءة');
        }

        final items = snapshot.data ?? const [];
        if (items.isEmpty) {
          return const _HistoryMessage(title: 'لا يوجد سجل قراءة بعد');
        }

        return ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            const SectionTitle(
              title: 'متابعة القراءة',
              leadingIcon: Icons.playlist_play_rounded,
            ),
            const _ReadingMemoryNote(),
            for (final item in items)
              _ReadingProgressCard(
                progress: item,
                onTap: () => _openReader(item),
              ),
          ],
        );
      },
    );
  }

  void _refresh() {
    final repository = _repository;
    if (repository == null || !mounted) {
      return;
    }

    setState(() {
      _future = repository.load();
    });
  }

  void _openReader(ReadingProgress progress) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ReaderScreen(
          contentApi: progress.contentApi,
          chapterTitle: progress.displayChapterTitle,
          novelTitle: progress.displayNovelTitle,
        ),
      ),
    );
  }
}

class _ReadingMemoryNote extends StatelessWidget {
  const _ReadingMemoryNote();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tokens.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: tokens.border),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Text(
            'كل فصل تتركه هنا ينتظرك بهدوء.',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(
              color: tokens.textSecondary,
              fontWeight: FontWeight.w800,
              height: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _ReadingProgressCard extends StatelessWidget {
  const _ReadingProgressCard({required this.progress, required this.onTap});

  final ReadingProgress progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;
    final value = progress.completionFraction;
    final percent = progress.completionPercent;
    final progressLabel = percent == null ? 'موضع محفوظ' : '$percent%';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: tokens.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: tokens.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: tokens.surfaceRaised,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: tokens.primary.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Icon(
                        Icons.play_arrow_rounded,
                        color: tokens.primary,
                        size: 34,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            progress.displayNovelTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: tokens.surfaceRaised,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              progress.displayChapterTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'آخر قراءة: ${_dateLabel(progress.updatedAt)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: tokens.textSecondary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      progressLabel,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: tokens.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: value ?? 0,
                          minHeight: 7,
                          backgroundColor: tokens.surfaceRaised,
                          color: tokens.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HistoryMessage extends StatelessWidget {
  const _HistoryMessage({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

String _dateLabel(DateTime date) {
  final local = date.toLocal();
  return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
}
