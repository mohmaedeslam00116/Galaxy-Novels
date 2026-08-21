import 'package:flutter/material.dart';

import '../novel_details_visual_tokens.dart';

enum NovelDetailsSection { chapters, comments }

class NovelDetailsSectionTabs extends StatelessWidget {
  const NovelDetailsSectionTabs({
    required this.selected,
    required this.onSelected,
    required this.chaptersCount,
    this.commentsCount,
    super.key,
  });

  final NovelDetailsSection selected;
  final ValueChanged<NovelDetailsSection> onSelected;
  final int chaptersCount;
  final int? commentsCount;

  @override
  Widget build(BuildContext context) {
    final tokens = NovelDetailsVisualTokens.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: tokens.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: tokens.border.withValues(alpha: 0.64)),
        ),
        child: Row(
          children: [
            Expanded(
              child: _SectionTab(
                key: const ValueKey('novel-section-chapters'),
                label: 'الفصول',
                count: chaptersCount,
                selected: selected == NovelDetailsSection.chapters,
                onTap: () => onSelected(NovelDetailsSection.chapters),
              ),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: _SectionTab(
                key: const ValueKey('novel-section-comments'),
                label: 'التعليقات',
                count: commentsCount,
                selected: selected == NovelDetailsSection.comments,
                onTap: () => onSelected(NovelDetailsSection.comments),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTab extends StatelessWidget {
  const _SectionTab({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final int? count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = NovelDetailsVisualTokens.of(context);
    final foreground = selected ? tokens.onPrimary : tokens.textSecondary;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? tokens.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (count != null) ...[
                  const SizedBox(width: 7),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? tokens.onPrimary.withValues(alpha: 0.18)
                          : tokens.surfaceHigh,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$count',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
