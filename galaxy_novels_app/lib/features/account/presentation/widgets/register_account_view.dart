import 'package:flutter/material.dart';

import '../../domain/auth_session.dart';

class RegisterAccountView extends StatefulWidget {
  const RegisterAccountView({
    required this.isSubmitting,
    required this.onRegister,
    required this.onShowLogin,
    this.errorMessage,
    this.onBackToGuest,
    super.key,
  });

  final bool isSubmitting;
  final String? errorMessage;
  final Future<void> Function(RegisterCredentials credentials) onRegister;
  final VoidCallback onShowLogin;
  final VoidCallback? onBackToGuest;

  @override
  State<RegisterAccountView> createState() => _RegisterAccountViewState();
}

class _RegisterAccountViewState extends State<RegisterAccountView> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _rememberSession = true;
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AutofillGroup(
      key: const ValueKey('register-account-form'),
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
                              key: const ValueKey('register-back-to-guest'),
                              onPressed: widget.isSubmitting
                                  ? null
                                  : widget.onBackToGuest,
                              icon: const Icon(Icons.arrow_back_rounded),
                              label: const Text('العودة لوضع الزائر'),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        Icon(
                          Icons.person_add_alt_1_rounded,
                          size: 44,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'إنشاء حساب',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'أنشئ حساب مجرة الروايات واستخدمه مباشرة داخل التطبيق.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 22),
                        TextFormField(
                          key: const ValueKey('register-username'),
                          controller: _usernameController,
                          enabled: !widget.isSubmitting,
                          autofillHints: const [AutofillHints.newUsername],
                          textInputAction: TextInputAction.next,
                          textDirection: TextDirection.ltr,
                          textAlign: TextAlign.left,
                          decoration: const InputDecoration(
                            labelText: 'اسم المستخدم',
                            prefixIcon: Icon(Icons.alternate_email_rounded),
                          ),
                          validator: _required('أدخل اسم المستخدم.'),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          key: const ValueKey('register-email'),
                          controller: _emailController,
                          enabled: !widget.isSubmitting,
                          autofillHints: const [AutofillHints.email],
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          textDirection: TextDirection.ltr,
                          textAlign: TextAlign.left,
                          decoration: const InputDecoration(
                            labelText: 'البريد الإلكتروني',
                            prefixIcon: Icon(Icons.mail_outline_rounded),
                          ),
                          validator: _validateEmail,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          key: const ValueKey('register-display-name'),
                          controller: _displayNameController,
                          enabled: !widget.isSubmitting,
                          autofillHints: const [AutofillHints.name],
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'الاسم الظاهر',
                            prefixIcon: Icon(Icons.badge_outlined),
                          ),
                          validator: _required('أدخل الاسم الظاهر.'),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          key: const ValueKey('register-password'),
                          controller: _passwordController,
                          enabled: !widget.isSubmitting,
                          autofillHints: const [AutofillHints.newPassword],
                          obscureText: _obscurePassword,
                          enableSuggestions: false,
                          autocorrect: false,
                          textInputAction: TextInputAction.next,
                          textDirection: TextDirection.ltr,
                          textAlign: TextAlign.left,
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
                        const SizedBox(height: 12),
                        TextFormField(
                          key: const ValueKey('register-confirm-password'),
                          controller: _confirmPasswordController,
                          enabled: !widget.isSubmitting,
                          obscureText: _obscurePassword,
                          enableSuggestions: false,
                          autocorrect: false,
                          textInputAction: TextInputAction.done,
                          textDirection: TextDirection.ltr,
                          textAlign: TextAlign.left,
                          onFieldSubmitted: (_) => _submit(),
                          decoration: const InputDecoration(
                            labelText: 'تأكيد كلمة المرور',
                            prefixIcon: Icon(Icons.lock_reset_rounded),
                          ),
                          validator: _validateConfirmPassword,
                        ),
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _rememberSession,
                          onChanged: widget.isSubmitting
                              ? null
                              : (value) => setState(
                                  () => _rememberSession = value ?? false,
                                ),
                          controlAffinity: ListTileControlAffinity.leading,
                          title: const Text('تذكرني على هذا الجهاز'),
                        ),
                        if (widget.errorMessage case final message?) ...[
                          _RegisterError(message: message),
                          const SizedBox(height: 14),
                        ],
                        FilledButton.icon(
                          key: const ValueKey('register-submit'),
                          onPressed: widget.isSubmitting ? null : _submit,
                          icon: widget.isSubmitting
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.person_add_alt_1_rounded),
                          label: Text(
                            widget.isSubmitting
                                ? 'جارٍ إنشاء الحساب...'
                                : 'إنشاء الحساب',
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextButton.icon(
                          key: const ValueKey('register-show-login'),
                          onPressed: widget.isSubmitting
                              ? null
                              : widget.onShowLogin,
                          icon: const Icon(Icons.login_rounded),
                          label: const Text('لديك حساب؟ تسجيل الدخول'),
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

  FormFieldValidator<String> _required(String message) {
    return (input) => input?.trim().isEmpty == false ? null : message;
  }

  String? _validateEmail(String? input) {
    final email = input?.trim() ?? '';
    if (email.isEmpty) {
      return 'أدخل البريد الإلكتروني.';
    }
    return email.contains('@') ? null : 'أدخل بريدًا إلكترونيًا صحيحًا.';
  }

  String? _validatePassword(String? input) {
    final password = input ?? '';
    if (password.isEmpty) {
      return 'أدخل كلمة المرور.';
    }
    return password.length >= 6
        ? null
        : 'كلمة المرور يجب أن تكون 6 أحرف على الأقل.';
  }

  String? _validateConfirmPassword(String? input) {
    if ((input ?? '').isEmpty) {
      return 'أكد كلمة المرور.';
    }
    return input == _passwordController.text
        ? null
        : 'كلمتا المرور غير متطابقتين.';
  }

  Future<void> _submit() async {
    if (widget.isSubmitting || _formKey.currentState?.validate() != true) {
      return;
    }
    FocusScope.of(context).unfocus();
    await widget.onRegister(
      RegisterCredentials(
        username: _usernameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        displayName: _displayNameController.text,
        rememberSession: _rememberSession,
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _displayNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}

class _RegisterError extends StatelessWidget {
  const _RegisterError({required this.message});

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
