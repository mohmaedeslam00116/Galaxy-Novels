import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';
import '../../domain/readable_chapter.dart';

class ReadableChapterTile extends StatelessWidget {
  const ReadableChapterTile({
    required this.chapter,
    required this.onTap,
    this.trailingAction,
    super.key,
  });

  final ReadableChapter chapter;
  final VoidCallback onTap;
  final Widget? trailingAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;
    final number = chapter.number.isNotEmpty
        ? chapter.number
        : '${chapter.sortPosition}';
    final borderColor = chapter.isVip
        ? tokens.gold.withValues(alpha: 0.36)
        : tokens.border;
    final accentColor = chapter.isVip ? tokens.gold : tokens.accent;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Ink(
          height: 74,
          decoration: BoxDecoration(
            color: tokens.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 10),
                child: Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: chapter.isVip
                        ? tokens.gold.withValues(alpha: 0.10)
                        : tokens.surfaceRaised,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.28),
                    ),
                  ),
                  child: Text(
                    number,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: accentColor,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            chapter.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        if (chapter.isVip) ...[
                          const SizedBox(width: 8),
                          _VipBadge(color: tokens.gold),
                        ],
                      ],
                    ),
                    if (chapter.title.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        chapter.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: tokens.textSecondary,
                          height: 1.2,
                        ),
                      ),
                    ] else if (chapter.dateLabel.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        chapter.dateLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: tokens.textSecondary,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (trailingAction != null) ...[
                trailingAction!,
                const SizedBox(width: 4),
              ],
              Icon(Icons.chevron_left_rounded, size: 24, color: accentColor),
              const SizedBox(width: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _VipBadge extends StatelessWidget {
  const _VipBadge({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        child: Text(
          'VIP',
          style: theme.textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
