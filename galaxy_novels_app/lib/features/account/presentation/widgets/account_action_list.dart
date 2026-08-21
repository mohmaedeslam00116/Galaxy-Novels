import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';

class AccountActionList extends StatelessWidget {
  const AccountActionList({
    required this.onOpenFavorites,
    required this.onOpenHistory,
    required this.onOpenReaderSettings,
    super.key,
  });

  final VoidCallback? onOpenFavorites;
  final VoidCallback? onOpenHistory;
  final VoidCallback? onOpenReaderSettings;

  @override
  Widget build(BuildContext context) {
    final tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;
    final actions = _actions();

    return Material(
      key: const ValueKey('account-action-list'),
      color: tokens.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: tokens.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var index = 0; index < actions.length; index++) ...[
            if (index > 0)
              Divider(
                height: 1,
                thickness: 1,
                indent: 12,
                endIndent: 12,
                color: tokens.border.withValues(alpha: 0.72),
              ),
            _AccountActionRow(action: actions[index]),
          ],
        ],
      ),
    );
  }

  List<_AccountAction> _actions() {
    return [
      _AccountAction(
        keyName: 'account-action-favorites',
        icon: Icons.bookmark_outline_rounded,
        title: 'المفضلة',
        subtitle: 'الروايات المحفوظة',
        onTap: onOpenFavorites,
      ),
      _AccountAction(
        keyName: 'account-action-history',
        icon: Icons.history_rounded,
        title: 'السجل',
        subtitle: 'متابعة القراءة',
        onTap: onOpenHistory,
      ),
      _AccountAction(
        keyName: 'account-action-settings',
        icon: Icons.settings_outlined,
        title: 'الإعدادات',
        subtitle: 'المظهر وإعدادات القراءة',
        onTap: onOpenReaderSettings,
      ),
    ];
  }
}

class _AccountActionRow extends StatelessWidget {
  const _AccountActionRow({required this.action});

  final _AccountAction action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;

    return Semantics(
      key: ValueKey(action.keyName),
      button: true,
      enabled: action.onTap != null,
      onTap: action.onTap,
      label: '${action.title}، ${action.subtitle}',
      excludeSemantics: true,
      child: InkWell(
        onTap: action.onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Row(
              children: [
                Icon(action.icon, size: 21, color: tokens.primary),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        action.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: tokens.textPrimary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        action.subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: tokens.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (action.onTap != null) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_left_rounded,
                    size: 21,
                    color: tokens.textSecondary,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AccountAction {
  const _AccountAction({
    required this.keyName,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String keyName;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
}
