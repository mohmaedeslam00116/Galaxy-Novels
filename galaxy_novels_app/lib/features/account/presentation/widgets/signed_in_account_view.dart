import 'package:flutter/material.dart';

import '../../domain/auth_session.dart';
import 'account_common_widgets.dart';
import 'account_hero_panel.dart';
import 'account_shortcuts.dart';
import 'account_stats_grid.dart';

class SignedInAccountView extends StatelessWidget {
  const SignedInAccountView({
    required this.user,
    required this.isSigningOut,
    required this.onLogout,
    this.noticeMessage,
    this.onRefreshProfile,
    this.onOpenFavorites,
    this.onOpenHistory,
    this.onOpenDownloads,
    this.onOpenReaderSettings,
    super.key,
  });

  final AuthUser user;
  final bool isSigningOut;
  final String? noticeMessage;
  final Future<void> Function() onLogout;
  final Future<void> Function()? onRefreshProfile;
  final VoidCallback? onOpenFavorites;
  final VoidCallback? onOpenHistory;
  final VoidCallback? onOpenDownloads;
  final VoidCallback? onOpenReaderSettings;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final horizontalPadding = constraints.maxWidth >= 600 ? 28.0 : 16.0;

          return ListView(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              12,
              horizontalPadding,
              32,
            ),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AccountHeroPanel(user: user),
                      const SizedBox(height: 18),
                      ReadingStatsGrid(user: user),
                      if (onRefreshProfile != null) ...[
                        const SizedBox(height: 8),
                        _AccountSessionTools(
                          onRefreshProfile: onRefreshProfile!,
                        ),
                      ],
                      const SizedBox(height: 16),
                      const AccountSectionTitle(title: 'لوحة القارئ'),
                      const SizedBox(height: 10),
                      AccountShortcutGrid(
                        onOpenFavorites: onOpenFavorites,
                        onOpenHistory: onOpenHistory,
                        onOpenDownloads: onOpenDownloads,
                        onOpenReaderSettings: onOpenReaderSettings,
                      ),
                      if (noticeMessage case final message?) ...[
                        const SizedBox(height: 18),
                        AccountNotice(message: message),
                      ],
                      const SizedBox(height: 16),
                      LogoutButton(
                        isSigningOut: isSigningOut,
                        onLogout: onLogout,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AccountSessionTools extends StatelessWidget {
  const _AccountSessionTools({required this.onRefreshProfile});

  final Future<void> Function() onRefreshProfile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(
          children: [
            Icon(Icons.sync_rounded, color: colors.secondary, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'بيانات الحساب تأتي من الموقع ويمكن تحديثها عند الحاجة.',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                  height: 1.35,
                ),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              key: const ValueKey('account-refresh-profile'),
              onPressed: onRefreshProfile,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('تحديث'),
            ),
          ],
        ),
      ),
    );
  }
}
