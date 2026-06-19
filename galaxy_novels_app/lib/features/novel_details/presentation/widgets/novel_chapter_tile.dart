import 'package:flutter/material.dart';

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

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.dividerColor),
          ),
          child: SizedBox(
            height: 86,
            child: Row(
              children: [
                SizedBox(
                  width: 58,
                  child: Text(
                    chapter.number.isNotEmpty
                        ? chapter.number
                        : '${chapter.position}',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
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
                        if (chapter.displayTitle.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            chapter.displayTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                        if (chapter.dateLabel.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            chapter.dateLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.58,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_left, size: 22),
                const SizedBox(width: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
