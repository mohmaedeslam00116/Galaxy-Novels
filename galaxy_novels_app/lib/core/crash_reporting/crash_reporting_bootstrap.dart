import 'package:flutter/foundation.dart';

import 'app_crash_reporter.dart';
import 'app_recoverable_exception.dart';

enum AppBuildMode { debug, profile, release }

typedef PlatformExceptionHandler =
    bool Function(Object error, StackTrace stackTrace);
typedef FlutterHandlerInstaller =
    void Function(FlutterExceptionHandler handler);
typedef PlatformHandlerInstaller =
    void Function(PlatformExceptionHandler handler);

AppBuildMode get currentAppBuildMode {
  if (kDebugMode) return AppBuildMode.debug;
  if (kProfileMode) return AppBuildMode.profile;
  return AppBuildMode.release;
}

bool crashCollectionEnabled(AppBuildMode buildMode) {
  return buildMode != AppBuildMode.debug;
}

class CrashReportingBootstrap {
  const CrashReportingBootstrap({
    required AppCrashReporter reporter,
    required FlutterHandlerInstaller installFlutterHandler,
    required PlatformHandlerInstaller installPlatformHandler,
  }) : _reporter = reporter,
       _installFlutterHandler = installFlutterHandler,
       _installPlatformHandler = installPlatformHandler;

  final AppCrashReporter _reporter;
  final FlutterHandlerInstaller _installFlutterHandler;
  final PlatformHandlerInstaller _installPlatformHandler;

  Future<void> configure(AppBuildMode buildMode) async {
    final collectionEnabled = crashCollectionEnabled(buildMode);
    try {
      await _reporter.setCollectionEnabled(collectionEnabled);
      if (!collectionEnabled) {
        await _reporter.deleteUnsentReports();
        return;
      }
    } on Exception {
      // Crash reporting must never prevent the application from starting.
      return;
    }

    _installFlutterHandler((details) {
      _reporter.recordFlutterError(
        details,
        fatal: isFatalAppError(details.exception),
      );
    });
    _installPlatformHandler((error, stackTrace) {
      _reporter.recordPlatformError(
        error,
        stackTrace,
        fatal: isFatalAppError(error),
      );
      return true;
    });
  }
}
