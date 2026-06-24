import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';
import '../../domain/public_comment.dart';

class CommentItem extends StatelessWidget {
  const CommentItem({required this.comment, super.key});

  final PublicComment comment;

  @override
  Widget build(BuildContext context) {
    final tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: tokens.border)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _CommentBody(comment: comment),
              if (comment.replies.isNotEmpty) ...[
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 20),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: BorderDirectional(
                        start: BorderSide(color: tokens.border, width: 2),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(start: 12),
                      child: Column(
                        children: [
                          for (
                            var index = 0;
                            index < comment.replies.length;
                            index++
                          ) ...[
                            _CommentBody(
                              comment: comment.replies[index],
                              compact: true,
                            ),
                            if (index < comment.replies.length - 1)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                child: Divider(height: 1, color: tokens.border),
                              ),
                          ],
                        ],
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

class _CommentBody extends StatefulWidget {
  const _CommentBody({required this.comment, this.compact = false});

  final PublicComment comment;
  final bool compact;

  @override
  State<_CommentBody> createState() => _CommentBodyState();
}

class _CommentBodyState extends State<_CommentBody> {
  bool _spoilerRevealed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;
    final comment = widget.comment;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CommentAvatar(
              name: comment.authorName,
              imageUrl: comment.avatarUrl,
              size: widget.compact ? 34 : 40,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    comment.authorName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: tokens.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (comment.authorRank.isNotEmpty)
                        Text(
                          comment.authorRank,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: tokens.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      if (comment.createdLabel.isNotEmpty)
                        Text(
                          comment.createdLabel,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: tokens.textSecondary,
                          ),
                        ),
                      if (comment.isPinned) _PinnedLabel(tokens: tokens),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        if (comment.replyToName.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            'ردًا على ${comment.replyToName}',
            style: theme.textTheme.labelMedium?.copyWith(
              color: tokens.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
        const SizedBox(height: 12),
        if (comment.isSpoiler && !_spoilerRevealed)
          Semantics(
            button: true,
            label: 'إظهار المحتوى المحروق',
            child: InkWell(
              key: ValueKey('comment-spoiler-${comment.id}'),
              borderRadius: BorderRadius.circular(8),
              onTap: () => setState(() => _spoilerRevealed = true),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: tokens.surfaceSoft,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: tokens.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.visibility_off_outlined,
                        size: 18,
                        color: tokens.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'إظهار المحتوى المحروق',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: tokens.textSecondary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
        else
          Text(
            comment.content,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: tokens.textPrimary,
              height: 1.7,
            ),
          ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 14,
          runSpacing: 6,
          children: [
            _CommentMetric(
              icon: Icons.thumb_up_alt_outlined,
              value: comment.likeCount,
              semanticLabel: 'إعجاب',
            ),
            _CommentMetric(
              icon: Icons.thumb_down_alt_outlined,
              value: comment.dislikeCount,
              semanticLabel: 'عدم إعجاب',
            ),
            if (comment.repliesCount > 0)
              _CommentMetric(
                icon: Icons.forum_outlined,
                value: comment.repliesCount,
                semanticLabel: 'رد',
              ),
          ],
        ),
      ],
    );
  }
}

class _CommentAvatar extends StatelessWidget {
  const _CommentAvatar({
    required this.name,
    required this.imageUrl,
    required this.size,
  });

  final String name;
  final String imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;
    final fallback = DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.surfaceRaised,
        shape: BoxShape.circle,
        border: Border.all(color: tokens.border),
      ),
      child: Center(
        child: Text(
          name.isEmpty ? '؟' : name.substring(0, 1),
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: tokens.primary,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );

    return SizedBox.square(
      dimension: size,
      child: imageUrl.isEmpty
          ? fallback
          : ClipOval(
              child: Image.network(
                imageUrl,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => fallback,
              ),
            ),
    );
  }
}

class _PinnedLabel extends StatelessWidget {
  const _PinnedLabel({required this.tokens});

  final AppThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.gold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: tokens.gold.withValues(alpha: 0.38)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        child: Text(
          'مثبّت',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: tokens.gold,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _CommentMetric extends StatelessWidget {
  const _CommentMetric({
    required this.icon,
    required this.value,
    required this.semanticLabel,
  });

  final IconData icon;
  final int value;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;

    return Semantics(
      label: '$semanticLabel: $value',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: tokens.textSecondary),
            const SizedBox(width: 4),
            Text(
              '$value',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: tokens.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
