import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';

class RankingRankBadge extends StatelessWidget {
  const RankingRankBadge({required this.rank, super.key});

  final int rank;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;
    final color = rankingMedalColor(tokens, rank);
    final isFirstPlace = rank == 1;

    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: isFirstPlace ? 46 : 42,
        minHeight: isFirstPlace ? 36 : 42,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.72)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Text(
            '#$rank',
            textAlign: TextAlign.center,
            style: theme.textTheme.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

Color rankingMedalColor(AppThemeTokens tokens, int rank) => switch (rank) {
  1 => tokens.gold,
  2 => tokens.textSecondary,
  3 => Color.lerp(tokens.warning, tokens.danger, 0.45)!,
  _ => tokens.accent,
};

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
