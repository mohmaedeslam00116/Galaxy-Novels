import 'package:flutter/material.dart';

import '../../domain/auth_session.dart';
import 'login_account_view.dart';
import 'register_account_view.dart';

class AuthEntryView extends StatefulWidget {
  const AuthEntryView({
    required this.isSubmitting,
    required this.onLogin,
    required this.onRegister,
    this.errorMessage,
    super.key,
  });

  final bool isSubmitting;
  final String? errorMessage;
  final Future<void> Function(LoginCredentials credentials) onLogin;
  final Future<void> Function(RegisterCredentials credentials) onRegister;

  @override
  State<AuthEntryView> createState() => _AuthEntryViewState();
}

class _AuthEntryViewState extends State<AuthEntryView> {
  bool _registerMode = false;

  @override
  Widget build(BuildContext context) {
    if (_registerMode) {
      return RegisterAccountView(
        isSubmitting: widget.isSubmitting,
        errorMessage: widget.errorMessage,
        onRegister: widget.onRegister,
        onShowLogin: () => setState(() => _registerMode = false),
      );
    }

    return LoginAccountView(
      isSubmitting: widget.isSubmitting,
      errorMessage: widget.errorMessage,
      onLogin: widget.onLogin,
      onCreateAccount: () => setState(() => _registerMode = true),
    );
  }
}
