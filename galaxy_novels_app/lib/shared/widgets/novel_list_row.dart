import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import 'novel_cover.dart';
import 'status_badge.dart';

class NovelListRow extends StatelessWidget {
  const NovelListRow({
    required this.title,
    required this.subtitle,
    required this.meta,
    this.imageUrl = '',
    this.badgeLabel = '',
    this.leadingLabel,
    this.onTap,
    super.key,
  });

  final String title;
  final String subtitle;
  final String meta;
  final String imageUrl;
  final String badgeLabel;
  final String? leadingLabel;
  final VoidCallback? onTap;

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
              children: [
                if (leadingLabel != null)
                  _LeadingLabel(label: leadingLabel!)
                else
                  NovelCover.list(title: title, imageUrl: imageUrl),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          if (badgeLabel.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Flexible(child: StatusBadge(label: badgeLabel)),
                          ],
                        ],
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: tokens.textSecondary,
                          ),
                        ),
                      ],
                      if (meta.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          meta,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: tokens.primary,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ],
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

class _LeadingLabel extends StatelessWidget {
  const _LeadingLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;

    return Container(
      width: NovelCover.listWidth,
      height: NovelCover.listHeight,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tokens.surfaceRaised,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: tokens.border),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.labelMedium?.copyWith(
          color: tokens.primary,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
