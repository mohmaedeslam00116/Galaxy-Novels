import 'package:flutter/material.dart';

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
