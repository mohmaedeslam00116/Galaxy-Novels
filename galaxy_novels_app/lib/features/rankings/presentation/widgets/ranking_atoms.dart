import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';

class RankingRankBadge extends StatelessWidget {
  const RankingRankBadge({
    required this.rank,
    this.featured = false,
    super.key,
  });

  final int rank;
  final bool featured;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;
    final color = featured ? tokens.gold : tokens.accent;

    return Container(
      width: featured ? 46 : 42,
      height: featured ? 36 : 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.72)),
      ),
      child: Text(
        '#$rank',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.labelLarge?.copyWith(
          color: color,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class RankingInlineMetric extends StatelessWidget {
  const RankingInlineMetric({
    required this.icon,
    required this.value,
    this.gold = false,
    super.key,
  });

  final IconData icon;
  final String value;
  final bool gold;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;
    final color = gold ? tokens.gold : tokens.textSecondary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 15),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}
