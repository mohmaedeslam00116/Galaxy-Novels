import 'package:flutter/foundation.dart';

import '../domain/auth_session.dart';

abstract class AuthRepository implements ValueListenable<AuthSessionState> {
  Future<void> restoreSession();

  void dispose();
}
