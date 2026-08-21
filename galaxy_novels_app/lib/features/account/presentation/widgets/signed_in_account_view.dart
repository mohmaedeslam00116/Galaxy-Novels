import 'package:flutter/material.dart';

import '../../domain/auth_session.dart';
import 'account_action_list.dart';
import 'account_common_widgets.dart';
import 'account_hero_panel.dart';
import 'account_reading_stats.dart';

class SignedInAccountView extends StatelessWidget {
  const SignedInAccountView({
    required this.user,
    required this.isSigningOut,
    required this.onLogout,
    this.noticeMessage,
    this.onRefreshProfile,
    this.onOpenFavorites,
    this.onOpenHistory,
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
                      AccountHeroPanel(
                        user: user,
                        onRefreshProfile: onRefreshProfile,
                      ),
                      if (noticeMessage case final message?) ...[
                        const SizedBox(height: 10),
                        AccountNotice(message: message),
                      ],
                      const SizedBox(height: 18),
                      const AccountSectionTitle(title: 'نشاط القراءة'),
                      const SizedBox(height: 8),
                      AccountReadingStats(user: user),
                      const SizedBox(height: 18),
                      const AccountSectionTitle(title: 'حسابي'),
                      const SizedBox(height: 8),
                      AccountActionList(
                        onOpenFavorites: onOpenFavorites,
                        onOpenHistory: onOpenHistory,
                        onOpenReaderSettings: onOpenReaderSettings,
                      ),
                      const SizedBox(height: 14),
                      AccountLogoutRow(
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
