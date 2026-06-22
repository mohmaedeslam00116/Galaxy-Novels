import 'package:flutter/material.dart';

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
          Align(
            child: Chip(
              avatar: const Icon(Icons.workspace_premium_outlined, size: 18),
              label: Text(user.vip.label.isEmpty ? 'عضو VIP' : user.vip.label),
            ),
          ),
        ],
        const SizedBox(height: 28),
        Row(
          children: [
            Expanded(
              child: _AccountStat(label: 'نقاط XP', value: '${user.xp.total}'),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _AccountStat(
                label: 'فصول مقروءة',
                value: '${user.xp.chaptersTotal}',
              ),
            ),
          ],
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Column(
          children: [
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
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
