import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:workmanager/workmanager.dart';

import 'app/galaxy_novels_app.dart';
import 'core/crash_reporting/crash_reporting_bootstrap.dart';
import 'core/crash_reporting/firebase_app_crash_reporter.dart';
import 'features/downloads/data/download_background_entrypoint.dart';
import 'features/reader/application/reader_speech_controller.dart';
import 'features/reader/data/reader_speech_audio_handler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ReaderSpeechController? readerSpeechController;
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    await Firebase.initializeApp();
    await CrashReportingBootstrap(
      reporter: FirebaseAppCrashReporter(),
      installFlutterHandler: (handler) => FlutterError.onError = handler,
      installPlatformHandler: (handler) {
        PlatformDispatcher.instance.onError = handler;
      },
    ).configure(currentAppBuildMode);
    await Workmanager().initialize(downloadBackgroundDispatcher);
    try {
      readerSpeechController = await initializeReaderSpeechAudioHandler();
    } on MissingPluginException catch (error, stackTrace) {
      _reportSpeechInitializationFailure(error, stackTrace);
    } on PlatformException catch (error, stackTrace) {
      _reportSpeechInitializationFailure(error, stackTrace);
    } on Exception catch (error, stackTrace) {
      _reportSpeechInitializationFailure(error, stackTrace);
    }
  }
  runApp(
    GalaxyNovelsApp(
      readerSpeechController: readerSpeechController,
      splashDuration: const Duration(milliseconds: 1200),
    ),
  );
}

void _reportSpeechInitializationFailure(Object error, StackTrace stackTrace) {
  FlutterError.reportError(
    FlutterErrorDetails(
      exception: error,
      stack: stackTrace,
      library: 'reader speech initialization',
      context: ErrorDescription(
        'while initializing Android text-to-speech playback',
      ),
    ),
  );
}
