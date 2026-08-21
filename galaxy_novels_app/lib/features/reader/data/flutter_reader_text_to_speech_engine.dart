import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../application/reader_speech_controller.dart';
import '../domain/reader_speech_models.dart';

class FlutterReaderTextToSpeechEngine implements ReaderTextToSpeechEngine {
  FlutterReaderTextToSpeechEngine({
    FlutterTts? textToSpeech,
    ReaderSpeechDiagnosticReporter? diagnosticReporter,
    Duration stopCallbackTimeout = _defaultStopCallbackTimeout,
  }) : _textToSpeech = textToSpeech ?? FlutterTts(),
       _diagnosticReporter = diagnosticReporter,
       _stopCallbackTimeout = stopCallbackTimeout;

  static const _fallbackMaxInputLength = 4000;
  static const _defaultStopCallbackTimeout = Duration(milliseconds: 750);

  final FlutterTts _textToSpeech;
  final ReaderSpeechDiagnosticReporter? _diagnosticReporter;
  final Duration _stopCallbackTimeout;
  final StreamController<ReaderSpeechProgress> _progressController =
      StreamController<ReaderSpeechProgress>.broadcast();

  Completer<void>? _activeSpeech;
  Completer<void>? _stopCallbackBarrier;
  Future<void>? _stopBarrier;
  SpeechRateValidRange? _rateRange;
  List<ReaderSpeechVoice> _discoveredVoices = const [];
  String? _defaultEngine;
  String? _currentEngine;
  ReaderSpeechVoice? _selectedVoice;
  double _lastRateMultiplier = 1;
  bool _initialized = false;
  bool _quarantined = false;

  @override
  Stream<ReaderSpeechProgress> get progress => _progressController.stream;

  @override
  ReaderSpeechVoice? get selectedVoice => _selectedVoice;

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    try {
      await _textToSpeech.awaitSpeakCompletion(false);
      await _textToSpeech.setQueueMode(0);
      _installCallbacks();
      _rateRange = await _textToSpeech.getSpeechRateValidRange;
      _defaultEngine = _textValue(await _textToSpeech.getDefaultEngine);
      _currentEngine = _defaultEngine;
      _initialized = true;
    } on MissingPluginException catch (_, stackTrace) {
      _reportFailure('initialize', 'missing_plugin', stackTrace);
      throw const ReaderSpeechEngineException(
        'خدمة القراءة الصوتية غير متاحة على هذا الجهاز.',
        code: 'missing_plugin',
        failureType: 'initialize',
      );
    } on PlatformException catch (error, stackTrace) {
      _reportFailure('initialize', error.code, stackTrace);
      throw ReaderSpeechEngineException(
        _engineFailureMessage(error.code),
        code: error.code,
        failureType: 'initialize',
      );
    }
  }

  @override
  Future<List<ReaderSpeechVoice>> discoverVoices() async {
    await initialize();
    final restoreEngine = _currentEngine;
    try {
      final voices = <ReaderSpeechVoice>[];
      for (final engineId in await _installedEngines(restoreEngine)) {
        voices.addAll(await _voicesForEngine(engineId));
      }
      _discoveredVoices = List.unmodifiable(voices);
      return _discoveredVoices;
    } on PlatformException catch (error, stackTrace) {
      _reportFailure('voice_discovery', error.code, stackTrace);
      throw ReaderSpeechEngineException(
        _engineFailureMessage(error.code),
        code: error.code,
        failureType: 'voice_discovery',
      );
    } finally {
      await _restoreEngine(restoreEngine);
    }
  }

  Future<List<String>> _installedEngines(String? fallbackEngine) async {
    final engines = _stringList(await _textToSpeech.getEngines);
    if (engines.isEmpty && fallbackEngine != null) engines.add(fallbackEngine);
    return engines;
  }

  Future<List<ReaderSpeechVoice>> _voicesForEngine(String engineId) async {
    try {
      await _textToSpeech.setEngine(engineId);
      return _mapList(await _textToSpeech.getVoices)
          .map(
            (metadata) => readerSpeechVoiceFromAndroid(
              engineId: engineId,
              metadata: metadata,
            ),
          )
          .where((voice) => voice.name.isNotEmpty && voice.locale.isNotEmpty)
          .toList();
    } on PlatformException {
      return const [];
    }
  }

  Future<void> _restoreEngine(String? engineId) async {
    if (engineId == null) return;
    try {
      await _textToSpeech.setEngine(engineId);
      _currentEngine = engineId;
    } on PlatformException {
      _currentEngine = null;
    }
  }

  @override
  Future<int> maxInputLength() async {
    await initialize();
    try {
      final value = await _textToSpeech.getMaxSpeechInputLength;
      return value == null || value <= 0 ? _fallbackMaxInputLength : value;
    } on PlatformException {
      return _fallbackMaxInputLength;
    }
  }

  @override
  Future<void> selectVoice(ReaderSpeechVoice voice) async {
    await initialize();
    Object? firstFailure;
    try {
      if (await _activateVoice(voice)) return;
    } on PlatformException catch (error) {
      firstFailure = error;
    }
    final fallback = selectPreferredArabicVoice(
      _discoveredVoices.where((item) => item.engineId == _defaultEngine),
    );
    if (fallback != null && fallback.id != voice.id) {
      try {
        if (await _activateVoice(fallback)) return;
      } on PlatformException catch (error) {
        firstFailure ??= error;
      }
    }
    if (firstFailure case final PlatformException error) {
      _reportFailure('voice_activation', error.code, StackTrace.current);
      throw ReaderSpeechEngineException(
        _engineFailureMessage(error.code),
        code: error.code,
        failureType: 'voice_activation',
      );
    }
    _reportFailure('voice_activation', 'unavailable', StackTrace.current);
    throw const ReaderSpeechEngineException(
      'تعذر تفعيل الصوت المحدد. جرّب صوتًا آخر.',
      code: 'unavailable',
      failureType: 'voice_activation',
    );
  }

  Future<bool> _activateVoice(ReaderSpeechVoice voice) async {
    if (_currentEngine != voice.engineId) {
      await _textToSpeech.setEngine(voice.engineId);
      _currentEngine = voice.engineId;
    }
    final result = await _textToSpeech.setVoice({
      'name': voice.name,
      'locale': voice.locale,
    });
    if (result is num && result <= 0) return false;
    _selectedVoice = voice;
    return true;
  }

  @override
  Future<void> setRateMultiplier(double multiplier) async {
    await initialize();
    _lastRateMultiplier = multiplier
        .clamp(ReaderSpeechPreferences.minRate, ReaderSpeechPreferences.maxRate)
        .toDouble();
    final range = _rateRange;
    if (range == null) return;
    final rate = readerSpeechPlatformRate(
      _lastRateMultiplier,
      minimum: range.min,
      normal: range.normal,
      maximum: range.max,
    );
    try {
      await _textToSpeech.setSpeechRate(rate);
    } on PlatformException catch (error, stackTrace) {
      _reportFailure('rate', error.code, stackTrace);
      throw ReaderSpeechEngineException(
        _engineFailureMessage(error.code),
        code: error.code,
        failureType: 'rate',
      );
    }
  }

  @override
  Future<void> speak(String text) async {
    await initialize();
    if (text.trim().isEmpty) return;
    final stopBarrier = _stopBarrier;
    if (stopBarrier != null) await stopBarrier;
    if (_quarantined) {
      throw const ReaderSpeechEngineException(
        'توقف محرك الصوت عن الاستجابة. أعد فتح التطبيق أو غيّر المحرك.',
        code: 'stop_callback_timeout',
        failureType: 'stop',
      );
    }
    try {
      await _speakOnce(text);
    } on ReaderSpeechEngineException catch (error, stackTrace) {
      _reportFailure('speak', error.code, stackTrace);
      if (!await _activateRuntimeFallback()) rethrow;
      await setRateMultiplier(_lastRateMultiplier);
      try {
        await _speakOnce(text);
      } on ReaderSpeechEngineException catch (retryError, stackTrace) {
        _reportFailure('speak_retry', retryError.code, stackTrace);
        rethrow;
      }
    }
  }

  Future<void> _speakOnce(String text) async {
    _interruptActiveSpeech();
    final completion = Completer<void>();
    _activeSpeech = completion;
    try {
      final result = await _textToSpeech.speak(text, focus: false);
      if (result is num && result <= 0 && !completion.isCompleted) {
        completion.completeError(
          const ReaderSpeechEngineException(
            'تعذر بدء القراءة الصوتية (الرمز: speak_failed).',
            code: 'speak_failed',
            failureType: 'speak',
          ),
        );
      }
      await completion.future;
    } on PlatformException catch (error) {
      if (!completion.isCompleted) {
        completion.completeError(
          ReaderSpeechEngineException(
            _engineFailureMessage(error.code),
            code: error.code,
            failureType: 'speak',
          ),
        );
      }
      await completion.future;
    } finally {
      if (identical(_activeSpeech, completion)) _activeSpeech = null;
    }
  }

  @override
  Future<void> stop() {
    final pending = _stopBarrier;
    if (pending != null) return pending;
    final operation = _stopAndAwaitTerminalCallback();
    _stopBarrier = operation;
    return operation.whenComplete(() {
      if (identical(_stopBarrier, operation)) _stopBarrier = null;
    });
  }

  Future<void> _stopAndAwaitTerminalCallback() async {
    final hadActiveSpeech = _activeSpeech != null;
    final callbackBarrier = hadActiveSpeech ? Completer<void>() : null;
    _stopCallbackBarrier = callbackBarrier;
    _interruptActiveSpeech();
    ReaderSpeechEngineException? platformFailure;
    try {
      await _textToSpeech.stop();
    } on PlatformException catch (error, stackTrace) {
      _reportFailure('stop', error.code, stackTrace);
      platformFailure = ReaderSpeechEngineException(
        _engineFailureMessage(error.code),
        code: error.code,
        failureType: 'stop',
      );
    }
    if (callbackBarrier != null) {
      try {
        await callbackBarrier.future.timeout(_stopCallbackTimeout);
      } on TimeoutException catch (_, stackTrace) {
        _quarantined = true;
        _reportFailure('stop', 'stop_callback_timeout', stackTrace);
        platformFailure ??= const ReaderSpeechEngineException(
          'توقف محرك الصوت عن الاستجابة. أعد فتح التطبيق أو غيّر المحرك.',
          code: 'stop_callback_timeout',
          failureType: 'stop',
        );
      }
    }
    if (identical(_stopCallbackBarrier, callbackBarrier)) {
      _stopCallbackBarrier = null;
    }
    if (platformFailure != null) throw platformFailure;
  }

  Future<bool> _activateRuntimeFallback() async {
    final fallback = selectPreferredArabicVoice(
      _discoveredVoices.where((voice) => voice.engineId == _defaultEngine),
    );
    if (fallback == null || fallback.id == _selectedVoice?.id) return false;
    try {
      return await _activateVoice(fallback);
    } on PlatformException {
      return false;
    }
  }

  void _installCallbacks() {
    _textToSpeech.setCompletionHandler(_completeActiveSpeech);
    _textToSpeech.setCancelHandler(() {
      if (!_completeStopCallbackBarrier()) _failUnexpectedCancellation();
    });
    _textToSpeech.setErrorHandler((error) {
      if (_completeStopCallbackBarrier()) return;
      final active = _activeSpeech;
      if (active == null || active.isCompleted) return;
      active.completeError(
        ReaderSpeechEngineException(
          'تعذر تشغيل الصوت المحدد '
          '(الرمز: ${_ttsCallbackErrorCode(error)}).',
          code: _ttsCallbackErrorCode(error),
          failureType: 'speak_callback',
        ),
      );
    });
    _textToSpeech.setProgressHandler((text, start, end, word) {
      if (_stopCallbackBarrier == null && !_progressController.isClosed) {
        _progressController.add(ReaderSpeechProgress(start: start, end: end));
      }
    });
  }

  void _completeActiveSpeech() {
    if (_completeStopCallbackBarrier()) return;
    final active = _activeSpeech;
    if (active != null && !active.isCompleted) active.complete();
  }

  void _interruptActiveSpeech() {
    final active = _activeSpeech;
    if (active != null && !active.isCompleted) {
      active.completeError(const ReaderSpeechInterruptedException());
    }
  }

  void _failUnexpectedCancellation() {
    final active = _activeSpeech;
    if (active == null || active.isCompleted) return;
    active.completeError(
      const ReaderSpeechEngineException(
        'أوقف محرك الصوت النطق بصورة غير متوقعة.',
        code: 'unexpected_cancel',
        failureType: 'speak_callback',
      ),
    );
  }

  bool _completeStopCallbackBarrier() {
    final barrier = _stopCallbackBarrier;
    if (barrier == null || barrier.isCompleted) return false;
    barrier.complete();
    return true;
  }

  void _reportFailure(String failureType, String code, StackTrace stackTrace) {
    final reporter = _diagnosticReporter;
    if (reporter == null) return;
    try {
      reporter(
        ReaderSpeechDiagnosticEvent(
          failureType: failureType,
          code: code,
          engineId: _currentEngine ?? _defaultEngine ?? 'unknown',
          androidVersion: Platform.operatingSystemVersion,
        ),
        stackTrace,
      );
    } on Exception {
      // Diagnostics must never replace the actionable playback failure.
    }
  }
}

typedef ReaderSpeechDiagnosticReporter =
    void Function(ReaderSpeechDiagnosticEvent event, StackTrace stackTrace);

@immutable
class ReaderSpeechDiagnosticEvent implements Exception {
  const ReaderSpeechDiagnosticEvent({
    required this.failureType,
    required this.code,
    required this.engineId,
    required this.androidVersion,
  });

  final String failureType;
  final String code;
  final String engineId;
  final String androidVersion;

  @override
  String toString() {
    return 'ReaderSpeechDiagnostic('
        'failureType: $failureType, '
        'code: $code, '
        'engineId: $engineId, '
        'androidVersion: $androidVersion)';
  }
}

void reportReaderSpeechDiagnosticToFlutter(
  ReaderSpeechDiagnosticEvent event,
  StackTrace stackTrace,
) {
  FlutterError.reportError(
    FlutterErrorDetails(
      exception: event,
      stack: stackTrace,
      library: 'reader speech',
    ),
  );
}

ReaderSpeechVoice readerSpeechVoiceFromAndroid({
  required String engineId,
  required Map<Object?, Object?> metadata,
}) {
  return ReaderSpeechVoice(
    engineId: engineId,
    name: _textValue(metadata['name']) ?? '',
    locale: _textValue(metadata['locale']) ?? '',
    quality: _androidVoiceMetric(metadata['quality']),
    latency: _androidVoiceMetric(metadata['latency']),
    networkRequired: _boolValue(metadata['network_required']),
  );
}

double readerSpeechPlatformRate(
  double multiplier, {
  required double minimum,
  required double normal,
  required double maximum,
}) {
  final bounded = multiplier.clamp(
    ReaderSpeechPreferences.minRate,
    ReaderSpeechPreferences.maxRate,
  );
  if (bounded <= 1) {
    final fraction =
        (bounded - ReaderSpeechPreferences.minRate) /
        (1 - ReaderSpeechPreferences.minRate);
    return minimum + ((normal - minimum) * fraction);
  }
  return normal + ((maximum - normal) * (bounded - 1));
}

List<String> _stringList(Object? value) {
  if (value is! Iterable<Object?>) return <String>[];
  return value.map(_textValue).whereType<String>().toList();
}

List<Map<Object?, Object?>> _mapList(Object? value) {
  if (value is! Iterable<Object?>) return const [];
  return value
      .whereType<Map<Object?, Object?>>()
      .map((map) => Map<Object?, Object?>.from(map))
      .toList();
}

String? _textValue(Object? value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : text;
}

int _androidVoiceMetric(Object? value) {
  if (value is num) return value.toInt();
  return switch (_textValue(value)?.toLowerCase()) {
    'very low' => 100,
    'low' => 200,
    'normal' => 300,
    'high' => 400,
    'very high' => 500,
    _ => 0,
  };
}

bool _boolValue(Object? value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  return const {'1', 'true', 'yes'}.contains(value?.toString().toLowerCase());
}

String _engineFailureMessage(String code) {
  return 'تعذر الاتصال بمحرك القراءة الصوتية (الرمز: $code).';
}

String _ttsCallbackErrorCode(Object? error) {
  final text = error?.toString() ?? '';
  final match = RegExp(r'-?\d+').firstMatch(text);
  return match?.group(0) ?? 'speak_callback';
}
