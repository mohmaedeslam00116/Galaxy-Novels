import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';
import '../../../../shared/widgets/novel_cover.dart';
import '../../domain/favorite_item.dart';

class FavoriteNovelRow extends StatelessWidget {
  const FavoriteNovelRow({
    required this.item,
    required this.onOpen,
    required this.onRemove,
    super.key,
  });

  final FavoriteItem item;
  final VoidCallback onOpen;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;
    final dateLabel = _dateLabel(item.addedAt);

    return Semantics(
      container: true,
      explicitChildNodes: true,
      button: true,
      label: 'فتح تفاصيل ${item.title}',
      child: InkWell(
        excludeFromSemantics: true,
        onTap: onOpen,
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: tokens.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: tokens.border),
          ),
          child: Row(
            children: [
              NovelCover.list(
                title: item.title,
                imageUrl: item.cover,
                key: ValueKey('favorite-cover-${item.id}'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (dateLabel != null) ...[
                      const SizedBox(height: 7),
                      Text(
                        dateLabel,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: tokens.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 5,
                      children: [
                        Icon(
                          Icons.arrow_back_rounded,
                          size: 17,
                          color: tokens.accent,
                        ),
                        Text(
                          'عرض التفاصيل',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: tokens.accent,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Semantics(
                button: true,
                label: 'إزالة ${item.title} من المفضلة',
                child: ExcludeSemantics(
                  child: IconButton(
                    key: ValueKey('remove-favorite-${item.id}'),
                    tooltip: 'إزالة ${item.title} من المفضلة',
                    onPressed: onRemove,
                    icon: const Icon(Icons.bookmark_remove_outlined),
                    color: tokens.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String? _dateLabel(DateTime date) {
  if (date.millisecondsSinceEpoch == 0) {
    return null;
  }
  final local = date.toLocal();
  return 'أضيفت في ${local.day}/${local.month}/${local.year}';
}
