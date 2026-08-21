import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/core/crash_reporting/app_crash_reporter.dart';
import 'package:galaxy_novels_app/core/crash_reporting/app_recoverable_exception.dart';
import 'package:galaxy_novels_app/core/crash_reporting/crash_reporting_bootstrap.dart';

void main() {
  test('crash collection is disabled only for debug builds', () {
    expect(crashCollectionEnabled(AppBuildMode.debug), isFalse);
    expect(crashCollectionEnabled(AppBuildMode.profile), isTrue);
    expect(crashCollectionEnabled(AppBuildMode.release), isTrue);
    expect(currentAppBuildMode, AppBuildMode.debug);
  });

  test(
    'debug mode disables collection without replacing error handlers',
    () async {
      final reporter = _RecordingCrashReporter();
      FlutterExceptionHandler? flutterHandler;
      PlatformExceptionHandler? platformHandler;
      final bootstrap = CrashReportingBootstrap(
        reporter: reporter,
        installFlutterHandler: (handler) => flutterHandler = handler,
        installPlatformHandler: (handler) => platformHandler = handler,
      );

      await bootstrap.configure(AppBuildMode.debug);

      expect(reporter.collectionValues, [false]);
      expect(reporter.deletedUnsentReports, 1);
      expect(flutterHandler, isNull);
      expect(platformHandler, isNull);
    },
  );

  test('profile mode forwards programming errors as fatal', () async {
    final reporter = _RecordingCrashReporter();
    FlutterExceptionHandler? flutterHandler;
    PlatformExceptionHandler? platformHandler;
    final bootstrap = CrashReportingBootstrap(
      reporter: reporter,
      installFlutterHandler: (handler) => flutterHandler = handler,
      installPlatformHandler: (handler) => platformHandler = handler,
    );

    await bootstrap.configure(AppBuildMode.profile);
    final flutterDetails = FlutterErrorDetails(
      exception: StateError('flutter failure'),
    );
    flutterHandler!(flutterDetails);
    final platformError = StateError('platform failure');
    final platformStack = StackTrace.current;
    final handled = platformHandler!(platformError, platformStack);

    expect(reporter.collectionValues, [true]);
    expect(reporter.flutterErrors, [(flutterDetails, true)]);
    expect(reporter.platformErrors, [(platformError, platformStack, true)]);
    expect(handled, isTrue);
  });

  test('temporary and typed recoverable errors are non-fatal', () async {
    final reporter = _RecordingCrashReporter();
    FlutterExceptionHandler? flutterHandler;
    PlatformExceptionHandler? platformHandler;
    final bootstrap = CrashReportingBootstrap(
      reporter: reporter,
      installFlutterHandler: (handler) => flutterHandler = handler,
      installPlatformHandler: (handler) => platformHandler = handler,
    );

    await bootstrap.configure(AppBuildMode.release);
    final socketDetails = FlutterErrorDetails(
      exception: const SocketException('offline'),
    );
    final httpDetails = FlutterErrorDetails(
      exception: const HttpException('connection closed'),
    );
    flutterHandler!(socketDetails);
    flutterHandler!(httpDetails);
    final timeout = TimeoutException('request timed out');
    final recoverable = const _RecoverableFailure();
    platformHandler!(timeout, StackTrace.current);
    platformHandler!(recoverable, StackTrace.current);

    expect(reporter.flutterErrors, [
      (socketDetails, false),
      (httpDetails, false),
    ]);
    expect(reporter.platformErrors.map((entry) => (entry.$1, entry.$3)), [
      (timeout, false),
      (recoverable, false),
    ]);
  });

  test('unexpected file-system failures remain fatal', () async {
    final reporter = _RecordingCrashReporter();
    PlatformExceptionHandler? platformHandler;
    final bootstrap = CrashReportingBootstrap(
      reporter: reporter,
      installFlutterHandler: (_) {},
      installPlatformHandler: (handler) => platformHandler = handler,
    );

    await bootstrap.configure(AppBuildMode.release);
    final failure = const FileSystemException(
      'unexpected local storage failure',
      '/data/user/0/com.galaxynovels.app/files/chapter.bin',
    );
    final stackTrace = StackTrace.current;
    platformHandler!(failure, stackTrace);

    expect(reporter.platformErrors, [(failure, stackTrace, true)]);
  });

  test(
    'reporting setup failure does not interrupt application startup',
    () async {
      final bootstrap = CrashReportingBootstrap(
        reporter: _FailingCrashReporter(),
        installFlutterHandler: (_) => fail('must not install Flutter handler'),
        installPlatformHandler: (_) =>
            fail('must not install platform handler'),
      );

      await expectLater(bootstrap.configure(AppBuildMode.release), completes);
    },
  );
}

class _RecordingCrashReporter implements AppCrashReporter {
  final List<bool> collectionValues = [];
  final List<(FlutterErrorDetails, bool)> flutterErrors = [];
  final List<(Object, StackTrace, bool)> platformErrors = [];
  int deletedUnsentReports = 0;

  @override
  Future<void> deleteUnsentReports() async {
    deletedUnsentReports += 1;
  }

  @override
  Future<void> setCollectionEnabled(bool enabled) async {
    collectionValues.add(enabled);
  }

  @override
  void recordFlutterError(FlutterErrorDetails details, {required bool fatal}) {
    flutterErrors.add((details, fatal));
  }

  @override
  void recordPlatformError(
    Object error,
    StackTrace stackTrace, {
    required bool fatal,
  }) {
    platformErrors.add((error, stackTrace, fatal));
  }
}

class _FailingCrashReporter implements AppCrashReporter {
  @override
  Future<void> deleteUnsentReports() async {}

  @override
  Future<void> setCollectionEnabled(bool enabled) {
    throw Exception('Crashlytics unavailable');
  }

  @override
  void recordFlutterError(FlutterErrorDetails details, {required bool fatal}) {}

  @override
  void recordPlatformError(
    Object error,
    StackTrace stackTrace, {
    required bool fatal,
  }) {}
}

class _RecoverableFailure implements AppRecoverableException {
  const _RecoverableFailure();
}
