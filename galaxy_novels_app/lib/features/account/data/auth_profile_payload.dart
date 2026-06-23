import '../domain/auth_session.dart';

class AuthProfilePayload {
  const AuthProfilePayload({required this.user});

  factory AuthProfilePayload.fromResponse(
    Map<String, dynamic> response, {
    required int expectedUserId,
  }) {
    final userJson = response['user'];
    if (userJson is! Map<String, dynamic>) {
      throw const FormatException('Missing authenticated user profile.');
    }

    final user = AuthUser.fromJson(userJson);
    if (user.id != expectedUserId) {
      throw const FormatException('Authenticated user profile changed.');
    }

    return AuthProfilePayload(user: user);
  }

  final AuthUser user;
}
