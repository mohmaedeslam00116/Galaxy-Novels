import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/features/reader/application/reader_speech_controller.dart';
import 'package:galaxy_novels_app/features/reader/data/flutter_reader_text_to_speech_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Android voice metadata is converted without exposing chapter text', () {
    final voice = readerSpeechVoiceFromAndroid(
      engineId: 'com.google.android.tts',
      metadata: const {
        'name': 'ar-xa-x-ard-local',
        'locale': 'ar-XA',
        'quality': 'very high',
        'latency': 'low',
        'network_required': '0',
      },
    );

    expect(voice.engineId, 'com.google.android.tts');
    expect(voice.name, 'ar-xa-x-ard-local');
    expect(voice.locale, 'ar-XA');
    expect(voice.quality, 500);
    expect(voice.latency, 200);
    expect(voice.networkRequired, isFalse);
  });

  test('network voices and numeric engine metadata are supported', () {
    final voice = readerSpeechVoiceFromAndroid(
      engineId: 'third.party.tts',
      metadata: const {
        'name': 'arabic-online',
        'locale': 'ar_EG',
        'quality': 400,
        'latency': 100,
        'network_required': 1,
      },
    );

    expect(voice.quality, 400);
    expect(voice.latency, 100);
    expect(voice.networkRequired, isTrue);
  });

  test('reader rate multiplier maps around the platform normal rate', () {
    expect(
      readerSpeechPlatformRate(0.5, minimum: 0.2, normal: 0.5, maximum: 1.0),
      0.2,
    );
    expect(
      readerSpeechPlatformRate(1, minimum: 0.2, normal: 0.5, maximum: 1.0),
      0.5,
    );
    expect(
      readerSpeechPlatformRate(1.5, minimum: 0.2, normal: 0.5, maximum: 1.0),
      0.75,
    );
    expect(
      readerSpeechPlatformRate(2, minimum: 0.2, normal: 0.5, maximum: 1.0),
      1.0,
    );
  });

  test('discovers Arabic voices across installed Android engines', () async {
    const channel = MethodChannel('flutter_tts');
    var activeEngine = 'engine.default';
    final selectedEngines = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          switch (call.method) {
            case 'awaitSpeakCompletion':
            case 'setQueueMode':
              return 1;
            case 'getSpeechRateValidRange':
              return {
                'min': 0.2,
                'normal': 0.5,
                'max': 1.0,
                'platform': 'android',
              };
            case 'getDefaultEngine':
              return 'engine.default';
            case 'getEngines':
              return ['engine.default', 'engine.extra'];
            case 'setEngine':
              activeEngine = call.arguments as String;
              selectedEngines.add(activeEngine);
              return 1;
            case 'getVoices':
              return [
                {
                  'name': '$activeEngine-arabic',
                  'locale': 'ar-EG',
                  'quality': 'high',
                  'latency': 'normal',
                  'network_required': '0',
                },
              ];
          }
          return 1;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );

    final engine = FlutterReaderTextToSpeechEngine();
    final voices = await engine.discoverVoices();

    expect(voices.map((voice) => voice.engineId), [
      'engine.default',
      'engine.extra',
    ]);
    expect(selectedEngines.last, 'engine.default');
  });

  test('speech progress completes without retaining the spoken text', () async {
    const channel = MethodChannel('flutter_tts');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          return switch (call.method) {
            'getSpeechRateValidRange' => {
              'min': 0.2,
              'normal': 0.5,
              'max': 1.0,
              'platform': 'android',
            },
            'getDefaultEngine' => 'engine.default',
            _ => 1,
          };
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );
    final engine = FlutterReaderTextToSpeechEngine();
    final progress = <ReaderSpeechProgress>[];
    final subscription = engine.progress.listen(progress.add);
    final speech = engine.speak('نص خاص لا ينبغي تخزينه');
    await Future<void>.delayed(Duration.zero);

    await _sendTtsCallback('speak.onProgress', {
      'text': 'نص خاص لا ينبغي تخزينه',
      'start': 0,
      'end': 2,
      'word': 'نص',
    });
    await _sendTtsCallback('speak.onComplete', null);
    await speech;

    expect(progress.single.start, 0);
    expect(progress.single.end, 2);
    await subscription.cancel();
  });

  test('stopping active speech reports an interruption', () async {
    const channel = MethodChannel('flutter_tts');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          return switch (call.method) {
            'getSpeechRateValidRange' => {
              'min': 0.2,
              'normal': 0.5,
              'max': 1.0,
              'platform': 'android',
            },
            'getDefaultEngine' => 'engine.default',
            _ => 1,
          };
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );
    final engine = FlutterReaderTextToSpeechEngine();
    final speechExpectation = expectLater(
      engine.speak('نص الاختبار'),
      throwsA(isA<ReaderSpeechInterruptedException>()),
    );
    await Future<void>.delayed(Duration.zero);

    final stop = engine.stop();
    await Future<void>.delayed(Duration.zero);
    await _sendTtsCallback('speak.onCancel', null);
    await stop;

    await speechExpectation;
  });

  test('unsolicited platform cancellation is an engine failure', () async {
    const channel = MethodChannel('flutter_tts');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          return switch (call.method) {
            'getSpeechRateValidRange' => {
              'min': 0.2,
              'normal': 0.5,
              'max': 1.0,
              'platform': 'android',
            },
            'getDefaultEngine' => 'engine.default',
            _ => 1,
          };
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );
    final engine = FlutterReaderTextToSpeechEngine();
    final speech = expectLater(
      engine.speak('نطق جارٍ'),
      throwsA(
        isA<ReaderSpeechEngineException>().having(
          (error) => error.code,
          'code',
          'unexpected_cancel',
        ),
      ),
    );
    await Future<void>.delayed(Duration.zero);

    await _sendTtsCallback('speak.onCancel', null);

    await speech;
  });

  test('missing stop callback quarantines the engine before restart', () async {
    const channel = MethodChannel('flutter_tts');
    var speakCalls = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          return switch (call.method) {
            'getSpeechRateValidRange' => {
              'min': 0.2,
              'normal': 0.5,
              'max': 1.0,
              'platform': 'android',
            },
            'getDefaultEngine' => 'engine.default',
            'speak' => ++speakCalls,
            _ => 1,
          };
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );
    final engine = FlutterReaderTextToSpeechEngine(
      stopCallbackTimeout: const Duration(milliseconds: 1),
    );
    final firstSpeech = expectLater(
      engine.speak('النطق القديم'),
      throwsA(isA<ReaderSpeechInterruptedException>()),
    );
    await Future<void>.delayed(Duration.zero);

    await expectLater(
      engine.stop(),
      throwsA(
        isA<ReaderSpeechEngineException>().having(
          (error) => error.code,
          'code',
          'stop_callback_timeout',
        ),
      ),
    );
    await firstSpeech;
    await expectLater(
      engine.speak('النطق الجديد'),
      throwsA(isA<ReaderSpeechEngineException>()),
    );
    await _sendTtsCallback('speak.onCancel', null);
    expect(speakCalls, 1);
  });

  test(
    'failed third-party voice retries once on the Android default engine',
    () async {
      const channel = MethodChannel('flutter_tts');
      var activeEngine = 'engine.default';
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            switch (call.method) {
              case 'getSpeechRateValidRange':
                return {
                  'min': 0.2,
                  'normal': 0.5,
                  'max': 1.0,
                  'platform': 'android',
                };
              case 'getDefaultEngine':
                return 'engine.default';
              case 'getEngines':
                return ['engine.default', 'engine.third'];
              case 'setEngine':
                activeEngine = call.arguments as String;
                return 1;
              case 'getVoices':
                return [
                  {
                    'name': '$activeEngine-arabic',
                    'locale': 'ar-EG',
                    'quality': activeEngine == 'engine.default'
                        ? 'high'
                        : 'very high',
                    'latency': 'normal',
                    'network_required': '0',
                  },
                ];
              case 'setVoice':
                return activeEngine == 'engine.third' ? 0 : 1;
              default:
                return 1;
            }
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );
      final engine = FlutterReaderTextToSpeechEngine();
      final voices = await engine.discoverVoices();
      final thirdParty = voices.singleWhere(
        (voice) => voice.engineId == 'engine.third',
      );

      await engine.selectVoice(thirdParty);

      expect(engine.selectedVoice?.engineId, 'engine.default');
    },
  );

  test('failed platform speak result becomes an engine failure', () async {
    const channel = MethodChannel('flutter_tts');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          return switch (call.method) {
            'getSpeechRateValidRange' => {
              'min': 0.2,
              'normal': 0.5,
              'max': 1.0,
              'platform': 'android',
            },
            'getDefaultEngine' => 'engine.default',
            'speak' => 0,
            _ => 1,
          };
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );

    final diagnostics = <ReaderSpeechDiagnosticEvent>[];
    final engine = FlutterReaderTextToSpeechEngine(
      diagnosticReporter: (event, stackTrace) => diagnostics.add(event),
    );
    await expectLater(
      engine.speak('نص سري للاختبار'),
      throwsA(isA<ReaderSpeechEngineException>()),
    );
    expect(diagnostics.single.failureType, 'speak');
    expect(diagnostics.single.code, 'speak_failed');
    expect(diagnostics.single.engineId, 'engine.default');
    expect(diagnostics.single.toString(), isNot(contains('نص سري')));
  });

  test('runtime failure retries the utterance on the default engine', () async {
    const channel = MethodChannel('flutter_tts');
    var activeEngine = 'engine.default';
    var speakCalls = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          switch (call.method) {
            case 'getSpeechRateValidRange':
              return {
                'min': 0.2,
                'normal': 0.5,
                'max': 1.0,
                'platform': 'android',
              };
            case 'getDefaultEngine':
              return 'engine.default';
            case 'getEngines':
              return ['engine.default', 'engine.third'];
            case 'setEngine':
              activeEngine = call.arguments as String;
              return 1;
            case 'getVoices':
              return [
                {
                  'name': '$activeEngine-arabic',
                  'locale': 'ar-EG',
                  'quality': 'high',
                  'latency': 'normal',
                  'network_required': '0',
                },
              ];
            case 'speak':
              speakCalls += 1;
              return activeEngine == 'engine.third' ? 0 : 1;
            default:
              return 1;
          }
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );
    final engine = FlutterReaderTextToSpeechEngine();
    final voices = await engine.discoverVoices();
    await engine.selectVoice(
      voices.singleWhere((voice) => voice.engineId == 'engine.third'),
    );

    final speech = engine.speak('نص يعاد مرة واحدة');
    while (speakCalls < 2) {
      await Future<void>.delayed(Duration.zero);
    }
    await _sendTtsCallback('speak.onComplete', null);
    await speech;

    expect(speakCalls, 2);
    expect(engine.selectedVoice?.engineId, 'engine.default');
  });

  test('a stopped utterance settles before the next one starts', () async {
    const channel = MethodChannel('flutter_tts');
    var speakCalls = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          return switch (call.method) {
            'getSpeechRateValidRange' => {
              'min': 0.2,
              'normal': 0.5,
              'max': 1.0,
              'platform': 'android',
            },
            'getDefaultEngine' => 'engine.default',
            'speak' => ++speakCalls,
            _ => 1,
          };
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );
    final engine = FlutterReaderTextToSpeechEngine();
    final firstSpeech = expectLater(
      engine.speak('النطق القديم'),
      throwsA(isA<ReaderSpeechInterruptedException>()),
    );
    await Future<void>.delayed(Duration.zero);

    final stop = engine.stop();
    final secondSpeech = engine.speak('النطق الجديد');
    await Future<void>.delayed(Duration.zero);
    expect(speakCalls, 1);

    await _sendTtsCallback('speak.onCancel', null);
    await stop;
    await firstSpeech;
    while (speakCalls < 2) {
      await Future<void>.delayed(Duration.zero);
    }
    await _sendTtsCallback('speak.onComplete', null);
    await secondSpeech;
  });
}

Future<void> _sendTtsCallback(String method, Object? arguments) async {
  final data = const StandardMethodCodec().encodeMethodCall(
    MethodCall(method, arguments),
  );
  final completion = Completer<void>();
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .handlePlatformMessage('flutter_tts', data, (ByteData? response) {
        completion.complete();
      });
  await completion.future;
}
