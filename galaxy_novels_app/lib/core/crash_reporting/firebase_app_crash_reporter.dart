import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import 'app_crash_reporter.dart';

class FirebaseAppCrashReporter implements AppCrashReporter {
  FirebaseAppCrashReporter({FirebaseCrashlytics? crashlytics})
    : _crashlytics = crashlytics ?? FirebaseCrashlytics.instance;

  final FirebaseCrashlytics _crashlytics;

  @override
  Future<void> setCollectionEnabled(bool enabled) {
    return _crashlytics.setCrashlyticsCollectionEnabled(enabled);
  }

  @override
  Future<void> deleteUnsentReports() {
    return _crashlytics.deleteUnsentReports();
  }

  @override
  void recordFlutterError(FlutterErrorDetails details, {required bool fatal}) {
    unawaited(
      _record(
        () => fatal
            ? _crashlytics.recordFlutterFatalError(details)
            : _crashlytics.recordFlutterError(details),
      ),
    );
  }

  @override
  void recordPlatformError(
    Object error,
    StackTrace stackTrace, {
    required bool fatal,
  }) {
    unawaited(
      _record(() => _crashlytics.recordError(error, stackTrace, fatal: fatal)),
    );
  }

  Future<void> _record(Future<void> Function() sendReport) async {
    try {
      await sendReport();
    } on Exception {
      // A failed report must not create a second unhandled application error.
    }
  }
}
