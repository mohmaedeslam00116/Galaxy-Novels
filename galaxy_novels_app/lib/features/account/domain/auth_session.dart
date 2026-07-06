enum AuthSessionStatus {
  idle,
  restoring,
  guest,
  authenticating,
  authenticated,
  signingOut,
  failure,
}

class AuthSessionState {
  const AuthSessionState._({
    required this.status,
    this.user,
    this.errorMessage,
    this.noticeMessage,
  });

  const AuthSessionState.idle() : this._(status: AuthSessionStatus.idle);

  const AuthSessionState.restoring()
    : this._(status: AuthSessionStatus.restoring);

  const AuthSessionState.guest({String? errorMessage})
    : this._(status: AuthSessionStatus.guest, errorMessage: errorMessage);

  const AuthSessionState.authenticating()
    : this._(status: AuthSessionStatus.authenticating);

  const AuthSessionState.authenticated(AuthUser user, {String? noticeMessage})
    : this._(
        status: AuthSessionStatus.authenticated,
        user: user,
        noticeMessage: noticeMessage,
      );

  const AuthSessionState.signingOut(AuthUser user)
    : this._(status: AuthSessionStatus.signingOut, user: user);

  const AuthSessionState.failure(String message)
    : this._(status: AuthSessionStatus.failure, errorMessage: message);

  final AuthSessionStatus status;
  final AuthUser? user;
  final String? errorMessage;
  final String? noticeMessage;
}

class LoginCredentials {
  const LoginCredentials({
    required this.username,
    required this.password,
    required this.rememberSession,
  });

  final String username;
  final String password;
  final bool rememberSession;
}

class RegisterCredentials {
  const RegisterCredentials({
    required this.username,
    required this.email,
    required this.password,
    required this.displayName,
    required this.rememberSession,
    this.deviceId = 'galaxy-novels-android',
    this.deviceLabel = 'Android',
    this.cfTurnstileResponse,
  });

  final String username;
  final String email;
  final String password;
  final String displayName;
  final bool rememberSession;
  final String deviceId;
  final String deviceLabel;
  final String? cfTurnstileResponse;
}

class AuthUser {
  const AuthUser({
    required this.id,
    required this.displayName,
    required this.avatar,
    required this.vip,
    required this.xp,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final id = _asInt(json['id']);
    final displayName = _asString(json['display_name']);
    if (id <= 0 || displayName.isEmpty) {
      throw const FormatException('Invalid authenticated user payload.');
    }

    return AuthUser(
      id: id,
      displayName: displayName,
      avatar: Uri.tryParse(_asString(json['avatar'])),
      vip: AuthVip.fromJson(_asMap(json['vip'])),
      xp: AuthXp.fromJson(_asMap(json['xp'])),
    );
  }

  final int id;
  final String displayName;
  final Uri? avatar;
  final AuthVip vip;
  final AuthXp xp;
}

class AuthVip {
  const AuthVip({
    required this.active,
    required this.tier,
    required this.label,
    required this.expiresAt,
  });

  factory AuthVip.fromJson(Map<String, dynamic> json) {
    return AuthVip(
      active: json['active'] == true,
      tier: _asString(json['tier']),
      label: _asString(json['label']),
      expiresAt: DateTime.tryParse(_asString(json['expires_at'])),
    );
  }

  final bool active;
  final String tier;
  final String label;
  final DateTime? expiresAt;
}

class AuthXp {
  const AuthXp({
    required this.total,
    required this.today,
    required this.secondsTotal,
    required this.chaptersTotal,
    required this.rank,
  });

  factory AuthXp.fromJson(Map<String, dynamic> json) {
    return AuthXp(
      total: _asInt(json['total']),
      today: _asInt(json['today']),
      secondsTotal: _asInt(json['seconds_total']),
      chaptersTotal: _asInt(json['chapters_total']),
      rank: AuthRank.fromJson(_asMap(json['rank'])),
    );
  }

  final int total;
  final int today;
  final int secondsTotal;
  final int chaptersTotal;
  final AuthRank rank;
}

class AuthRank {
  const AuthRank({required this.level, required this.display});

  factory AuthRank.fromJson(Map<String, dynamic> json) {
    return AuthRank(
      level: _asInt(json['level']),
      display: _asString(json['display']),
    );
  }

  final int level;
  final String display;
}

Map<String, dynamic> _asMap(Object? value) {
  return value is Map<String, dynamic> ? value : const {};
}

String _asString(Object? value) => value?.toString().trim() ?? '';

int _asInt(Object? value) {
  if (value is int) {
    return value;
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
