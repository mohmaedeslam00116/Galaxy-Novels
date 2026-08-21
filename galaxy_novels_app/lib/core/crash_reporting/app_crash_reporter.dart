import 'package:flutter/foundation.dart';

abstract interface class AppCrashReporter {
  Future<void> setCollectionEnabled(bool enabled);

  Future<void> deleteUnsentReports();

  void recordFlutterError(FlutterErrorDetails details, {required bool fatal});

  void recordPlatformError(
    Object error,
    StackTrace stackTrace, {
    required bool fatal,
  });
}
