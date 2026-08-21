import 'dart:async';
import 'dart:io';

abstract interface class AppRecoverableException implements Exception {}

bool isFatalAppError(Object error) {
  return error is! AppRecoverableException &&
      error is! TimeoutException &&
      error is! SocketException &&
      error is! HttpException;
}
