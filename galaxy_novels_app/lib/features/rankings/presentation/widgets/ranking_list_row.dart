import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';
import '../../../../data/models/catalog_data.dart';
import '../../../../shared/widgets/novel_cover.dart';
import '../../../../shared/widgets/status_badge.dart';
import 'ranking_atoms.dart';
import 'ranking_formatters.dart';

class RankingListRow extends StatelessWidget {
  const RankingListRow({
    required this.rank,
    required this.novel,
    this.onTap,
    super.key,
  });

  final int rank;
  final CatalogNovel novel;
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
                RankingRankBadge(rank: rank),
                const SizedBox(width: 10),
                NovelCover.list(
                  title: novel.title,
                  imageUrl: rankingCoverUrl(novel),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              novel.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          if (novel.statusLabel.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Flexible(
                              child: StatusBadge(label: novel.statusLabel),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        rankingSubtitle(novel),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: tokens.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 9),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          RankingInlineMetric(
                            icon: Icons.menu_book_outlined,
                            value: '${novel.chaptersCount} فصل',
                          ),
                          RankingInlineMetric(
                            icon: Icons.visibility_outlined,
                            value:
                                '${compactRankingNumber(novel.views)} مشاهدة',
                          ),
                          if (novel.ratingAverage > 0)
                            RankingInlineMetric(
                              icon: Icons.star_rounded,
                              value: novel.ratingAverage.toStringAsFixed(1),
                              gold: true,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_left, color: tokens.textSecondary, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
