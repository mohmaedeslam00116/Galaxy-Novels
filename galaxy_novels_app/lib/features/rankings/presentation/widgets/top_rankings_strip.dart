import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';
import '../../../../data/models/catalog_data.dart';
import '../../../../shared/widgets/novel_cover.dart';
import 'ranking_atoms.dart';
import 'ranking_formatters.dart';

class TopRankingsStrip extends StatelessWidget {
  const TopRankingsStrip({
    required this.novels,
    required this.onOpenNovel,
    super.key,
  });

  final List<CatalogNovel> novels;
  final ValueChanged<String> onOpenNovel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey('rankings-featured-top-three'),
      height: 254,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: novels.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final novel = novels[index];
          final rank = index + 1;
          return RepaintBoundary(
            child: _TopRankingTile(
              key: ValueKey('ranking-top-pick-$rank'),
              rank: rank,
              novel: novel,
              onTap: novel.manifest.isEmpty
                  ? null
                  : () => onOpenNovel(novel.manifest),
            ),
          );
        },
      ),
    );
  }
}

class _TopRankingTile extends StatelessWidget {
  const _TopRankingTile({
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
    final isWinner = rank == 1;

    return SizedBox(
      width: 172,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: tokens.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isWinner ? tokens.gold : tokens.border,
              width: isWinner ? 1.3 : 1,
            ),
            boxShadow: [
              if (isWinner)
                BoxShadow(
                  color: tokens.gold.withValues(alpha: 0.14),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Align(
                      alignment: Alignment.center,
                      child: NovelCover(
                        title: novel.title,
                        imageUrl: rankingCoverUrl(novel),
                        width: 106,
                        height: 150,
                      ),
                    ),
                    PositionedDirectional(
                      top: 0,
                      start: 0,
                      child: RankingRankBadge(rank: rank, featured: isWinner),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  novel.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    height: 1.25,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: RankingInlineMetric(
                        icon: Icons.visibility_outlined,
                        value: compactRankingNumber(novel.views),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: RankingInlineMetric(
                        icon: Icons.menu_book_outlined,
                        value: '${novel.chaptersCount} فصل',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
