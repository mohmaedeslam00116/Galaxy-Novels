import 'package:flutter/material.dart';

import '../../application/auth_repository.dart';
import '../../domain/auth_session.dart';
import 'signed_in_account_view.dart';

class AccountSessionView extends StatelessWidget {
  const AccountSessionView({required this.repository, super.key});

  final AuthRepository repository;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AuthSessionState>(
      valueListenable: repository,
      builder: (context, state, _) {
        return switch (state.status) {
          AuthSessionStatus.idle ||
          AuthSessionStatus.loading => const _LoadingAccount(),
          AuthSessionStatus.guest => const _GuestAccount(),
          AuthSessionStatus.failure => _AccountFailure(
            message: state.errorMessage ?? 'تعذر التحقق من الجلسة.',
            onRetry: repository.restoreSession,
          ),
          AuthSessionStatus.authenticated => SignedInAccountView(
            user: state.user!,
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
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('جارٍ التحقق من الجلسة...'),
        ],
      ),
    );
  }
}

class _GuestAccount extends StatelessWidget {
  const _GuestAccount();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
      children: [
        Icon(
          Icons.person_outline_rounded,
          size: 64,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 20),
        Text(
          'أنت تتصفح كزائر',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'سجّل الدخول لمزامنة القراءة والمفضلة و XP.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 24),
        const FilledButton(onPressed: null, child: Text('تسجيل الدخول')),
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
