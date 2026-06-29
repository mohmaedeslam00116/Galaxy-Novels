import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';
import 'ranking_formatters.dart';

class RankingsHeader extends StatelessWidget {
  const RankingsHeader({
    required this.periodLabel,
    required this.novelsCount,
    required this.totalViews,
    super.key,
  });

  final String periodLabel;
  final int novelsCount;
  final int totalViews;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tokens.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: tokens.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 36,
                    decoration: BoxDecoration(
                      color: tokens.accent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'إحصاء الروايات',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  _PeriodChip(label: periodLabel),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'ترتيب سريع للروايات الأعلى حضورًا داخل المجرة.',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: tokens.textSecondary,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _HeaderMetric(
                      icon: Icons.menu_book_outlined,
                      label: 'رواية',
                      value: novelsCount.toString(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _HeaderMetric(
                      icon: Icons.visibility_outlined,
                      label: 'مشاهدة',
                      value: compactRankingNumber(totalViews),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  const _PeriodChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;

    return Container(
      constraints: const BoxConstraints(minHeight: 34),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: tokens.surfaceRaised,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tokens.border),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.labelMedium?.copyWith(
          color: tokens.primary,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _HeaderMetric extends StatelessWidget {
  const _HeaderMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.surfaceRaised,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tokens.border.withValues(alpha: 0.78)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: tokens.accent, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: tokens.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                maxLines: 1,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
