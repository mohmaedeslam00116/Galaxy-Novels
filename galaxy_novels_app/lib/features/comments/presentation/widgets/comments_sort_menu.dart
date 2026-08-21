import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';
import '../../domain/comment_target.dart';

class CommentsSortMenu extends StatelessWidget {
  const CommentsSortMenu({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final CommentsSort value;
  final ValueChanged<CommentsSort> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;

    return Semantics(
      key: const ValueKey('comments-sort-menu'),
      container: true,
      label: 'ترتيب التعليقات: ${value.label}',
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        child: PopupMenuButton<CommentsSort>(
          tooltip: 'ترتيب التعليقات',
          initialValue: value,
          onSelected: onChanged,
          itemBuilder: (context) => [
            for (final sort in CommentsSort.values)
              PopupMenuItem(
                value: sort,
                child: Semantics(
                  key: ValueKey('comments-sort-option-${sort.apiValue}'),
                  selected: sort == value,
                  label: sort.label,
                  excludeSemantics: true,
                  child: Text(sort.label),
                ),
              ),
          ],
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: tokens.surfaceSoft,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: tokens.border),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.sort_rounded,
                    size: 18,
                    color: tokens.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    value.label,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: tokens.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.arrow_drop_down_rounded,
                    size: 18,
                    color: tokens.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
