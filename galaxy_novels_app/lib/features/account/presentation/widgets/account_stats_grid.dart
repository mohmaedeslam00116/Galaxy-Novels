import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';
import '../../domain/auth_session.dart';

class ReadingStatsGrid extends StatelessWidget {
  const ReadingStatsGrid({required this.user, super.key});

  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 8.0;
        final columns = constraints.maxWidth < 420 ? 2 : 4;
        final itemWidth =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            SizedBox(
              width: itemWidth,
              height: 92,
              child: _AccountStat(
                icon: Icons.bolt_rounded,
                label: 'نقاط XP',
                value: user.xp.total.toString(),
              ),
            ),
            SizedBox(
              width: itemWidth,
              height: 92,
              child: _AccountStat(
                icon: Icons.today_outlined,
                label: 'XP اليوم',
                value: user.xp.today.toString(),
              ),
            ),
            SizedBox(
              width: itemWidth,
              height: 92,
              child: _AccountStat(
                icon: Icons.menu_book_outlined,
                label: 'فصول مقروءة',
                value: user.xp.chaptersTotal.toString(),
              ),
            ),
            SizedBox(
              width: itemWidth,
              height: 92,
              child: _AccountStat(
                icon: Icons.schedule_rounded,
                label: 'وقت القراءة',
                value: _formatReadingTime(user.xp.secondsTotal),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AccountStat extends StatelessWidget {
  const _AccountStat({
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
        border: Border.all(color: tokens.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: tokens.accent, size: 18),
            const SizedBox(height: 5),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  maxLines: 1,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: tokens.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: tokens.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatReadingTime(int seconds) {
  if (seconds <= 0) {
    return '0د';
  }

  final hours = seconds ~/ 3600;
  final minutes = (seconds % 3600) ~/ 60;
  if (hours > 0 && minutes > 0) {
    return '$hoursس $minutesد';
  }
  if (hours > 0) {
    return '$hoursس';
  }
  return '${minutes == 0 ? 1 : minutes}د';
}
