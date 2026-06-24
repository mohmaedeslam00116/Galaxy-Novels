import 'package:flutter/foundation.dart';
import 'package:galaxy_novels_app/features/account/application/auth_repository.dart';
import 'package:galaxy_novels_app/features/account/domain/auth_session.dart';

class FakeAuthRepository extends ValueNotifier<AuthSessionState>
    implements AuthRepository {
  FakeAuthRepository({
    AuthSessionState initialState = const AuthSessionState.guest(),
  }) : super(initialState);

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
  }

  @override
  Future<void> refreshProfile() async {
    refreshProfileCalls += 1;
  }

  @override
  Future<void> logout() async {
    value = const AuthSessionState.guest();
  }
}
