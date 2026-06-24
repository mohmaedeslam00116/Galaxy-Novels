import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../shared/widgets/section_title.dart';
import '../application/comments_controller.dart';
import '../domain/comment_target.dart';
import 'widgets/comment_item.dart';
import 'widgets/comments_sort_menu.dart';
import 'widgets/comments_states.dart';

class CommentsSliverSection extends StatelessWidget {
  const CommentsSliverSection({
    required this.controller,
    this.showTitle = true,
    super.key,
  });

  final CommentsController controller;
  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<CommentsState>(
      valueListenable: controller,
      builder: (context, state, _) {
        return SliverMainAxisGroup(
          slivers: [
            if (showTitle)
              const SliverToBoxAdapter(
                child: SectionTitle(
                  title: 'التعليقات',
                  leadingIcon: Icons.forum_outlined,
                ),
              ),
            SliverToBoxAdapter(
              child: _CommentsToolbar(
                state: state,
                onSortChanged: (sort) => unawaited(controller.changeSort(sort)),
              ),
            ),
            ..._contentSlivers(state),
          ],
        );
      },
    );
  }

  List<Widget> _contentSlivers(CommentsState state) {
    if (state.status == CommentsStatus.idle ||
        state.status == CommentsStatus.loading) {
      return const [SliverToBoxAdapter(child: CommentsLoadingState())];
    }
    if (state.status == CommentsStatus.failure) {
      return [
        SliverToBoxAdapter(
          child: CommentsErrorState(
            message: state.errorMessage ?? 'تعذر تحميل التعليقات الآن.',
            onRetry: () => unawaited(controller.retry()),
          ),
        ),
      ];
    }
    if (state.comments.isEmpty) {
      return const [SliverToBoxAdapter(child: CommentsEmptyState())];
    }

    return [
      SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => CommentItem(comment: state.comments[index]),
          childCount: state.comments.length,
          addAutomaticKeepAlives: false,
        ),
      ),
      SliverToBoxAdapter(
        child: _CommentsFooter(state: state, controller: controller),
      ),
    ];
  }
}

class _CommentsToolbar extends StatelessWidget {
  const _CommentsToolbar({required this.state, required this.onSortChanged});

  final CommentsState state;
  final ValueChanged<CommentsSort> onSortChanged;

  @override
  Widget build(BuildContext context) {
    final tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;
    final countLabel = state.status == CommentsStatus.ready
        ? '${state.totalComments} تعليق'
        : 'ترتيب التعليقات';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              countLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: tokens.textSecondary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          CommentsSortMenu(value: state.sort, onChanged: onSortChanged),
        ],
      ),
    );
  }
}

class _CommentsFooter extends StatelessWidget {
  const _CommentsFooter({required this.state, required this.controller});

  final CommentsState state;
  final CommentsController controller;

  @override
  Widget build(BuildContext context) {
    if (state.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: SizedBox.square(
            dimension: 24,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      );
    }
    final error = state.loadMoreErrorMessage;
    if (error != null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(error, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => unawaited(controller.loadMore()),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }
    if (!state.hasNextPage) {
      return const SizedBox(height: 20);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: OutlinedButton.icon(
        key: const ValueKey('comments-load-more'),
        onPressed: () => unawaited(controller.loadMore()),
        icon: const Icon(Icons.expand_more_rounded),
        label: const Text('عرض المزيد'),
      ),
    );
  }
}
