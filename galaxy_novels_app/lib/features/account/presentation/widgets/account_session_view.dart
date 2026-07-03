import 'package:flutter/material.dart';

import '../../application/auth_repository.dart';
import '../../domain/auth_session.dart';
import 'login_account_view.dart';
import 'signed_in_account_view.dart';

class AccountSessionView extends StatelessWidget {
  const AccountSessionView({
    required this.repository,
    this.onOpenFavorites,
    this.onOpenHistory,
    this.onOpenDownloads,
    this.onOpenReaderSettings,
    super.key,
  });

  final AuthRepository repository;
  final VoidCallback? onOpenFavorites;
  final VoidCallback? onOpenHistory;
  final VoidCallback? onOpenDownloads;
  final VoidCallback? onOpenReaderSettings;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AuthSessionState>(
      valueListenable: repository,
      builder: (context, state, _) {
        return switch (state.status) {
          AuthSessionStatus.idle ||
          AuthSessionStatus.restoring => const _LoadingAccount(),
          AuthSessionStatus.guest ||
          AuthSessionStatus.authenticating => LoginAccountView(
            errorMessage: state.errorMessage,
            isSubmitting: state.status == AuthSessionStatus.authenticating,
            onLogin: repository.login,
          ),
          AuthSessionStatus.failure => _AccountFailure(
            message: state.errorMessage ?? 'تعذر التحقق من الجلسة.',
            onRetry: repository.restoreSession,
          ),
          AuthSessionStatus.authenticated ||
          AuthSessionStatus.signingOut => SignedInAccountView(
            user: state.user!,
            noticeMessage: state.noticeMessage,
            isSigningOut: state.status == AuthSessionStatus.signingOut,
            onLogout: repository.logout,
            onRefreshProfile: repository.refreshProfile,
            onOpenFavorites: onOpenFavorites,
            onOpenHistory: onOpenHistory,
            onOpenDownloads: onOpenDownloads,
            onOpenReaderSettings: onOpenReaderSettings,
          ),
        };
      },
    );
  }
}

class _LoadingAccount extends StatelessWidget {
  const _LoadingAccount();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final placeholder = theme.colorScheme.surfaceContainerHighest;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
      children: [
        Align(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: placeholder,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Align(
          child: Container(
            width: 160,
            height: 20,
            decoration: BoxDecoration(
              color: placeholder,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
        const SizedBox(height: 28),
        for (var index = 0; index < 2; index++) ...[
          Container(
            height: 56,
            decoration: BoxDecoration(
              color: placeholder,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _AccountFailure extends StatelessWidget {
  const _AccountFailure({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}
