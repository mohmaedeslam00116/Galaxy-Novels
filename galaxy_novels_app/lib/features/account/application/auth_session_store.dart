import '../../../core/network/private_api_client.dart';

abstract interface class AuthSessionStore {
  Future<PrivateSessionSnapshot?> read();

  Future<void> write(PrivateSessionSnapshot session);

  Future<void> clear();
}

class AuthSessionStoreException implements Exception {
  const AuthSessionStoreException();
}
