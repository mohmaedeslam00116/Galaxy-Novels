import 'dart:convert';
import 'dart:io';

import '../config/app_config.dart';
import 'dart_io_private_request_sender.dart';
import 'private_api_types.dart';
import 'session_cookie_store.dart';

export 'private_api_types.dart';

class PrivateApiClient {
  PrivateApiClient({
    required AppConfig config,
    SessionCookieStore? cookieStore,
    PrivateRequestSender? requestSender,
  }) : _config = config,
       _cookieStore = cookieStore ?? InMemorySessionCookieStore(),
       _requestSender = requestSender ?? sendPrivateRequestWithDartIo;

  static const apiPath = '/wp-json/wor-reader-app/v1/';

  final AppConfig _config;
  final SessionCookieStore _cookieStore;
  final PrivateRequestSender _requestSender;

  String? _nonce;

  String? get nonce => _nonce;

  PrivateSessionSnapshot? exportSessionSnapshot() {
    final nonce = _nonce;
    if (nonce == null) {
      return null;
    }
    final cookieHeader = _cookieStore.headerFor(_resolveEndpoint('session'));
    if (cookieHeader == null || cookieHeader.isEmpty) {
      return null;
    }
    return PrivateSessionSnapshot(nonce: nonce, cookieHeader: cookieHeader);
  }

  void importSessionSnapshot(PrivateSessionSnapshot snapshot) {
    clearSession();
    final endpoint = _resolveEndpoint('session');
    _cookieStore.restoreRequestHeader(endpoint, snapshot.cookieHeader);
    updateNonce(snapshot.nonce);
  }

  Future<Map<String, dynamic>> getPublic(String path) => _request('GET', path);

  Future<Map<String, dynamic>> getAuthenticated(String path) async {
    return _request('GET', path, nonce: _requiredNonce());
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
    return _request('POST', path, body: body, nonce: _requiredNonce());
  }

  void updateNonce(Object? value) {
    final next = value?.toString().trim() ?? '';
    _nonce = next.isEmpty ? null : next;
  }

  void clearSession() {
    _nonce = null;
    _cookieStore.clear();
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, Object?>? body,
    String? nonce,
  }) async {
    final uri = _resolveEndpoint(path);
    final encodedBody = body == null ? null : jsonEncode(body);
    final request = PrivateRawRequest(
      method: method,
      uri: uri,
      headers: _headersFor(uri, nonce: nonce, body: encodedBody),
      body: encodedBody,
    );
    final response = await _requestSender(request);
    _cookieStore.absorb(uri, response.setCookieHeaders);
    final responseJson = _decodeResponse(response);
    _throwIfFailed(response, responseJson);
    _refreshNonce(responseJson);
    return responseJson;
  }

  Map<String, String> _headersFor(
    Uri uri, {
    required String? nonce,
    required String? body,
  }) {
    final headers = <String, String>{
      'Accept': 'application/json',
      'User-Agent': _config.userAgent,
      'Cache-Control': 'no-store',
      'Pragma': 'no-cache',
    };
    final cookieHeader = _cookieStore.headerFor(uri);
    if (cookieHeader != null) {
      headers['Cookie'] = cookieHeader;
    }
    if (nonce != null) {
      headers['X-WP-Nonce'] = nonce;
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
      if (response.statusCode == HttpStatus.unauthorized ||
          response.statusCode == HttpStatus.forbidden) {
        _nonce = null;
      }
      throw PrivateApiException(
        statusCode: response.statusCode,
        code: responseJson['code']?.toString(),
        message: _errorMessage(responseJson, response.statusCode),
      );
    }
  }

  void _refreshNonce(Map<String, dynamic> responseJson) {
    if (responseJson.containsKey('nonce')) {
      updateNonce(responseJson['nonce']);
    }
  }

  String _requiredNonce() {
    final nonce = _nonce;
    if (nonce == null) {
      throw const PrivateApiException(
        code: 'missing_nonce',
        message: 'The authenticated request requires a session nonce.',
      );
    }
    return nonce;
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
