import 'package:flutter/material.dart';

import '../../../app/app_dependencies.dart';
import '../../../app/app_theme.dart';
import '../../../data/models/reading_progress.dart';
import '../../../data/repositories/reading_history_repository.dart';
import '../../../shared/widgets/novel_cover.dart';
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

        return _HistoryList(items: items, onOpenReader: _openReader);
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
          coverUrl: progress.coverUrl,
        ),
      ),
    );
  }
}

class _HistoryList extends StatelessWidget {
  const _HistoryList({required this.items, required this.onOpenReader});

  final List<ReadingProgress> items;
  final ValueChanged<ReadingProgress> onOpenReader;

  @override
  Widget build(BuildContext context) {
    final previousCount = items.length - 1;
    final itemCount = previousCount > 0 ? previousCount + 3 : 2;

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index == 0) {
          return const SectionTitle(
            title: 'متابعة القراءة',
            leadingIcon: Icons.playlist_play_rounded,
          );
        }
        if (index == 1) {
          return _ContinueReadingPanel(
            progress: items.first,
            onTap: () => onOpenReader(items.first),
          );
        }
        if (index == 2) {
          return _HistorySubheading(count: previousCount);
        }

        final progress = items[index - 2];
        return _ReadingProgressRow(
          progress: progress,
          onTap: () => onOpenReader(progress),
        );
      },
    );
  }
}

class _ContinueReadingPanel extends StatelessWidget {
  const _ContinueReadingPanel({required this.progress, required this.onTap});

  final ReadingProgress progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: tokens.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: tokens.primary.withValues(alpha: 0.28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.16),
                blurRadius: 14,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    NovelCover(
                      title: progress.displayNovelTitle,
                      imageUrl: progress.coverUrl,
                      width: 76,
                      height: 112,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _HistoryTextBlock(
                        progress: progress,
                        titleStyle: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          height: 1.35,
                        ),
                        showDatePrefix: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _ProgressLine(progress: progress),
                const SizedBox(height: 12),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: _ActionPill(
                    label: 'تابع القراءة',
                    icon: Icons.menu_book_rounded,
                    foreground: theme.colorScheme.onPrimary,
                    background: tokens.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HistorySubheading extends StatelessWidget {
  const _HistorySubheading({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Row(
        children: [
          Text(
            'قراءات سابقة',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 10),
          _ActionPill(
            label: '$count محفوظة',
            icon: Icons.history_rounded,
            foreground: tokens.textSecondary,
            background: tokens.surfaceRaised,
          ),
        ],
      ),
    );
  }
}

class _ReadingProgressRow extends StatelessWidget {
  const _ReadingProgressRow({required this.progress, required this.onTap});

  final ReadingProgress progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: tokens.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: tokens.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NovelCover.list(
                  title: progress.displayNovelTitle,
                  imageUrl: progress.coverUrl,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _HistoryTextBlock(
                        progress: progress,
                        titleStyle: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          height: 1.35,
                        ),
                        showDatePrefix: false,
                      ),
                      const SizedBox(height: 12),
                      _ProgressLine(progress: progress),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_left_rounded,
                  color: tokens.textSecondary,
                  size: 26,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HistoryTextBlock extends StatelessWidget {
  const _HistoryTextBlock({
    required this.progress,
    required this.titleStyle,
    required this.showDatePrefix,
  });

  final ReadingProgress progress;
  final TextStyle? titleStyle;
  final bool showDatePrefix;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _ActionPill(
              label: showDatePrefix ? 'الأحدث' : _dateLabel(progress.updatedAt),
              icon: Icons.schedule_rounded,
              foreground: tokens.textSecondary,
              background: tokens.surfaceRaised,
            ),
            if (_isVipProgress(progress))
              _ActionPill(
                label: 'VIP',
                icon: Icons.workspace_premium_rounded,
                foreground: tokens.accent,
                background: tokens.accent.withValues(alpha: 0.12),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          progress.displayNovelTitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: titleStyle,
        ),
        const SizedBox(height: 8),
        Text(
          progress.displayChapterTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelLarge?.copyWith(
            color: tokens.textSecondary,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (showDatePrefix) ...[
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
      ],
    );
  }
}

class _ProgressLine extends StatelessWidget {
  const _ProgressLine({required this.progress});

  final ReadingProgress progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;
    final value = progress.completionFraction;
    final percent = progress.completionPercent;
    final progressLabel = percent == null ? 'موضع محفوظ' : '$percent%';

    return Row(
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
    );
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({
    required this.label,
    required this.icon,
    required this.foreground,
    required this.background,
  });

  final String label;
  final IconData icon;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: foreground, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
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

bool _isVipProgress(ReadingProgress progress) {
  final api = progress.contentApi.toLowerCase();
  return api.contains('/vip/') || api.contains('vip/chapters');
}
