import 'package:flutter/material.dart';

import '../../domain/auth_session.dart';

class LoginAccountView extends StatefulWidget {
  const LoginAccountView({
    required this.isSubmitting,
    required this.onLogin,
    this.errorMessage,
    super.key,
  });

  final bool isSubmitting;
  final String? errorMessage;
  final Future<void> Function(LoginCredentials credentials) onLogin;

  @override
  State<LoginAccountView> createState() => _LoginAccountViewState();
}

class _LoginAccountViewState extends State<LoginAccountView> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberSession = true;
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AutofillGroup(
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
          children: [
            Icon(
              Icons.person_outline_rounded,
              size: 56,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'تسجيل الدخول',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'سجّل الدخول لعرض بيانات حسابك داخل التطبيق.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 28),
            TextFormField(
              key: const ValueKey('login-username'),
              controller: _usernameController,
              enabled: !widget.isSubmitting,
              autofillHints: const [AutofillHints.username],
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'اسم المستخدم أو البريد الإلكتروني',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              validator: _validateUsername,
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const ValueKey('login-password'),
              controller: _passwordController,
              enabled: !widget.isSubmitting,
              autofillHints: const [AutofillHints.password],
              obscureText: _obscurePassword,
              enableSuggestions: false,
              autocorrect: false,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: 'كلمة المرور',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  onPressed: widget.isSubmitting
                      ? null
                      : () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                  tooltip: _obscurePassword
                      ? 'إظهار كلمة المرور'
                      : 'إخفاء كلمة المرور',
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: _validatePassword,
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _rememberSession,
              onChanged: widget.isSubmitting
                  ? null
                  : (value) =>
                        setState(() => _rememberSession = value ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text('تذكرني على هذا الجهاز'),
            ),
            if (widget.errorMessage case final message?) ...[
              _LoginError(message: message),
              const SizedBox(height: 14),
            ],
            FilledButton.icon(
              key: const ValueKey('login-submit'),
              onPressed: widget.isSubmitting ? null : _submit,
              icon: widget.isSubmitting
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.login_rounded),
              label: Text(
                widget.isSubmitting ? 'جارٍ تسجيل الدخول...' : 'تسجيل الدخول',
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _validateUsername(String? input) {
    return input?.trim().isEmpty == false
        ? null
        : 'أدخل اسم المستخدم أو البريد الإلكتروني.';
  }

  String? _validatePassword(String? input) {
    return input?.isNotEmpty == true ? null : 'أدخل كلمة المرور.';
  }

  Future<void> _submit() async {
    if (widget.isSubmitting || _formKey.currentState?.validate() != true) {
      return;
    }
    FocusScope.of(context).unfocus();
    await widget.onLogin(
      LoginCredentials(
        username: _usernameController.text,
        password: _passwordController.text,
        rememberSession: _rememberSession,
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

class _LoginError extends StatelessWidget {
  const _LoginError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: theme.colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
