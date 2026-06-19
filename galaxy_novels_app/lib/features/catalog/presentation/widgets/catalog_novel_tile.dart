import 'package:flutter/material.dart';

import '../../../../app/app_dependencies.dart';
import '../../../../data/models/catalog_data.dart';

class CatalogNovelTile extends StatelessWidget {
  const CatalogNovelTile({required this.novel, this.onTap, super.key});

  final CatalogNovel novel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final meta = _buildMeta(novel);
    final genres = novel.genres.take(2).map((genre) => genre.name).join('، ');

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            SizedBox(
              width: 54,
              height: 76,
              child: _CatalogCover(
                title: novel.title,
                url: novel.coverThumbnail.isNotEmpty
                    ? novel.coverThumbnail
                    : novel.coverMedium,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    novel.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (genres.isNotEmpty)
                    Text(
                      genres,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  const SizedBox(height: 6),
                  Text(
                    meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CatalogCover extends StatelessWidget {
  const _CatalogCover({required this.title, required this.url});

  final String title;
  final String url;

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = _resolveImageUrl(context, url);

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: resolvedUrl == null
          ? _CoverFallback(title: title)
          : Image.network(
              resolvedUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _CoverFallback(title: title),
            ),
    );
  }
}

class _CoverFallback extends StatelessWidget {
  const _CoverFallback({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ColoredBox(
      color: theme.colorScheme.primary.withValues(alpha: 0.12),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Text(
            'غلاف',
            maxLines: 1,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

String _buildMeta(CatalogNovel novel) {
  final parts = <String>[
    if (novel.chaptersCount > 0) '${novel.chaptersCount} فصل',
    if (novel.statusLabel.isNotEmpty) novel.statusLabel,
    if (novel.updatedAt != null) _dateLabel(novel.updatedAt!),
  ];

  return parts.join(' • ');
}

String _dateLabel(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

String? _resolveImageUrl(BuildContext context, String url) {
  if (url.isEmpty) {
    return null;
  }

  try {
    return AppDependencies.of(context).config.resolve(url).toString();
  } on Object {
    return null;
  }
}
