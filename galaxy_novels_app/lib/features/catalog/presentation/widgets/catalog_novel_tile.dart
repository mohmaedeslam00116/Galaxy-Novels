import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';
import '../../../../data/models/catalog_data.dart';
import '../../../../shared/widgets/novel_cover.dart';
import '../../../../shared/widgets/status_badge.dart';

class CatalogNovelTile extends StatelessWidget {
  const CatalogNovelTile({required this.novel, this.onTap, super.key});

  final CatalogNovel novel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;
    final imageUrl = novel.coverMedium.isNotEmpty
        ? novel.coverMedium
        : novel.coverThumbnail;

    return RepaintBoundary(
      child: Semantics(
        button: onTap != null,
        label: novel.title,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              color: tokens.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: tokens.border),
              boxShadow: [
                BoxShadow(
                  color: tokens.primary.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      NovelCover(
                        title: novel.title,
                        imageUrl: imageUrl,
                        width: double.infinity,
                        height: double.infinity,
                        borderRadius: 8,
                      ),
                      if (novel.statusLabel.isNotEmpty)
                        PositionedDirectional(
                          top: 7,
                          end: 7,
                          child: StatusBadge(label: novel.statusLabel),
                        ),
                    ],
                  ),
                ),
                _CatalogStatsBar(novel: novel),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
                  child: Text(
                    novel.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      height: 1.22,
                    ),
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

class _CatalogStatsBar extends StatelessWidget {
  const _CatalogStatsBar({required this.novel});

  final CatalogNovel novel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;

    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: tokens.surfaceRaised,
        border: Border(top: BorderSide(color: tokens.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TinyStat(
              icon: Icons.visibility_outlined,
              value: _compactNumber(novel.views),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _TinyStat(
              icon: Icons.menu_book_outlined,
              value: novel.chaptersCount > 0 ? '${novel.chaptersCount}' : '-',
            ),
          ),
        ],
      ),
    );
  }
}

class _TinyStat extends StatelessWidget {
  const _TinyStat({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;

    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          textDirection: TextDirection.ltr,
          children: [
            Icon(icon, size: 13, color: tokens.accent),
            const SizedBox(width: 4),
            Text(
              value,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.visible,
              style: theme.textTheme.labelSmall?.copyWith(
                color: tokens.textPrimary,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _compactNumber(int value) {
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(1)}M';
  }
  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(1)}K';
  }
  return value.toString();
}
