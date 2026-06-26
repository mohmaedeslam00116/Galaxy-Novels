import '../domain/auth_session.dart';

class AuthSessionPayload {
  const AuthSessionPayload({
    required this.user,
    this.accessToken,
    this.tokenType = 'Bearer',
    this.expiresAt,
  });

  factory AuthSessionPayload.fromResponse(Map<String, dynamic> response) {
    final userJson = response['user'];
    if (response['logged_in'] != true || userJson is! Map<String, dynamic>) {
      throw const FormatException('Incomplete session payload.');
    }
    return AuthSessionPayload(
      user: AuthUser.fromJson(userJson),
      accessToken: _optionalHeaderValue(response['access_token']),
      tokenType: _optionalHeaderValue(response['token_type']) ?? 'Bearer',
      expiresAt: DateTime.tryParse(response['expires_at']?.toString() ?? ''),
    );
  }

  final AuthUser user;
  final String? accessToken;
  final String tokenType;
  final DateTime? expiresAt;
}

String? _optionalHeaderValue(Object? value) {
  final text = value?.toString().trim() ?? '';
  if (text.isEmpty || text.contains('\r') || text.contains('\n')) {
    return null;
  }
  return text;
}
