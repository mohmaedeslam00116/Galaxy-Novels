import 'package:flutter/material.dart';

import '../../../../app/app_dependencies.dart';
import '../../../../data/models/novel_details_data.dart';

class NovelDetailsHeader extends StatelessWidget {
  const NovelDetailsHeader({required this.details, super.key});

  final NovelDetails details;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final meta = [
      if (details.author.isNotEmpty) 'المؤلف: ${details.author}',
      if (details.translator.isNotEmpty) 'المترجم: ${details.translator}',
      if (details.statusLabel.isNotEmpty) details.statusLabel,
    ].join(' • ');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        children: [
          SizedBox(
            width: 150,
            height: 224,
            child: _NovelCover(title: details.title, url: details.bestCover),
          ),
          const SizedBox(height: 16),
          Text(
            details.title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              height: 1.25,
            ),
          ),
          if (details.originalTitle.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              details.originalTitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
              ),
            ),
          ],
          if (meta.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              meta,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
          const SizedBox(height: 18),
          _StatsRow(details: details),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.details});

  final NovelDetails details;

  @override
  Widget build(BuildContext context) {
    final stats = <_StatData>[
      _StatData(
        value: details.chaptersCount.toString(),
        label: 'فصل',
        icon: Icons.menu_book_outlined,
      ),
      if (details.views > 0)
        _StatData(
          value: details.views.toString(),
          label: 'مشاهدة',
          icon: Icons.visibility_outlined,
        ),
      if (details.ratingAverage > 0)
        _StatData(
          value: details.ratingAverage.toStringAsFixed(1),
          label: 'التقييم',
          icon: Icons.star_rounded,
        ),
    ];

    if (stats.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        for (var index = 0; index < stats.length; index += 1) ...[
          if (index > 0) const SizedBox(width: 8),
          Expanded(child: _StatItem(data: stats[index])),
        ],
      ],
    );
  }
}

class _StatData {
  const _StatData({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.data});

  final _StatData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(data.icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(height: 4),
          Text(
            data.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            data.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _NovelCover extends StatelessWidget {
  const _NovelCover({required this.title, required this.url});

  final String title;
  final String url;

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = _resolveImageUrl(context, url);

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
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

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.12),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Text(
            'غلاف',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w900,
              height: 1.25,
            ),
          ),
        ),
      ),
    );
  }
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
