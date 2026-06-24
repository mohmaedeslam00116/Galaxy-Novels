import 'package:flutter/material.dart';

import '../../../../app/app_dependencies.dart';
import '../../../../app/app_theme.dart';
import '../../../../data/models/novel_details_data.dart';
import '../../../../data/repositories/novel_repository.dart';
import '../../../../shared/widgets/section_title.dart';
import '../../../novel_engagement/application/novel_engagement_controller.dart';
import '../../../novel_engagement/presentation/novel_personal_state_section.dart';
import 'favorite_toggle_button.dart';
import 'novel_chapters_section.dart';
import 'novel_details_header.dart';

class NovelDetailsContent extends StatelessWidget {
  const NovelDetailsContent({
    required this.loadResult,
    required this.engagementState,
    required this.onRead,
    required this.onDownloadChapters,
    required this.onToggleFavorite,
    required this.onRate,
    required this.onSignIn,
    required this.onRetryEngagement,
    super.key,
  });

  final NovelDetailsLoadResult loadResult;
  final NovelEngagementState engagementState;
  final void Function(NovelChapter chapter, String novelTitle) onRead;
  final VoidCallback onDownloadChapters;
  final Future<void> Function() onToggleFavorite;
  final VoidCallback onRate;
  final VoidCallback onSignIn;
  final VoidCallback onRetryEngagement;

  @override
  Widget build(BuildContext context) {
    final details = loadResult.details;
    final firstReadableChapter = _firstReadableChapter(loadResult.chapters);
    final continuationChapter = _continuationChapter(
      loadResult.chapters,
      engagementState.userState?.lastRead.chapterId ?? 0,
    );
    final readChapter = continuationChapter ?? firstReadableChapter;

    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: NovelDetailsHeader(details: details)),
            SliverToBoxAdapter(
              child: NovelPersonalStateSection(
                state: engagementState,
                onRate: onRate,
                onSignIn: onSignIn,
                onRetry: onRetryEngagement,
              ),
            ),
            if (details.summary.isNotEmpty)
              SliverToBoxAdapter(
                child: _SummarySection(summary: details.summary),
              ),
            NovelChaptersSection(
              result: loadResult,
              onRead: onRead,
              onDownloadChapters: onDownloadChapters,
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 118)),
          ],
        ),
        PositionedDirectional(
          start: 0,
          end: 0,
          bottom: 0,
          child: _DetailsBottomBar(
            novelId: details.id,
            onToggleFavorite: onToggleFavorite,
            readLabel: continuationChapter == null
                ? 'ابدأ القراءة'
                : 'متابعة ${continuationChapter.label}',
            onRead: readChapter == null
                ? null
                : () => onRead(readChapter, details.title),
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
  const _DetailsBottomBar({
    required this.novelId,
    required this.onToggleFavorite,
    required this.readLabel,
    required this.onRead,
  });

  final int novelId;
  final Future<void> Function() onToggleFavorite;
  final String readLabel;
  final VoidCallback? onRead;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;
    final dependencies = AppDependencies.of(context);

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
              FavoriteToggleButton(
                novelId: novelId,
                authRepository: dependencies.authRepository,
                favoritesRepository: dependencies.favoritesRepository,
                onPressed: onToggleFavorite,
              ),
              if (onRead != null) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onRead,
                    icon: const Icon(Icons.menu_book_outlined),
                    label: Text(
                      readLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      textStyle: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

NovelChapter? _firstReadableChapter(List<NovelChapter> chapters) {
  for (final chapter in chapters) {
    if (chapter.effectiveContentApi.isNotEmpty) {
      return chapter;
    }
  }
  return null;
}

NovelChapter? _continuationChapter(List<NovelChapter> chapters, int chapterId) {
  if (chapterId <= 0) {
    return null;
  }
  for (final chapter in chapters) {
    if (chapter.id == chapterId && chapter.effectiveContentApi.isNotEmpty) {
      return chapter;
    }
  }
  return null;
}

class NovelDetailsSkeleton extends StatelessWidget {
  const NovelDetailsSkeleton({super.key});

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

class NovelDetailsMessage extends StatelessWidget {
  const NovelDetailsMessage({
    required this.title,
    this.actionLabel,
    this.onAction,
    super.key,
  });

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
