import 'package:flutter/material.dart';

import '../../../../data/models/rankings_data.dart';
import '../../../../shared/widgets/section_title.dart';
import 'ranking_formatters.dart';
import 'ranking_list_row.dart';
import 'rankings_header.dart';
import 'top_rankings_strip.dart';

class RankingsContent extends StatelessWidget {
  const RankingsContent({
    required this.rankings,
    required this.onOpenNovel,
    super.key,
  });

  final RankingsData rankings;
  final ValueChanged<String> onOpenNovel;

  @override
  Widget build(BuildContext context) {
    final topNovels = rankings.items.take(3).toList(growable: false);
    final remainingNovels = rankings.items.skip(3).toList(growable: false);

    return CustomScrollView(
      key: const ValueKey('rankings-scroll-view'),
      slivers: [
        SliverToBoxAdapter(
          child: RankingsHeader(
            periodLabel: rankingPeriodLabel(rankings.period),
            novelsCount: rankings.items.length,
            totalViews: rankings.items.fold<int>(
              0,
              (sum, novel) => sum + novel.views,
            ),
          ),
        ),
        if (topNovels.isNotEmpty) ...[
          const SliverToBoxAdapter(
            child: SectionTitle(
              title: 'الأكثر شهرة',
              leadingIcon: Icons.workspace_premium_outlined,
            ),
          ),
          SliverToBoxAdapter(
            child: TopRankingsStrip(
              novels: topNovels,
              onOpenNovel: onOpenNovel,
            ),
          ),
        ],
        if (remainingNovels.isNotEmpty)
          const SliverToBoxAdapter(
            child: SectionTitle(
              title: 'باقي الترتيب',
              leadingIcon: Icons.format_list_numbered_rtl,
            ),
          ),
        SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final rank = index + topNovels.length + 1;
            final novel = remainingNovels[index];
            return RepaintBoundary(
              child: RankingListRow(
                key: ValueKey('ranking-list-row-$rank'),
                rank: rank,
                novel: novel,
                onTap: novel.manifest.isEmpty
                    ? null
                    : () => onOpenNovel(novel.manifest),
              ),
            );
          }, childCount: remainingNovels.length),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}
