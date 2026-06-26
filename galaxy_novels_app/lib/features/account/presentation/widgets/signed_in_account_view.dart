import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';
import '../../domain/auth_session.dart';

class SignedInAccountView extends StatelessWidget {
  const SignedInAccountView({
    required this.user,
    required this.isSigningOut,
    required this.onLogout,
    this.noticeMessage,
    super.key,
  });

  final AuthUser user;
  final bool isSigningOut;
  final String? noticeMessage;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Text(
            user.displayName.characters.first,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          user.displayName,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        if (user.xp.rank.display.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            user.xp.rank.display,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        if (user.vip.active) ...[
          const SizedBox(height: 10),
          _VipStatusCard(vip: user.vip),
        ],
        const SizedBox(height: 28),
        LayoutBuilder(
          builder: (context, constraints) {
            const spacing = 8.0;
            final itemWidth = (constraints.maxWidth - spacing * 2) / 3;
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                SizedBox(
                  width: itemWidth,
                  height: 96,
                  child: _AccountStat(
                    label: 'نقاط XP',
                    value: user.xp.total.toString(),
                  ),
                ),
                SizedBox(
                  width: itemWidth,
                  height: 96,
                  child: _AccountStat(
                    label: 'XP اليوم',
                    value: user.xp.today.toString(),
                  ),
                ),
                SizedBox(
                  width: itemWidth,
                  height: 96,
                  child: _AccountStat(
                    label: 'فصول مقروءة',
                    value: user.xp.chaptersTotal.toString(),
                  ),
                ),
              ],
            );
          },
        ),
        if (noticeMessage case final message?) ...[
          const SizedBox(height: 20),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
        const SizedBox(height: 28),
        OutlinedButton.icon(
          onPressed: isSigningOut ? null : onLogout,
          icon: isSigningOut
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.logout_rounded),
          label: Text(isSigningOut ? 'جارٍ تسجيل الخروج...' : 'تسجيل الخروج'),
        ),
      ],
    );
  }
}

class _VipStatusCard extends StatelessWidget {
  const _VipStatusCard({required this.vip});

  final AuthVip vip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;
    final title = vip.label.isEmpty ? 'عضو VIP' : vip.label;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.gold.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tokens.gold.withValues(alpha: 0.32)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: tokens.gold.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.workspace_premium_outlined,
                color: tokens.gold,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: tokens.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _vipExpiryText(context, vip.expiresAt),
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
          ],
        ),
      ),
    );
  }

  String _vipExpiryText(BuildContext context, DateTime? expiresAt) {
    if (expiresAt == null) {
      return 'فعال حاليا';
    }
    final date = MaterialLocalizations.of(
      context,
    ).formatCompactDate(expiresAt.toLocal());
    return 'ينتهي في $date';
  }
}

class _AccountStat extends StatelessWidget {
  const _AccountStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  maxLines: 1,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
