import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../shared/widgets/section_title.dart';
import '../../account/application/auth_repository.dart';
import '../application/comments_controller.dart';
import '../domain/comment_interaction.dart';
import '../domain/comment_target.dart';
import '../domain/public_comment.dart';
import 'widgets/comment_composer.dart';
import 'widgets/comment_item.dart';
import 'widgets/comments_sort_menu.dart';
import 'widgets/comments_states.dart';

class CommentsSliverSection extends StatefulWidget {
  const CommentsSliverSection({
    required this.controller,
    this.authRepository,
    this.showTitle = true,
    super.key,
  });

  final CommentsController controller;
  final AuthRepository? authRepository;
  final bool showTitle;

  @override
  State<CommentsSliverSection> createState() => _CommentsSliverSectionState();
}

class _CommentsSliverSectionState extends State<CommentsSliverSection> {
  PublicComment? _replyTarget;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<CommentsState>(
      valueListenable: widget.controller,
      builder: (context, state, _) {
        return SliverMainAxisGroup(
          slivers: [
            if (widget.showTitle)
              const SliverToBoxAdapter(
                child: SectionTitle(
                  title: 'التعليقات',
                  leadingIcon: Icons.forum_outlined,
                ),
              ),
            SliverToBoxAdapter(
              child: _CommentsToolbar(
                state: state,
                onSortChanged: (sort) =>
                    unawaited(widget.controller.changeSort(sort)),
              ),
            ),
            SliverToBoxAdapter(
              child: _TargetReactionsStrip(
                state: state,
                onSelected: (reaction) {
                  final next = state.myReaction == reaction ? null : reaction;
                  unawaited(widget.controller.reactToTarget(next));
                },
              ),
            ),
            SliverToBoxAdapter(
              child: CommentComposer(
                controller: widget.controller,
                authRepository: widget.authRepository,
                replyTarget: _replyTarget,
                onCancelReply: () => setState(() => _replyTarget = null),
                onSubmitted: () => setState(() => _replyTarget = null),
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
            onRetry: () => unawaited(widget.controller.retry()),
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
          (context, index) => CommentItem(
            comment: state.comments[index],
            onReply: (comment) => setState(() => _replyTarget = comment),
            onVote: (comment, vote) => unawaited(
              widget.controller.voteComment(commentId: comment.id, vote: vote),
            ),
          ),
          childCount: state.comments.length,
          addAutomaticKeepAlives: false,
        ),
      ),
      SliverToBoxAdapter(
        child: _CommentsFooter(state: state, controller: widget.controller),
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

class _TargetReactionsStrip extends StatelessWidget {
  const _TargetReactionsStrip({required this.state, required this.onSelected});

  final CommentsState state;
  final ValueChanged<CommentReaction> onSelected;

  @override
  Widget build(BuildContext context) {
    if (state.status != CommentsStatus.ready) {
      return const SizedBox.shrink();
    }
    final tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;
    final error = state.interactionErrorMessage;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final reaction in CommentReaction.values) ...[
                  _ReactionButton(
                    reaction: reaction,
                    count: state.reactions[reaction] ?? 0,
                    selected: state.myReaction == reaction,
                    enabled: !state.isInteracting,
                    onPressed: () => onSelected(reaction),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: tokens.danger,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReactionButton extends StatelessWidget {
  const _ReactionButton({
    required this.reaction,
    required this.count,
    required this.selected,
    required this.enabled,
    required this.onPressed,
  });

  final CommentReaction reaction;
  final int count;
  final bool selected;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;
    final foreground = selected ? tokens.primary : tokens.textSecondary;
    final background = selected ? tokens.primary.withValues(alpha: 0.12) : null;

    return Semantics(
      button: true,
      selected: selected,
      label: '${reaction.label}: $count',
      child: InkWell(
        key: ValueKey('comment-reaction-${reaction.apiValue}'),
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(8),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? tokens.primary : tokens.border,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            child: Text(
              '${reaction.label} $count',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
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
