import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';

class GuestAccountView extends StatelessWidget {
  const GuestAccountView({
    required this.onShowLogin,
    required this.onShowRegister,
    this.errorMessage,
    super.key,
  });

  final VoidCallback onShowLogin;
  final VoidCallback onShowRegister;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 32),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.auto_stories_outlined,
                  size: 44,
                  color: tokens.primary,
                ),
                const SizedBox(height: 14),
                Text(
                  'تتصفح كزائر',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: tokens.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'القراءة متاحة دون حساب. سجّل الدخول فقط عندما تريد مزامنة السجل والمفضلة.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: tokens.textSecondary,
                    height: 1.5,
                  ),
                ),
                if (errorMessage case final message?) ...[
                  const SizedBox(height: 16),
                  _GuestError(message: message),
                ],
                const SizedBox(height: 22),
                FilledButton.icon(
                  key: const ValueKey('auth-show-login'),
                  onPressed: onShowLogin,
                  icon: const Icon(Icons.login_rounded),
                  label: const Text('تسجيل الدخول'),
                ),
                const SizedBox(height: 6),
                TextButton(
                  key: const ValueKey('auth-show-register'),
                  onPressed: onShowRegister,
                  child: const Text('إنشاء حساب'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _GuestError extends StatelessWidget {
  const _GuestError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.errorContainer.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(Icons.error_outline_rounded, color: colors.onErrorContainer),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: colors.onErrorContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
