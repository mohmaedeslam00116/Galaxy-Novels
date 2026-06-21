import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import 'novel_cover.dart';
import 'status_badge.dart';

class NovelPosterTile extends StatelessWidget {
  const NovelPosterTile({
    required this.title,
    required this.imageUrl,
    this.statusLabel = '',
    this.onTap,
    super.key,
  });

  static const double width = NovelCover.posterWidth;
  static const double titleGap = 8;
  static const double titleHeight = 38;
  static const double height = NovelCover.posterHeight + titleGap + titleHeight;

  final String title;
  final String imageUrl;
  final String statusLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: width,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                NovelCover.poster(title: title, imageUrl: imageUrl),
                if (statusLabel.isNotEmpty)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: StatusBadge(label: statusLabel),
                  ),
              ],
            ),
            const SizedBox(height: titleGap),
            SizedBox(
              height: titleHeight,
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FeaturedPosterTile extends StatelessWidget {
  const FeaturedPosterTile({
    required this.title,
    required this.imageUrl,
    this.statusLabel = '',
    this.onTap,
    super.key,
  });

  final String title;
  final String imageUrl;
  final String statusLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;

    return SizedBox(
      width: 304,
      height: 192,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: tokens.surfaceRaised,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: tokens.primary.withValues(alpha: 0.18)),
            boxShadow: [
              BoxShadow(
                color: tokens.primary.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (statusLabel.isNotEmpty)
                        StatusBadge(
                          label: statusLabel,
                          emphasis: StatusBadgeEmphasis.gold,
                        ),
                      const Spacer(),
                      Text(
                        'مختارة من المجرة',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: tokens.accent,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        title,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 10),
                child: NovelCover(
                  title: title,
                  imageUrl: imageUrl,
                  width: 104,
                  height: 156,
                  borderRadius: 8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
