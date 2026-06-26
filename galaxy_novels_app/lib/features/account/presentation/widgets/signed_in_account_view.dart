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
                      const SizedBox(height: 22),
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
                      const SizedBox(height: 24),
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
