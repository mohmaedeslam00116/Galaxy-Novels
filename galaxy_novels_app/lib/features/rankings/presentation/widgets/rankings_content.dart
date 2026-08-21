import 'package:flutter/material.dart';

import '../../../../data/models/rankings_data.dart';
import '../../../../shared/widgets/section_title.dart';
import '../../../ads/application/inline_native_ad_repository.dart';
import '../../../ads/presentation/inline_native_ad_slot.dart';
import 'ranking_formatters.dart';
import 'ranking_list_row.dart';
import 'rankings_header.dart';
import 'rankings_podium.dart';

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
          ),
        ),
        if (topNovels.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: RankingsPodium(novels: topNovels, onOpenNovel: onOpenNovel),
          ),
        ],
        const SliverToBoxAdapter(
          child: InlineNativeAdSlot(
            placement: InlineNativeAdPlacement.rankings,
          ),
        ),
        if (remainingNovels.isNotEmpty)
          const SliverToBoxAdapter(
            child: SectionTitle(
              title: 'باقي الترتيب',
              leadingIcon: Icons.format_list_numbered_rtl,
            ),
          ),
        if (remainingNovels.isNotEmpty)
          SliverPadding(
            key: const ValueKey('rankings-table'),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final rank = index + topNovels.length + 1;
                final novel = remainingNovels[index];
                return RepaintBoundary(
                  child: RankingListRow(
                    key: ValueKey('ranking-list-row-$rank'),
                    rank: rank,
                    novel: novel,
                    position: _rankingRowPosition(
                      index,
                      remainingNovels.length,
                    ),
                    onTap: novel.manifest.isEmpty
                        ? null
                        : () => onOpenNovel(novel.manifest),
                  ),
                );
              }, childCount: remainingNovels.length),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

RankingRowPosition _rankingRowPosition(int index, int rowCount) {
  if (rowCount == 1) return RankingRowPosition.only;
  if (index == 0) return RankingRowPosition.first;
  if (index == rowCount - 1) return RankingRowPosition.last;
  return RankingRowPosition.middle;
}
