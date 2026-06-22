import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'private_api_types.dart';

Future<PrivateRawResponse> sendPrivateRequestWithDartIo(
  PrivateRawRequest outgoing,
) async {
  const timeout = Duration(seconds: 20);
  final client = HttpClient()..connectionTimeout = timeout;

  try {
    return await _performHttpRequest(client, outgoing, timeout);
  } on TimeoutException {
    throw const PrivateApiException(
      code: 'timeout',
      message: 'Private API request timed out.',
    );
  } on SocketException {
    throw const PrivateApiException(
      code: 'network_unavailable',
      message: 'Private API is unavailable.',
    );
  } on HandshakeException {
    throw const PrivateApiException(
      code: 'secure_connection_failed',
      message: 'Private API secure connection failed.',
    );
  } on HttpException {
    throw const PrivateApiException(
      code: 'network_unavailable',
      message: 'Private API request failed.',
    );
  } finally {
    client.close(force: true);
  }
}

Future<PrivateRawResponse> _performHttpRequest(
  HttpClient client,
  PrivateRawRequest outgoing,
  Duration timeout,
) async {
  final request = await client
      .openUrl(outgoing.method, outgoing.uri)
      .timeout(timeout);
  request.followRedirects = false;
  outgoing.headers.forEach(request.headers.set);
  if (outgoing.body != null) {
    request.write(outgoing.body);
  }

  final response = await request.close().timeout(timeout);
  final responseBody = await response
      .transform(utf8.decoder)
      .join()
      .timeout(timeout);
  return PrivateRawResponse(
    statusCode: response.statusCode,
    body: responseBody,
    setCookieHeaders: response.headers[HttpHeaders.setCookieHeader] ?? const [],
  );
}
