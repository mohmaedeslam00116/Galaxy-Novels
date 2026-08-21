import 'package:flutter/material.dart';

import '../../application/auth_repository.dart';
import '../../domain/auth_session.dart';
import 'account_loading_state.dart';
import 'auth_entry_view.dart';
import 'signed_in_account_view.dart';

class AccountSessionView extends StatelessWidget {
  const AccountSessionView({
    required this.repository,
    this.onOpenFavorites,
    this.onOpenHistory,
    this.onOpenReaderSettings,
    super.key,
  });

  final AuthRepository repository;
  final VoidCallback? onOpenFavorites;
  final VoidCallback? onOpenHistory;
  final VoidCallback? onOpenReaderSettings;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AuthSessionState>(
      valueListenable: repository,
      builder: (context, state, _) {
        return switch (state.status) {
          AuthSessionStatus.idle ||
          AuthSessionStatus.restoring => const AccountLoadingState(),
          AuthSessionStatus.guest ||
          AuthSessionStatus.authenticating => AuthEntryView(
            errorMessage: state.errorMessage,
            isSubmitting: state.status == AuthSessionStatus.authenticating,
            onLogin: repository.login,
            onRegister: repository.register,
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
            onOpenReaderSettings: onOpenReaderSettings,
          ),
        };
      },
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
