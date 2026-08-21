import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';
import '../../../../data/models/catalog_data.dart';
import '../../../../shared/widgets/novel_cover.dart';
import '../../../../shared/widgets/status_badge.dart';
import 'ranking_atoms.dart';
import 'ranking_formatters.dart';

enum RankingRowPosition { only, first, middle, last }

extension on RankingRowPosition {
  bool get isFirst =>
      this == RankingRowPosition.only || this == RankingRowPosition.first;

  bool get isLast =>
      this == RankingRowPosition.only || this == RankingRowPosition.last;
}

class RankingListRow extends StatelessWidget {
  const RankingListRow({
    required this.rank,
    required this.novel,
    required this.position,
    this.onTap,
    super.key,
  });

  final int rank;
  final CatalogNovel novel;
  final RankingRowPosition position;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: rankingSemanticLabel(novel, rank),
      button: true,
      enabled: onTap != null,
      onTap: onTap,
      excludeSemantics: true,
      child: _RankingRowSurface(
        novel: novel,
        rank: rank,
        position: position,
        onTap: onTap,
      ),
    );
  }
}

class _RankingRowSurface extends StatelessWidget {
  const _RankingRowSurface({
    required this.novel,
    required this.rank,
    required this.position,
    required this.onTap,
  });

  final CatalogNovel novel;
  final int rank;
  final RankingRowPosition position;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;
    final borderSide = BorderSide(color: tokens.border);
    final radius = BorderRadius.vertical(
      top: position.isFirst ? const Radius.circular(8) : Radius.zero,
      bottom: position.isLast ? const Radius.circular(8) : Radius.zero,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Ink(
          decoration: BoxDecoration(
            color: tokens.surface,
            borderRadius: radius,
            border: Border(
              top: borderSide,
              left: borderSide,
              right: borderSide,
              bottom: position.isLast ? borderSide : BorderSide.none,
            ),
          ),
          child: _RankingRowContent(novel: novel, rank: rank, onTap: onTap),
        ),
      ),
    );
  }
}

class _RankingRowContent extends StatelessWidget {
  const _RankingRowContent({
    required this.novel,
    required this.rank,
    required this.onTap,
  });

  final CatalogNovel novel;
  final int rank;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 82),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            RankingRankBadge(rank: rank),
            const SizedBox(width: 8),
            NovelCover(
              title: novel.title,
              imageUrl: rankingCoverUrl(novel),
              width: 46,
              height: 66,
            ),
            const SizedBox(width: 10),
            Expanded(child: _RankingRowDetails(novel: novel)),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_left_rounded,
                size: 22,
                color: tokens.textSecondary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RankingRowDetails extends StatelessWidget {
  const _RankingRowDetails({required this.novel});

  final CatalogNovel novel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          novel.title,
          style: theme.textTheme.titleSmall?.copyWith(
            color: tokens.textPrimary,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        _RankingRowMetrics(novel: novel),
      ],
    );
  }
}

class _RankingRowMetrics extends StatelessWidget {
  const _RankingRowMetrics({required this.novel});

  final CatalogNovel novel;

  @override
  Widget build(BuildContext context) {
    final tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;
    final rating = rankingRatingLabel(novel);

    return Wrap(
      spacing: 10,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _TableMetric(
          icon: Icons.visibility_outlined,
          value: '${compactRankingNumber(novel.views)} مشاهدة',
        ),
        if (rating != null)
          _TableMetric(
            icon: Icons.star_rounded,
            value: rating,
            color: tokens.gold,
          ),
        if (novel.statusLabel.trim().isNotEmpty)
          StatusBadge(label: novel.statusLabel),
      ],
    );
  }
}

class _TableMetric extends StatelessWidget {
  const _TableMetric({required this.icon, required this.value, this.color});

  final IconData icon;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;
    final metricColor = color ?? tokens.textSecondary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: metricColor),
        const SizedBox(width: 4),
        Text(
          value,
          style: theme.textTheme.labelSmall?.copyWith(
            color: metricColor,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
