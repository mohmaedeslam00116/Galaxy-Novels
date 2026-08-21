import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';

class AccountSectionTitle extends StatelessWidget {
  const AccountSectionTitle({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;

    return Row(
      children: [
        Container(
          width: 4,
          height: 22,
          decoration: BoxDecoration(
            color: tokens.accent,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: tokens.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class AccountNotice extends StatelessWidget {
  const AccountNotice({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tokens.danger.withValues(alpha: 0.22)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded, color: tokens.danger, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: tokens.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AccountLogoutRow extends StatelessWidget {
  const AccountLogoutRow({
    required this.isSigningOut,
    required this.onLogout,
    super.key,
  });

  final bool isSigningOut;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    final tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;

    final onTap = isSigningOut ? null : onLogout;

    return Semantics(
      key: const ValueKey('account-logout'),
      button: true,
      enabled: !isSigningOut,
      onTap: onTap,
      label: isSigningOut ? 'جارٍ تسجيل الخروج...' : 'تسجيل الخروج',
      excludeSemantics: true,
      child: Material(
        color: tokens.danger.withValues(alpha: 0.04),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: tokens.danger.withValues(alpha: 0.2)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
              child: Row(
                children: [
                  if (isSigningOut)
                    SizedBox.square(
                      dimension: 19,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: tokens.danger,
                      ),
                    )
                  else
                    Icon(Icons.logout_rounded, color: tokens.danger, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isSigningOut ? 'جارٍ تسجيل الخروج...' : 'تسجيل الخروج',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: tokens.danger,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
