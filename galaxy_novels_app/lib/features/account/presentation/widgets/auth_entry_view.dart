import 'package:flutter/material.dart';

import '../../domain/auth_session.dart';
import 'guest_account_view.dart';
import 'login_account_view.dart';
import 'register_account_view.dart';

enum _AuthEntryMode { guest, login, register }

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
  _AuthEntryMode _mode = _AuthEntryMode.guest;

  @override
  Widget build(BuildContext context) {
    return switch (_mode) {
      _AuthEntryMode.guest => GuestAccountView(
        errorMessage: widget.errorMessage,
        onShowLogin: () => setState(() => _mode = _AuthEntryMode.login),
        onShowRegister: () => setState(() => _mode = _AuthEntryMode.register),
      ),
      _AuthEntryMode.login => LoginAccountView(
        isSubmitting: widget.isSubmitting,
        errorMessage: widget.errorMessage,
        onLogin: widget.onLogin,
        onCreateAccount: () => setState(() => _mode = _AuthEntryMode.register),
        onBackToGuest: () => setState(() => _mode = _AuthEntryMode.guest),
      ),
      _AuthEntryMode.register => RegisterAccountView(
        isSubmitting: widget.isSubmitting,
        errorMessage: widget.errorMessage,
        onRegister: widget.onRegister,
        onShowLogin: () => setState(() => _mode = _AuthEntryMode.login),
        onBackToGuest: () => setState(() => _mode = _AuthEntryMode.guest),
      ),
    };
  }
}
