import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';
import '../../../../data/models/novel_details_data.dart';

class NovelChapterTile extends StatelessWidget {
  const NovelChapterTile({
    required this.chapter,
    required this.onTap,
    super.key,
  });

  final NovelChapter chapter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;
    final number = chapter.number.isNotEmpty
        ? chapter.number
        : '${chapter.position}';
    final subtitle = chapter.displayTitle.isNotEmpty
        ? chapter.displayTitle
        : chapter.dateLabel;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: tokens.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: tokens.border),
          ),
          child: SizedBox(
            height: 74,
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 10),
                  child: Container(
                    width: 46,
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: tokens.surfaceRaised,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: tokens.accent.withValues(alpha: 0.28),
                      ),
                    ),
                    child: Text(
                      number,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: tokens.accent,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          chapter.label.isNotEmpty ? chapter.label : 'فصل',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if (subtitle.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: tokens.textSecondary,
                              height: 1.2,
                            ),
                          ),
                        ],
                        if (chapter.dateLabel.isNotEmpty &&
                            chapter.displayTitle.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            chapter.dateLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: tokens.textSecondary.withValues(
                                alpha: 0.78,
                              ),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_left_rounded,
                  size: 24,
                  color: tokens.accent,
                ),
                const SizedBox(width: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
