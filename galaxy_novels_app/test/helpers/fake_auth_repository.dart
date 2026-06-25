import 'package:flutter/foundation.dart';
import 'package:galaxy_novels_app/features/account/application/auth_repository.dart';
import 'package:galaxy_novels_app/features/account/domain/auth_session.dart';

class FakeAuthRepository extends ValueNotifier<AuthSessionState>
    implements AuthRepository {
  FakeAuthRepository({
    AuthSessionState initialState = const AuthSessionState.guest(),
    this.authenticatedUser,
    this.expireOnRefresh = false,
  }) : super(initialState);

  final AuthUser? authenticatedUser;
  final bool expireOnRefresh;

  LoginCredentials? lastLogin;
  int refreshProfileCalls = 0;

  @override
  Future<void> restoreSession() async {
    if (value.status == AuthSessionStatus.idle) {
      value = const AuthSessionState.guest();
    }
  }

  @override
  Future<void> login(LoginCredentials credentials) async {
    lastLogin = credentials;
    final user = authenticatedUser;
    if (user != null) {
      value = AuthSessionState.authenticated(user);
    }
  }

  @override
  Future<void> refreshProfile() async {
    refreshProfileCalls += 1;
    if (expireOnRefresh) {
      value = const AuthSessionState.guest();
    }
  }

  @override
  Future<void> logout() async {
    value = const AuthSessionState.guest();
  }
}
