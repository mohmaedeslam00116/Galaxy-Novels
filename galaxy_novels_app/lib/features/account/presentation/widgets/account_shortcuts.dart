import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';

class AccountShortcutGrid extends StatelessWidget {
  const AccountShortcutGrid({
    required this.onOpenFavorites,
    required this.onOpenHistory,
    required this.onOpenDownloads,
    required this.onOpenReaderSettings,
    super.key,
  });

  final VoidCallback? onOpenFavorites;
  final VoidCallback? onOpenHistory;
  final VoidCallback? onOpenDownloads;
  final VoidCallback? onOpenReaderSettings;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 8.0;
        final columns = constraints.maxWidth < 420 ? 2 : 4;
        final itemWidth =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;
        final shortcuts = [
          _ShortcutData(
            icon: Icons.bookmark_outline_rounded,
            title: 'المفضلة',
            subtitle: 'الروايات المحفوظة',
            onTap: onOpenFavorites,
          ),
          _ShortcutData(
            icon: Icons.history_rounded,
            title: 'السجل',
            subtitle: 'متابعة القراءة',
            onTap: onOpenHistory,
          ),
          _ShortcutData(
            icon: Icons.download_outlined,
            title: 'التنزيلات',
            subtitle: 'القراءة دون اتصال',
            onTap: onOpenDownloads,
          ),
          _ShortcutData(
            icon: Icons.tune_rounded,
            title: 'إعدادات القراءة',
            subtitle: 'الخط والثيم',
            onTap: onOpenReaderSettings,
          ),
        ];

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final shortcut in shortcuts)
              SizedBox(
                width: itemWidth,
                height: 88,
                child: _AccountShortcutTile(shortcut: shortcut),
              ),
          ],
        );
      },
    );
  }
}

class _ShortcutData {
  const _ShortcutData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
}

class _AccountShortcutTile extends StatelessWidget {
  const _AccountShortcutTile({required this.shortcut});

  final _ShortcutData shortcut;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;

    return Material(
      color: tokens.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: tokens.border),
      ),
      child: InkWell(
        onTap: shortcut.onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(shortcut.icon, color: tokens.primary, size: 22),
              const Spacer(),
              Text(
                shortcut.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: tokens.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                shortcut.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: tokens.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
