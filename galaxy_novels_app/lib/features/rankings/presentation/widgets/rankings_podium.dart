import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';
import '../../../../data/models/catalog_data.dart';
import '../../../../shared/widgets/novel_cover.dart';
import '../../../../shared/widgets/status_badge.dart';
import 'ranking_atoms.dart';
import 'ranking_formatters.dart';

class RankingsPodium extends StatelessWidget {
  const RankingsPodium({
    required this.novels,
    required this.onOpenNovel,
    super.key,
  });

  final List<CatalogNovel> novels;
  final ValueChanged<String> onOpenNovel;

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final viewportWidth = MediaQuery.sizeOf(context).width;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final useVerticalLayout = textScale >= 1.6 || viewportWidth < 300;
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: useVerticalLayout
                  ? _VerticalPodium(novels: novels, onOpenNovel: onOpenNovel)
                  : _HorizontalPodium(novels: novels, onOpenNovel: onOpenNovel),
            ),
          );
        },
      ),
    );
  }
}

class _HorizontalPodium extends StatelessWidget {
  const _HorizontalPodium({required this.novels, required this.onOpenNovel});

  final List<CatalogNovel> novels;
  final ValueChanged<String> onOpenNovel;

  @override
  Widget build(BuildContext context) {
    final tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;
    final ranks = const [
      2,
      1,
      3,
    ].where((rank) => rank <= novels.length).toList(growable: false);

    return DecoratedBox(
      key: const ValueKey('rankings-podium-horizontal'),
      decoration: BoxDecoration(
        color: tokens.surfaceRaised,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tokens.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var index = 0; index < ranks.length; index++) ...[
              if (index > 0) const SizedBox(width: 6),
              Expanded(
                child: _HorizontalPodiumItem(
                  novel: novels[ranks[index] - 1],
                  rank: ranks[index],
                  onOpenNovel: onOpenNovel,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HorizontalPodiumItem extends StatelessWidget {
  const _HorizontalPodiumItem({
    required this.novel,
    required this.rank,
    required this.onOpenNovel,
  });

  final CatalogNovel novel;
  final int rank;
  final ValueChanged<String> onOpenNovel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;
    final medalColor = rankingMedalColor(tokens, rank);
    final rating = rankingRatingLabel(novel);
    final onTap = novel.manifest.isEmpty
        ? null
        : () => onOpenNovel(novel.manifest);
    final featured = rank == 1;

    return Semantics(
      button: true,
      enabled: onTap != null,
      excludeSemantics: true,
      label: rankingSemanticLabel(novel, rank),
      onTap: onTap,
      child: Material(
        color: medalColor.withValues(alpha: 0.07),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: medalColor.withValues(alpha: 0.38)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ValueKey('ranking-top-pick-$rank'),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(7),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RankingRankBadge(rank: rank),
                const SizedBox(height: 6),
                NovelCover(
                  title: novel.title,
                  imageUrl: rankingCoverUrl(novel),
                  width: featured ? 80 : 72,
                  height: featured ? 116 : 104,
                ),
                const SizedBox(height: 6),
                Text(
                  novel.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: tokens.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                RankingInlineMetric(
                  icon: Icons.visibility_outlined,
                  value: '${compactRankingNumber(novel.views)} مشاهدة',
                ),
                if (rating != null) ...[
                  const SizedBox(height: 3),
                  RankingInlineMetric(
                    icon: Icons.star_rounded,
                    value: rating,
                    gold: true,
                  ),
                ],
                if (novel.statusLabel.trim().isNotEmpty) ...[
                  const SizedBox(height: 5),
                  StatusBadge(label: novel.statusLabel),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VerticalPodium extends StatelessWidget {
  const _VerticalPodium({required this.novels, required this.onOpenNovel});

  final List<CatalogNovel> novels;
  final ValueChanged<String> onOpenNovel;

  @override
  Widget build(BuildContext context) {
    final tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;

    return DecoratedBox(
      key: const ValueKey('rankings-podium-vertical'),
      decoration: BoxDecoration(
        color: tokens.surfaceRaised,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tokens.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Material(
          type: MaterialType.transparency,
          child: Column(
            children: [
              for (var index = 0; index < novels.length; index++) ...[
                if (index > 0)
                  Divider(
                    height: 1,
                    thickness: 1,
                    indent: 10,
                    endIndent: 10,
                    color: tokens.border.withValues(alpha: 0.72),
                  ),
                _VerticalPodiumItem(
                  novel: novels[index],
                  rank: index + 1,
                  onOpenNovel: onOpenNovel,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _VerticalPodiumItem extends StatelessWidget {
  const _VerticalPodiumItem({
    required this.novel,
    required this.rank,
    required this.onOpenNovel,
  });

  final CatalogNovel novel;
  final int rank;
  final ValueChanged<String> onOpenNovel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;
    final rating = rankingRatingLabel(novel);
    final onTap = novel.manifest.isEmpty
        ? null
        : () => onOpenNovel(novel.manifest);

    return Semantics(
      button: true,
      enabled: onTap != null,
      excludeSemantics: true,
      label: rankingSemanticLabel(novel, rank),
      onTap: onTap,
      child: InkWell(
        key: ValueKey('ranking-top-pick-$rank'),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 92),
          child: Padding(
            padding: const EdgeInsets.all(9),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    RankingRankBadge(rank: rank),
                    const SizedBox(width: 8),
                    NovelCover(
                      title: novel.title,
                      imageUrl: rankingCoverUrl(novel),
                      width: 68,
                      height: 98,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        novel.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: tokens.textPrimary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.chevron_left_rounded,
                      size: 20,
                      color: onTap == null
                          ? tokens.textSecondary.withValues(alpha: 0.5)
                          : tokens.textSecondary,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    RankingInlineMetric(
                      icon: Icons.visibility_outlined,
                      value: '${compactRankingNumber(novel.views)} مشاهدة',
                    ),
                    if (rating != null)
                      RankingInlineMetric(
                        icon: Icons.star_rounded,
                        value: rating,
                        gold: true,
                      ),
                    if (novel.statusLabel.trim().isNotEmpty)
                      StatusBadge(label: novel.statusLabel),
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
