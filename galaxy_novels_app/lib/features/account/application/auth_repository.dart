import 'package:flutter/foundation.dart';

import '../domain/auth_session.dart';

abstract class AuthRepository implements ValueListenable<AuthSessionState> {
  Future<void> restoreSession();

  Future<void> login(LoginCredentials credentials);

  Future<void> refreshProfile();

  Future<void> logout();

  void dispose();
}
