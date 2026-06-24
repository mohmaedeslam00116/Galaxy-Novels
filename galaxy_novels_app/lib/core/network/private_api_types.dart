typedef PrivateRequestSender =
    Future<PrivateRawResponse> Function(PrivateRawRequest request);

class PrivateSessionSnapshot {
  const PrivateSessionSnapshot({
    required this.nonce,
    required this.cookieHeader,
  });

  final String nonce;
  final String cookieHeader;
}

class PrivateRawRequest {
  PrivateRawRequest({
    required this.method,
    required this.uri,
    required Map<String, String> headers,
    required this.body,
  }) : headers = Map.unmodifiable(headers);

  final String method;
  final Uri uri;
  final Map<String, String> headers;
  final String? body;
}

class PrivateRawResponse {
  const PrivateRawResponse({
    required this.statusCode,
    required this.body,
    this.setCookieHeaders = const [],
  });

  final int statusCode;
  final String body;
  final List<String> setCookieHeaders;
}

class PrivateApiException implements Exception {
  const PrivateApiException({
    required this.message,
    this.code,
    this.statusCode,
  });

  final String message;
  final String? code;
  final int? statusCode;

  @override
  String toString() => 'PrivateApiException($code, $statusCode): $message';
}
