import '../domain/auth_session.dart';

class AuthSessionPayload {
  const AuthSessionPayload({required this.nonce, required this.user});

  factory AuthSessionPayload.fromResponse(Map<String, dynamic> response) {
    final nonce = response['nonce']?.toString().trim() ?? '';
    final userJson = response['user'];
    if (response['logged_in'] != true ||
        nonce.isEmpty ||
        userJson is! Map<String, dynamic>) {
      throw const FormatException('Incomplete session payload.');
    }
    return AuthSessionPayload(nonce: nonce, user: AuthUser.fromJson(userJson));
  }

  final String nonce;
  final AuthUser user;
}
