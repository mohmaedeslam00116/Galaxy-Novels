import 'package:galaxy_novels_app/core/network/private_api_client.dart';
import 'package:galaxy_novels_app/features/account/application/auth_session_store.dart';

class FakeAuthSessionStore implements AuthSessionStore {
  PrivateSessionSnapshot? session;
  int clearCount = 0;
  int writeCount = 0;

  @override
  Future<PrivateSessionSnapshot?> read() async => session;

  @override
  Future<void> write(PrivateSessionSnapshot session) async {
    writeCount += 1;
    this.session = session;
  }

  @override
  Future<void> clear() async {
    clearCount += 1;
    session = null;
  }
}
