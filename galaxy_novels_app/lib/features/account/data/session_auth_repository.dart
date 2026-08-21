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
    _authLog('restore:start');
    _resetProfileRefreshRequests();
    _sessionGeneration += 1;
    _publishState(const AuthSessionState.restoring());
    _client.clearSession();

    try {
      final storedSession = await _sessionStore.read();
      _persistSession = storedSession != null;
      _authLog('load-server-session stored=${storedSession != null}');
      if (_isLocallyExpired(storedSession)) {
        _authLog('restore:locally-expired');
        await _clearSessionAfterExpiry();
        return;
      }
      final session = await _loadServerSession(storedSession);
      if (session == null) {
        _authLog('restore:no-server-session');
        await _clearSession();
        _publishState(const AuthSessionState.guest());
        return;
      }
      final notice = await _persistSnapshotIfNeeded();
      _publishState(
        AuthSessionState.authenticated(session.user, noticeMessage: notice),
      );
      _authLog('restore:authenticated user=${session.user.id}');
    } on PrivateApiException catch (error) {
      _authLog(
        'restore:api-error status=${error.statusCode} code=${error.code}',
      );
      if (_isExpiredSessionFailure(error)) {
        await _clearSessionAfterExpiry();
        return;
      }
      _publishState(AuthSessionState.failure(restoreMessageFor(error)));
    } on AuthSessionStoreException {
      _authLog('restore:store-error');
      _publishState(
        const AuthSessionState.failure(
          'تعذر الوصول إلى الجلسة المحفوظة على الجهاز.',
        ),
      );
    } on FormatException {
      _authLog('restore:format-error');
      await _clearSessionAfterInvalidResponse();
      _publishState(
        const AuthSessionState.failure(
          'تعذر قراءة بيانات الحساب. حاول مرة أخرى.',
        ),
      );
    }
  }

  Future<AuthSessionPayload?> _loadServerSession(
    PrivateSessionSnapshot? storedSession,
  ) async {
    if (storedSession != null) {
      _client.importSessionSnapshot(storedSession);
    }

    final response = await _client.getPublic('session');
    if (response['logged_in'] != true) {
      return null;
    }
    final session = AuthSessionPayload.fromResponse(response);
    _applySessionAccessToken(session, requireToken: false);
    return session;
  }

  bool _isLocallyExpired(PrivateSessionSnapshot? snapshot) {
    final expiresAt = snapshot?.expiresAt;
    return expiresAt != null &&
        !expiresAt.toUtc().isAfter(DateTime.now().toUtc());
  }

  bool _isExpiredSessionFailure(PrivateApiException error) {
    final code = error.code?.trim().toLowerCase();
    return error.statusCode == 401 ||
        error.statusCode == 403 ||
        code == 'wor_reader_app_login_required';
  }

  @override
  Future<void> login(LoginCredentials credentials) async {
    if (_value.status == AuthSessionStatus.authenticating) {
      return;
    }
    _authLog('login:start remember=${credentials.rememberSession}');
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
      _authLog(
        'login:authenticated user=${session.user.id} '
        'persist=$_persistSession notice=${notice != null}',
      );
    } on PrivateApiException catch (error) {
      _authLog('login:api-error status=${error.statusCode} code=${error.code}');
      _client.clearSession();
      _publishState(
        AuthSessionState.guest(errorMessage: loginMessageFor(error)),
      );
    } on AuthSessionStoreException {
      _authLog('login:store-error');
      _publishState(
        const AuthSessionState.guest(
          errorMessage: 'تعذر استخدام التخزين الآمن على هذا الجهاز.',
        ),
      );
    } on FormatException {
      _authLog('login:format-error');
      _client.clearSession();
      _publishState(
        const AuthSessionState.guest(
          errorMessage: 'أعاد الموقع بيانات حساب غير مكتملة.',
        ),
      );
    }
  }

  @override
  Future<void> register(RegisterCredentials credentials) async {
    if (_value.status == AuthSessionStatus.authenticating) {
      return;
    }
    _authLog('register:start remember=${credentials.rememberSession}');
    _resetProfileRefreshRequests();
    _sessionGeneration += 1;
    if (_invalidRegisterCredentials(credentials)) {
      _publishState(
        const AuthSessionState.guest(
          errorMessage: 'أكمل بيانات إنشاء الحساب بشكل صحيح.',
        ),
      );
      return;
    }

    _publishState(const AuthSessionState.authenticating());
    _client.clearSession();
    _persistSession = false;

    try {
      final session = await _requestRegister(credentials);
      final notice = await _persistSnapshotIfNeeded();
      _publishState(
        AuthSessionState.authenticated(session.user, noticeMessage: notice),
      );
      _authLog(
        'register:authenticated user=${session.user.id} '
        'persist=$_persistSession notice=${notice != null}',
      );
    } on PrivateApiException catch (error) {
      _authLog(
        'register:api-error status=${error.statusCode} code=${error.code}',
      );
      _client.clearSession();
      _publishState(
        AuthSessionState.guest(errorMessage: registerMessageFor(error)),
      );
    } on AuthSessionStoreException {
      _authLog('register:store-error');
      _publishState(
        const AuthSessionState.guest(
          errorMessage: 'تعذر استخدام التخزين الآمن على هذا الجهاز.',
        ),
      );
    } on FormatException {
      _authLog('register:format-error');
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
    _authLog('login:cleared-stored-session');
    final response = await _client.postPublic(
      'auth/login',
      body: {
        'username': credentials.username.trim(),
        'password': credentials.password,
        'remember': credentials.rememberSession,
      },
    );
    final session = AuthSessionPayload.fromResponse(response);
    _applySessionAccessToken(session, requireToken: true);
    _persistSession = credentials.rememberSession;
    return session;
  }

  Future<AuthSessionPayload> _requestRegister(
    RegisterCredentials credentials,
  ) async {
    await _sessionStore.clear();
    _authLog('register:cleared-stored-session');
    final turnstileResponse = credentials.cfTurnstileResponse?.trim() ?? '';
    final response = await _client.postPublic(
      'auth/register',
      body: {
        'username': credentials.username.trim(),
        'email': credentials.email.trim(),
        'password': credentials.password,
        'display_name': credentials.displayName.trim(),
        'device_id': credentials.deviceId.trim(),
        'device_label': credentials.deviceLabel.trim(),
        if (turnstileResponse.isNotEmpty)
          'cf_turnstile_response': turnstileResponse,
      },
    );
    final session = AuthSessionPayload.fromResponse(response);
    _applySessionAccessToken(session, requireToken: true);
    _persistSession = credentials.rememberSession;
    return session;
  }

  bool _invalidRegisterCredentials(RegisterCredentials credentials) {
    return credentials.username.trim().isEmpty ||
        credentials.email.trim().isEmpty ||
        !credentials.email.contains('@') ||
        credentials.password.isEmpty ||
        credentials.displayName.trim().isEmpty ||
        credentials.deviceId.trim().isEmpty ||
        credentials.deviceLabel.trim().isEmpty;
  }

  void _applySessionAccessToken(
    AuthSessionPayload session, {
    required bool requireToken,
  }) {
    final accessToken = session.accessToken;
    if (accessToken == null) {
      if (requireToken) {
        throw const FormatException('Missing app access token.');
      }
      return;
    }
    _client.updateAccessToken(
      accessToken,
      tokenType: session.tokenType,
      expiresAt: session.expiresAt,
    );
  }

  @override
  Future<void> refreshProfile() {
    final requestSession = _activeAuthenticatedSession();
    if (requestSession == null) {
      _authLog('refresh:skipped-no-auth-session');
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
        _authLog(
          'refresh:scheduled-after-cooldown user=${requestSession.user.id}',
        );
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
      _authLog('refresh:start user=${requestSession.user.id}');
      final refreshed = await _requestProfile(requestSession.user.id);
      _publishProfileIfCurrent(
        requestSession.user.id,
        requestSession.generation,
        refreshed,
      );
      _authLog('refresh:success user=${requestSession.user.id}');
    } on PrivateApiException catch (error) {
      _authLog(
        'refresh:api-error user=${requestSession.user.id} '
        'status=${error.statusCode} code=${error.code}',
      );
      if (!_isExpectedProfileFailure(error)) {
        rethrow;
      }
    } on FormatException {
      _authLog('refresh:format-error user=${requestSession.user.id}');
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
    final response = await _client.getAuthenticated('me');
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
        statusCode == 401 ||
        statusCode == 403 ||
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

    final remoteLogout = _revokeRemoteSessionBestEffort();
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
    unawaited(remoteLogout);
  }

  Future<void> _revokeRemoteSessionBestEffort() async {
    try {
      await _client.postAuthenticated('auth/logout');
    } on PrivateApiException {
      // Local logout is authoritative.
    } on FormatException {
      // Local logout is authoritative.
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
    _authLog('state ${_value.status.name}->${nextState.status.name}');
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

void _authLog(String message) {
  assert(() {
    debugPrint('[GalaxyAuth] $message');
    return true;
  }());
}
