import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';
import '../../domain/auth_session.dart';

class AccountReadingStats extends StatelessWidget {
  const AccountReadingStats({required this.user, super.key});

  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    final tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;
    final stats = _statsFor(user);

    return Semantics(
      container: true,
      label: 'نشاط القراءة',
      child: Material(
        key: const ValueKey('account-reading-stats'),
        color: tokens.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: tokens.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            for (var index = 0; index < stats.length; index++) ...[
              if (index > 0)
                Divider(
                  height: 1,
                  thickness: 1,
                  indent: 12,
                  endIndent: 12,
                  color: tokens.border.withValues(alpha: 0.72),
                ),
              _AccountStatRow(stat: stats[index]),
            ],
          ],
        ),
      ),
    );
  }
}

class _AccountStatRow extends StatelessWidget {
  const _AccountStatRow({required this.stat});

  final _AccountStatDefinition stat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;

    return Semantics(
      label: '${stat.label}: ${stat.value}',
      excludeSemantics: true,
      child: ConstrainedBox(
        key: ValueKey(stat.keyName),
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(stat.icon, size: 19, color: tokens.accent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  stat.label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: tokens.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  stat.value,
                  textAlign: TextAlign.end,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: tokens.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountStatDefinition {
  const _AccountStatDefinition({
    required this.keyName,
    required this.icon,
    required this.label,
    required this.value,
  });

  final String keyName;
  final IconData icon;
  final String label;
  final String value;
}

List<_AccountStatDefinition> _statsFor(AuthUser user) {
  return [
    _AccountStatDefinition(
      keyName: 'account-stat-total-xp',
      icon: Icons.bolt_rounded,
      label: 'نقاط XP',
      value: user.xp.total.toString(),
    ),
    _AccountStatDefinition(
      keyName: 'account-stat-today-xp',
      icon: Icons.today_outlined,
      label: 'XP اليوم',
      value: user.xp.today.toString(),
    ),
    _AccountStatDefinition(
      keyName: 'account-stat-chapters',
      icon: Icons.menu_book_outlined,
      label: 'الفصول المقروءة',
      value: user.xp.chaptersTotal.toString(),
    ),
    _AccountStatDefinition(
      keyName: 'account-stat-time',
      icon: Icons.schedule_rounded,
      label: 'وقت القراءة',
      value: _formatReadingTime(user.xp.secondsTotal),
    ),
  ];
}

String _formatReadingTime(int seconds) {
  if (seconds <= 0) return '0د';
  final hours = seconds ~/ 3600;
  final minutes = (seconds % 3600) ~/ 60;
  if (hours > 0 && minutes > 0) return '$hoursس $minutesد';
  if (hours > 0) return '$hoursس';
  return '${minutes == 0 ? 1 : minutes}د';
}
