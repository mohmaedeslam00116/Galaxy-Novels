import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';
import '../../domain/auth_session.dart';

class LoginAccountView extends StatefulWidget {
  const LoginAccountView({
    required this.isSubmitting,
    required this.onLogin,
    this.errorMessage,
    this.onCreateAccount,
    this.onBackToGuest,
    super.key,
  });

  final bool isSubmitting;
  final String? errorMessage;
  final Future<void> Function(LoginCredentials credentials) onLogin;
  final VoidCallback? onCreateAccount;
  final VoidCallback? onBackToGuest;

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
    return AutofillGroup(
      key: const ValueKey('login-account-form'),
      child: Form(
        key: _formKey,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final sidePadding = constraints.maxWidth >= 560 ? 28.0 : 16.0;
            return ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(sidePadding, 20, sidePadding, 32),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (widget.onBackToGuest != null) ...[
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: TextButton.icon(
                              key: const ValueKey('login-back-to-guest'),
                              onPressed: widget.isSubmitting
                                  ? null
                                  : widget.onBackToGuest,
                              icon: const Icon(Icons.arrow_back_rounded),
                              label: const Text('العودة لوضع الزائر'),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        const _LoginHero(),
                        const SizedBox(height: 16),
                        const _LoginScopeNotice(),
                        if (widget.onCreateAccount != null) ...[
                          const SizedBox(height: 10),
                          TextButton.icon(
                            key: const ValueKey('auth-show-register'),
                            onPressed: widget.isSubmitting
                                ? null
                                : widget.onCreateAccount,
                            icon: const Icon(Icons.person_add_alt_1_rounded),
                            label: const Text('إنشاء حساب جديد'),
                          ),
                        ],
                        const SizedBox(height: 20),
                        TextFormField(
                          key: const ValueKey('login-username'),
                          controller: _usernameController,
                          enabled: !widget.isSubmitting,
                          autofillHints: const [AutofillHints.username],
                          textInputAction: TextInputAction.next,
                          textDirection: TextDirection.ltr,
                          textAlign: TextAlign.left,
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
                          textDirection: TextDirection.ltr,
                          textAlign: TextAlign.left,
                          onFieldSubmitted: (_) => _submit(),
                          decoration: InputDecoration(
                            labelText: 'كلمة المرور',
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            suffixIcon: IconButton(
                              onPressed: widget.isSubmitting
                                  ? null
                                  : () => setState(
                                      () =>
                                          _obscurePassword = !_obscurePassword,
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
                        if (widget.errorMessage case final message?) ...[
                          const SizedBox(height: 12),
                          _LoginError(message: message),
                        ],
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          key: const ValueKey('login-submit'),
                          onPressed: widget.isSubmitting ? null : _submit,
                          icon: widget.isSubmitting
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.login_rounded),
                          label: Text(
                            widget.isSubmitting
                                ? 'جارٍ تسجيل الدخول...'
                                : 'تسجيل الدخول',
                          ),
                        ),
                        const SizedBox(height: 10),
                        _RememberSessionTile(
                          value: _rememberSession,
                          enabled: !widget.isSubmitting,
                          onChanged: (value) =>
                              setState(() => _rememberSession = value ?? false),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
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

class _LoginHero extends StatelessWidget {
  const _LoginHero();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;

    return Column(
      children: [
        Icon(Icons.auto_stories_outlined, color: tokens.primary, size: 42),
        const SizedBox(height: 12),
        Text(
          'مرحبًا بعودتك',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge?.copyWith(
            color: tokens.textPrimary,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'حساب واحد لموقع مجرة الروايات والتطبيق',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: tokens.textSecondary,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _RememberSessionTile extends StatelessWidget {
  const _RememberSessionTile({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final bool value;
  final bool enabled;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;

    return CheckboxListTile(
      contentPadding: EdgeInsets.zero,
      value: value,
      onChanged: enabled ? onChanged : null,
      controlAffinity: ListTileControlAffinity.leading,
      title: Text(
        'تذكرني على هذا الجهاز',
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w800,
        ),
      ),
      subtitle: Text(
        'يبقي جلسة الحساب محفوظة لفتح السجل والمفضلة بسرعة.',
        style: theme.textTheme.bodySmall?.copyWith(
          color: tokens.textSecondary,
          height: 1.35,
        ),
      ),
    );
  }
}

class _LoginScopeNotice extends StatelessWidget {
  const _LoginScopeNotice();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;

    return Row(
      children: [
        Icon(Icons.verified_user_outlined, color: tokens.accent, size: 19),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            'استخدم حساب موقع مجرة الروايات الحالي للدخول.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: tokens.textSecondary,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
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
