import 'package:flutter/foundation.dart';

import '../../../core/network/private_api_client.dart';
import '../application/auth_repository.dart';
import '../domain/auth_session.dart';

class SessionAuthRepository extends ChangeNotifier implements AuthRepository {
  SessionAuthRepository({required PrivateApiClient client}) : _client = client;

  final PrivateApiClient _client;

  AuthSessionState _value = const AuthSessionState.idle();
  Future<void>? _restoreInFlight;
  bool _disposed = false;

  @override
  AuthSessionState get value => _value;

  @override
  Future<void> restoreSession() {
    return _restoreInFlight ??= _restore().whenComplete(() {
      _restoreInFlight = null;
    });
  }

  Future<void> _restore() async {
    _setValue(const AuthSessionState.loading());

    try {
      final response = await _client.getPublic('session');
      if (response['logged_in'] != true) {
        _client.clearSession();
        _setValue(const AuthSessionState.guest());
        return;
      }

      final nonce = response['nonce']?.toString().trim() ?? '';
      final userJson = response['user'];
      if (nonce.isEmpty || userJson is! Map<String, dynamic>) {
        throw const FormatException('Incomplete session payload.');
      }

      _client.updateNonce(nonce);
      _setValue(AuthSessionState.authenticated(AuthUser.fromJson(userJson)));
    } on PrivateApiException catch (error) {
      _setValue(AuthSessionState.failure(_messageFor(error)));
    } on FormatException {
      _client.clearSession();
      _setValue(
        const AuthSessionState.failure(
          'تعذر قراءة بيانات الحساب. حاول مرة أخرى.',
        ),
      );
    }
  }

  void _setValue(AuthSessionState next) {
    if (_disposed) {
      return;
    }
    _value = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

String _messageFor(PrivateApiException error) {
  return switch (error.code) {
    'network_unavailable' =>
      'لا يوجد اتصال بالموقع الآن. تحقق من الشبكة وحاول مجددًا.',
    'timeout' => 'استغرق الاتصال وقتًا أطول من المتوقع. حاول مجددًا.',
    _ => 'تعذر التحقق من الجلسة الآن. حاول مجددًا.',
  };
}
