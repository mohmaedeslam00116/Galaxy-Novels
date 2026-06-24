import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/network/private_api_client.dart';
import '../application/auth_repository.dart';
import '../application/auth_session_store.dart';
import '../domain/auth_session.dart';
import 'auth_error_messages.dart';
import 'auth_profile_payload.dart';
import 'auth_session_payload.dart';

class SessionAuthRepository extends ChangeNotifier implements AuthRepository {
  SessionAuthRepository({
    required PrivateApiClient client,
    required AuthSessionStore sessionStore,
    Duration profileRefreshCooldown = const Duration(seconds: 60),
  }) : _client = client,
       _sessionStore = sessionStore,
       _profileRefreshCooldown = profileRefreshCooldown,
       _profileRefreshClock = Stopwatch()..start() {
    if (profileRefreshCooldown.isNegative) {
      throw ArgumentError.value(
        profileRefreshCooldown,
        'profileRefreshCooldown',
        'must not be negative',
      );
    }
  }

  final PrivateApiClient _client;
  final AuthSessionStore _sessionStore;
  final Duration _profileRefreshCooldown;
  final Stopwatch _profileRefreshClock;

  AuthSessionState _value = const AuthSessionState.idle();
  Future<void>? _restoreInFlight;
  Future<void>? _profileRefreshInFlight;
  int? _profileRefreshInFlightUserId;
  int? _profileRefreshInFlightGeneration;
  Timer? _profileRefreshTimer;
  int? _profileRefreshTimerUserId;
  int? _profileRefreshTimerGeneration;
  Duration? _lastProfileRefreshAttemptElapsed;
  int _sessionGeneration = 0;
  bool _persistSession = false;
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
    _resetProfileRefreshRequests();
    _sessionGeneration += 1;
    _publishState(const AuthSessionState.restoring());
    _client.clearSession();

    try {
      final session = await _loadServerSession();
      if (session == null) {
        await _clearSession();
        _publishState(const AuthSessionState.guest());
        return;
      }
      final notice = await _persistSnapshotIfNeeded();
      _publishState(
        AuthSessionState.authenticated(session.user, noticeMessage: notice),
      );
    } on PrivateApiException catch (error) {
      _publishState(AuthSessionState.failure(restoreMessageFor(error)));
    } on AuthSessionStoreException {
      _publishState(
        const AuthSessionState.failure(
          'تعذر الوصول إلى الجلسة المحفوظة على الجهاز.',
        ),
      );
    } on FormatException {
      await _clearSessionAfterInvalidResponse();
      _publishState(
        const AuthSessionState.failure(
          'تعذر قراءة بيانات الحساب. حاول مرة أخرى.',
        ),
      );
    }
  }

  Future<AuthSessionPayload?> _loadServerSession() async {
    final storedSession = await _sessionStore.read();
    _persistSession = storedSession != null;
    if (storedSession != null) {
      _client.importSessionSnapshot(storedSession);
    }

    final response = await _client.getPublic('session');
    if (response['logged_in'] != true) {
      return null;
    }
    final session = AuthSessionPayload.fromResponse(response);
    _client.updateNonce(session.nonce);
    return session;
  }

  @override
  Future<void> login(LoginCredentials credentials) async {
    if (_value.status == AuthSessionStatus.authenticating) {
      return;
    }
    _resetProfileRefreshRequests();
    _sessionGeneration += 1;
    if (credentials.username.trim().isEmpty || credentials.password.isEmpty) {
      _publishState(
        const AuthSessionState.guest(
          errorMessage: 'أدخل اسم المستخدم وكلمة المرور.',
        ),
      );
      return;
    }

    _publishState(const AuthSessionState.authenticating());
    _client.clearSession();
    _persistSession = false;

    try {
      final session = await _requestLogin(credentials);
      final notice = await _persistSnapshotIfNeeded();
      _publishState(
        AuthSessionState.authenticated(session.user, noticeMessage: notice),
      );
    } on PrivateApiException catch (error) {
      _client.clearSession();
      _publishState(
        AuthSessionState.guest(errorMessage: loginMessageFor(error)),
      );
    } on AuthSessionStoreException {
      _publishState(
        const AuthSessionState.guest(
          errorMessage: 'تعذر استخدام التخزين الآمن على هذا الجهاز.',
        ),
      );
    } on FormatException {
      _client.clearSession();
      _publishState(
        const AuthSessionState.guest(
          errorMessage: 'أعاد الموقع بيانات حساب غير مكتملة.',
        ),
      );
    }
  }

  Future<AuthSessionPayload> _requestLogin(LoginCredentials credentials) async {
    await _sessionStore.clear();
    final response = await _client.postPublic(
      'auth/login',
      body: {
        'username': credentials.username.trim(),
        'password': credentials.password,
        'remember': credentials.rememberSession,
      },
    );
    final session = AuthSessionPayload.fromResponse(response);
    _client.updateNonce(session.nonce);
    _persistSession = credentials.rememberSession;
    return session;
  }

  @override
  Future<void> refreshProfile() {
    final requestSession = _activeAuthenticatedSession();
    if (requestSession == null) {
      return Future.value();
    }

    final inFlight = _profileRefreshInFlight;
    if (inFlight != null &&
        _profileRefreshInFlightUserId == requestSession.user.id &&
        _profileRefreshInFlightGeneration == requestSession.generation) {
      return inFlight;
    }

    final lastAttemptElapsed = _lastProfileRefreshAttemptElapsed;
    if (lastAttemptElapsed != null) {
      final cooldownRemaining =
          _profileRefreshCooldown -
          (_profileRefreshClock.elapsed - lastAttemptElapsed);
      if (cooldownRemaining > Duration.zero) {
        _scheduleProfileRefresh(requestSession, cooldownRemaining);
        return Future.value();
      }
    }

    return _startProfileRefresh(requestSession);
  }

  Future<void> _startProfileRefresh(
    ({AuthUser user, int generation}) requestSession,
  ) {
    late final Future<void> refresh;
    _cancelDeferredProfileRefresh();
    _lastProfileRefreshAttemptElapsed = _profileRefreshClock.elapsed;
    refresh = _refreshProfileNow(requestSession).whenComplete(() {
      if (identical(_profileRefreshInFlight, refresh)) {
        _profileRefreshInFlight = null;
        _profileRefreshInFlightUserId = null;
        _profileRefreshInFlightGeneration = null;
      }
    });
    _profileRefreshInFlight = refresh;
    _profileRefreshInFlightUserId = requestSession.user.id;
    _profileRefreshInFlightGeneration = requestSession.generation;
    return refresh;
  }

  void _scheduleProfileRefresh(
    ({AuthUser user, int generation}) requestSession,
    Duration delay,
  ) {
    final timer = _profileRefreshTimer;
    if (timer != null &&
        _profileRefreshTimerUserId == requestSession.user.id &&
        _profileRefreshTimerGeneration == requestSession.generation) {
      return;
    }
    timer?.cancel();
    _profileRefreshTimerUserId = requestSession.user.id;
    _profileRefreshTimerGeneration = requestSession.generation;
    _profileRefreshTimer = Timer(delay, () {
      _profileRefreshTimer = null;
      _profileRefreshTimerUserId = null;
      _profileRefreshTimerGeneration = null;
      if (!_isCurrentAuthenticatedSession(
        requestSession.user.id,
        requestSession.generation,
      )) {
        return;
      }
      unawaited(_refreshProfileInBackground(requestSession));
    });
  }

  Future<void> _refreshProfileInBackground(
    ({AuthUser user, int generation}) requestSession,
  ) async {
    try {
      await _startProfileRefresh(requestSession);
    } on Object catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'account session',
          context: ErrorDescription(
            'while refreshing the account profile in the background',
          ),
        ),
      );
    }
  }

  Future<void> _refreshProfileNow(
    ({AuthUser user, int generation}) requestSession,
  ) async {
    try {
      final refreshed = await _requestProfile(requestSession.user.id);
      _publishProfileIfCurrent(
        requestSession.user.id,
        requestSession.generation,
        refreshed,
      );
    } on PrivateApiException catch (error) {
      if (error.statusCode == 401) {
        if (_isCurrentAuthenticatedSession(
          requestSession.user.id,
          requestSession.generation,
        )) {
          await restoreSession();
        }
        return;
      }
      if (!_isExpectedProfileFailure(error)) {
        rethrow;
      }
    } on FormatException {
      return;
    }
  }

  ({AuthUser user, int generation})? _activeAuthenticatedSession() {
    final current = _value;
    if (_disposed || current.status != AuthSessionStatus.authenticated) {
      return null;
    }
    final user = current.user;
    if (user == null) {
      return null;
    }
    return (user: user, generation: _sessionGeneration);
  }

  Future<AuthUser> _requestProfile(int ownerId) async {
    final response = await _client.getAuthenticatedWithNonceRefresh('me');
    return AuthProfilePayload.fromResponse(
      response,
      expectedUserId: ownerId,
    ).user;
  }

  void _publishProfileIfCurrent(
    int ownerId,
    int generation,
    AuthUser refreshed,
  ) {
    if (!_isCurrentAuthenticatedSession(ownerId, generation)) {
      return;
    }
    final current = _value;
    _publishState(
      AuthSessionState.authenticated(
        refreshed,
        noticeMessage: current.noticeMessage,
      ),
    );
  }

  bool _isCurrentAuthenticatedSession(int ownerId, int generation) {
    final current = _value;
    return !_disposed &&
        _sessionGeneration == generation &&
        current.status == AuthSessionStatus.authenticated &&
        current.user?.id == ownerId;
  }

  bool _isExpectedProfileFailure(PrivateApiException error) {
    final statusCode = error.statusCode ?? 0;
    return error.code == 'invalid_json' ||
        error.code == 'timeout' ||
        error.code == 'network_unavailable' ||
        error.code == 'secure_connection_failed' ||
        statusCode == 429 ||
        (statusCode >= 500 && statusCode < 600);
  }

  @override
  Future<void> logout() async {
    final user = _value.user;
    if (user == null || _value.status == AuthSessionStatus.signingOut) {
      return;
    }
    _resetProfileRefreshRequests();
    _sessionGeneration += 1;
    _publishState(AuthSessionState.signingOut(user));

    try {
      await _logoutWithNonceRefresh();
      await _completeLogout();
    } on PrivateApiException catch (error) {
      if (error.statusCode == 401) {
        await _clearSessionAfterExpiry();
        return;
      }
      _publishState(
        AuthSessionState.authenticated(
          user,
          noticeMessage: logoutMessageFor(error),
        ),
      );
    } on FormatException {
      _publishState(
        AuthSessionState.authenticated(
          user,
          noticeMessage: 'تعذر تحديث الجلسة لتسجيل الخروج.',
        ),
      );
    }
  }

  Future<void> _completeLogout() async {
    _client.clearSession();
    _persistSession = false;
    try {
      await _sessionStore.clear();
      _publishState(const AuthSessionState.guest());
    } on AuthSessionStoreException {
      _publishState(
        const AuthSessionState.guest(
          errorMessage: 'تم تسجيل الخروج، لكن تعذر تنظيف الجلسة المحفوظة.',
        ),
      );
    }
  }

  Future<void> _logoutWithNonceRefresh() async {
    try {
      await _client.postAuthenticated('auth/logout');
    } on PrivateApiException catch (error) {
      final nonceExpired =
          error.code == 'wor_reader_app_bad_nonce' ||
          error.code == 'missing_nonce';
      if (!nonceExpired) {
        rethrow;
      }

      final response = await _client.getPublic('session');
      if (response['logged_in'] != true) {
        return;
      }
      final refreshed = AuthSessionPayload.fromResponse(response);
      _client.updateNonce(refreshed.nonce);
      await _client.postAuthenticated('auth/logout');
    }
  }

  Future<String?> _persistSnapshotIfNeeded() async {
    if (!_persistSession) {
      return null;
    }
    final snapshot = _client.exportSessionSnapshot();
    if (snapshot == null) {
      throw const FormatException('Missing session credentials.');
    }
    try {
      await _sessionStore.write(snapshot);
      return null;
    } on AuthSessionStoreException {
      _persistSession = false;
      return 'تم تسجيل الدخول، لكن تعذر حفظ الجلسة على الجهاز.';
    }
  }

  Future<void> _clearSession() async {
    _client.clearSession();
    _persistSession = false;
    await _sessionStore.clear();
  }

  Future<void> _clearSessionAfterInvalidResponse() async {
    try {
      await _clearSession();
    } on AuthSessionStoreException {
      _client.clearSession();
    }
  }

  Future<void> _clearSessionAfterExpiry() async {
    try {
      await _clearSession();
      _publishState(const AuthSessionState.guest());
    } on AuthSessionStoreException {
      _publishState(
        const AuthSessionState.guest(
          errorMessage: 'انتهت الجلسة وتعذر حذف النسخة المحفوظة.',
        ),
      );
    }
  }

  void _publishState(AuthSessionState nextState) {
    if (_disposed) {
      return;
    }
    _value = nextState;
    notifyListeners();
  }

  void _cancelDeferredProfileRefresh() {
    _profileRefreshTimer?.cancel();
    _profileRefreshTimer = null;
    _profileRefreshTimerUserId = null;
    _profileRefreshTimerGeneration = null;
  }

  void _resetProfileRefreshRequests() {
    _cancelDeferredProfileRefresh();
    _lastProfileRefreshAttemptElapsed = null;
    _profileRefreshInFlight = null;
    _profileRefreshInFlightUserId = null;
    _profileRefreshInFlightGeneration = null;
  }

  @override
  void dispose() {
    _resetProfileRefreshRequests();
    _disposed = true;
    super.dispose();
  }
}
