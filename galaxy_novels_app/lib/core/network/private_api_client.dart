import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import 'dart_io_private_request_sender.dart';
import 'private_api_types.dart';

export 'private_api_types.dart';

class PrivateApiClient {
  PrivateApiClient({
    required AppConfig config,
    PrivateRequestSender? requestSender,
  }) : _config = config,
       _requestSender = requestSender ?? sendPrivateRequestWithDartIo;

  static const apiPath = '/wp-json/wor-reader-app/v1/';

  final AppConfig _config;
  final PrivateRequestSender _requestSender;

  String? _accessToken;
  String _tokenType = 'Bearer';
  DateTime? _tokenExpiresAt;

  String? get accessToken => _accessToken;

  PrivateSessionSnapshot? exportSessionSnapshot() {
    final accessToken = _accessToken;
    if (accessToken == null) {
      return null;
    }
    return PrivateSessionSnapshot(
      accessToken: accessToken,
      tokenType: _tokenType,
      expiresAt: _tokenExpiresAt,
    );
  }

  void importSessionSnapshot(PrivateSessionSnapshot snapshot) {
    clearSession();
    updateAccessToken(
      snapshot.accessToken,
      tokenType: snapshot.tokenType,
      expiresAt: snapshot.expiresAt,
    );
  }

  Future<Map<String, dynamic>> getPublic(String path) => _request('GET', path);

  Future<Map<String, dynamic>> getAuthenticated(String path) async {
    return _request('GET', path, requireAuth: true);
  }

  Future<Map<String, dynamic>> postPublic(
    String path, {
    Map<String, Object?>? body,
  }) {
    return _request('POST', path, body: body);
  }

  Future<Map<String, dynamic>> postAuthenticated(
    String path, {
    Map<String, Object?>? body,
  }) async {
    return _request('POST', path, body: body, requireAuth: true);
  }

  void updateAccessToken(
    Object? value, {
    Object? tokenType,
    DateTime? expiresAt,
  }) {
    final next = _cleanHeaderValue(value);
    if (next == null) {
      _accessToken = null;
      _tokenType = 'Bearer';
      _tokenExpiresAt = null;
      return;
    }
    _accessToken = next;
    _tokenType = _cleanHeaderValue(tokenType) ?? 'Bearer';
    _tokenExpiresAt = expiresAt;
  }

  void clearSession() {
    updateAccessToken(null);
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, Object?>? body,
    bool requireAuth = false,
  }) async {
    final uri = _resolveEndpoint(path);
    final encodedBody = body == null ? null : jsonEncode(body);
    final request = PrivateRawRequest(
      method: method,
      uri: uri,
      headers: _headersFor(requireAuth: requireAuth, body: encodedBody),
      body: encodedBody,
    );
    _privateApiLog(
      'request ${request.method} ${uri.path} '
      'bearer=${request.headers.containsKey('Authorization')} '
      'tokenFallback=${request.headers.containsKey('X-Wor-App-Token')} '
      'body=${encodedBody != null}',
    );
    final response = await _requestSender(request);
    final responseJson = _decodeResponse(response);
    _privateApiLog(
      'response ${request.method} ${uri.path} '
      'status=${response.statusCode} '
      'code=${responseJson['code'] ?? '-'} '
      'loggedIn=${responseJson['logged_in'] ?? '-'} '
      'accessToken=${responseJson.containsKey('access_token')} '
      'setCookie=${response.setCookieHeaders.length}',
    );
    _throwIfFailed(response, responseJson);
    _refreshAccessToken(responseJson);
    return responseJson;
  }

  Map<String, String> _headersFor({
    required bool requireAuth,
    required String? body,
  }) {
    final token = requireAuth ? _requiredAccessToken() : _accessToken;
    final headers = <String, String>{
      'Accept': 'application/json',
      'User-Agent': _config.userAgent,
      'Cache-Control': 'no-store',
      'Pragma': 'no-cache',
    };
    if (token != null) {
      headers['Authorization'] = '${_authorizationScheme()} $token';
      headers['X-Wor-App-Token'] = token;
    }
    if (body != null) {
      headers['Content-Type'] = 'application/json; charset=utf-8';
    }
    return headers;
  }

  void _throwIfFailed(
    PrivateRawResponse response,
    Map<String, dynamic> responseJson,
  ) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw PrivateApiException(
        statusCode: response.statusCode,
        code: responseJson['code']?.toString(),
        message: _errorMessage(responseJson, response.statusCode),
      );
    }
  }

  void _refreshAccessToken(Map<String, dynamic> responseJson) {
    if (!responseJson.containsKey('access_token')) {
      return;
    }
    updateAccessToken(
      responseJson['access_token'],
      tokenType: responseJson['token_type'],
      expiresAt: DateTime.tryParse(
        responseJson['expires_at']?.toString() ?? '',
      ),
    );
  }

  String _requiredAccessToken() {
    final token = _accessToken;
    if (token == null) {
      throw const PrivateApiException(
        code: 'missing_access_token',
        message: 'The authenticated request requires an app access token.',
      );
    }
    return token;
  }

  String _authorizationScheme() {
    return _tokenType.toLowerCase() == 'bearer' ? 'Bearer' : _tokenType;
  }

  Uri _resolveEndpoint(String path) {
    final apiBase = _config.resolve(apiPath);
    final relative = path.startsWith('/') ? path.substring(1) : path;
    final uri = apiBase.resolve(relative);

    if (uri.scheme != 'https' ||
        uri.origin != apiBase.origin ||
        uri.userInfo.isNotEmpty ||
        !uri.path.startsWith(apiBase.path)) {
      throw const PrivateApiException(
        code: 'unsafe_endpoint',
        message: 'Private API requests must use the configured HTTPS host.',
      );
    }
    return uri;
  }
}

String? _cleanHeaderValue(Object? value) {
  final text = value?.toString().trim() ?? '';
  if (text.isEmpty || text.contains('\r') || text.contains('\n')) {
    return null;
  }
  return text;
}

Map<String, dynamic> _decodeResponse(PrivateRawResponse response) {
  if (response.body.trim().isEmpty) {
    return <String, dynamic>{};
  }

  try {
    final value = jsonDecode(response.body);
    if (value is Map<String, dynamic>) {
      return value;
    }
  } on FormatException {
    // Converted below into a stable API error without exposing response data.
  }

  throw PrivateApiException(
    statusCode: response.statusCode,
    code: 'invalid_json',
    message: 'The private API returned an invalid JSON object.',
  );
}

String _errorMessage(Map<String, dynamic> json, int statusCode) {
  final message = json['message']?.toString().trim() ?? '';
  return message.isNotEmpty
      ? message
      : 'Private API request failed ($statusCode).';
}

void _privateApiLog(String message) {
  assert(() {
    debugPrint('[GalaxyAuthApi] $message');
    return true;
  }());
}
