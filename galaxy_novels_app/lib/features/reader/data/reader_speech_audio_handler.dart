import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';

import '../application/reader_speech_controller.dart';
import '../domain/reader_speech_models.dart';
import 'flutter_reader_text_to_speech_engine.dart';
import 'shared_preferences_reader_speech_store.dart';
import 'stored_reader_speech_repository.dart';

Future<ReaderSpeechAudioHandler> initializeReaderSpeechAudioHandler() async {
  final handler = await AudioService.init<ReaderSpeechAudioHandler>(
    builder: () => ReaderSpeechAudioHandler(
      playbackController: ReaderSpeechPlaybackController(
        engine: FlutterReaderTextToSpeechEngine(
          diagnosticReporter: reportReaderSpeechDiagnosticToFlutter,
        ),
        repository: StoredReaderSpeechRepository(
          store: SharedPreferencesReaderSpeechStore(),
        ),
      ),
    ),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.galaxynovels.app.reader_speech',
      androidNotificationChannelName: 'القراءة الصوتية',
      androidNotificationChannelDescription:
          'تشغيل فصول الروايات صوتيًا في الخلفية',
      androidNotificationIcon: 'drawable/ic_reader_speech_notification',
      androidStopForegroundOnPause: false,
      artDownscaleWidth: 512,
      artDownscaleHeight: 512,
    ),
  );
  await handler.initializeAudioSession();
  return handler;
}

class ReaderSpeechAudioHandler extends BaseAudioHandler
    implements ReaderSpeechController, RestorableReaderSpeechController {
  ReaderSpeechAudioHandler({
    required ReaderSpeechController playbackController,
    ReaderSpeechAudioSession? audioSession,
  }) : _playbackController = playbackController,
       _audioSession = audioSession {
    _playbackController.addListener(_syncNotification);
    _syncNotification();
  }

  final ReaderSpeechController _playbackController;
  ReaderSpeechAudioSession? _audioSession;
  StreamSubscription<AudioInterruptionEvent>? _interruptionSubscription;
  StreamSubscription<void>? _noisySubscription;
  Future<void> _audioFocusTail = Future.value();
  bool _resumeAfterInterruption = false;

  Future<void> initializeAudioSession() async {
    final session = _audioSession ??=
        await PlatformReaderSpeechAudioSession.create();
    await session.configureForSpeech();
    _interruptionSubscription = session.interruptionEventStream.listen(
      _handleAudioInterruption,
      onError: _reportBackgroundFailure,
    );
    _noisySubscription = session.becomingNoisyEventStream.listen((_) {
      _resumeAfterInterruption = false;
      _runDetached(pause());
    }, onError: _reportBackgroundFailure);
  }

  @override
  ReaderSpeechState get value => _playbackController.value;

  @override
  ReaderSpeechPreferences get preferences => _playbackController.preferences;

  @override
  List<ReaderSpeechVoice> get availableVoices =>
      _playbackController.availableVoices;

  @override
  ReaderSpeechSleepTimer get sleepTimer => _playbackController.sleepTimer;

  @override
  DateTime? get sleepTimerEndsAt => _playbackController.sleepTimerEndsAt;

  @override
  void addListener(VoidCallback listener) {
    _playbackController.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    _playbackController.removeListener(listener);
  }

  @override
  void bindChapterSource(ReaderSpeechChapterSource source) {
    _playbackController.bindChapterSource(source);
  }

  @override
  Future<void> restoreSession(
    ReaderSpeechChapterSource Function(ReaderSpeechCheckpoint checkpoint)
    sourceFactory,
  ) async {
    final controller = _playbackController;
    if (controller is RestorableReaderSpeechController) {
      await (controller as RestorableReaderSpeechController).restoreSession(
        sourceFactory,
      );
    }
  }

  @override
  Future<void> prepareChapter(
    ReaderSpeechChapter chapter, {
    int? visibleBlockIndex,
  }) {
    return _playbackController.prepareChapter(
      chapter,
      visibleBlockIndex: visibleBlockIndex,
    );
  }

  @override
  Future<void> play() async {
    if (!await _setAudioFocus(true)) return;
    await _playbackController.play();
  }

  @override
  Future<void> pause() async {
    final releaseFocus = _setAudioFocus(false);
    await _playbackController.pause();
    await releaseFocus;
  }

  @override
  Future<void> stop() async {
    final releaseFocus = _setAudioFocus(false);
    try {
      await _playbackController.stop();
    } finally {
      try {
        await releaseFocus;
      } finally {
        await super.stop();
      }
    }
  }

  @override
  Future<void> skipPreviousBlock() {
    return _playbackController.skipPreviousBlock();
  }

  @override
  Future<void> skipNextBlock() {
    return _playbackController.skipNextBlock();
  }

  @override
  Future<void> skipToPrevious() => skipPreviousBlock();

  @override
  Future<void> skipToNext() => skipNextBlock();

  @override
  Future<void> startFromBlock(int blockIndex) {
    return _playbackController.startFromBlock(blockIndex);
  }

  @override
  Future<void> updatePreferences(ReaderSpeechPreferences preferences) {
    return _playbackController.updatePreferences(preferences);
  }

  @override
  Future<void> previewVoice(ReaderSpeechVoice voice) {
    return _previewVoiceWithAudioFocus(voice);
  }

  @override
  Future<void> setSleepTimer(ReaderSpeechSleepTimer timer) {
    return _playbackController.setSleepTimer(timer);
  }

  void _syncNotification() {
    final speechState = _playbackController.value;
    playbackState.add(readerSpeechAudioPlaybackState(speechState));
    mediaItem.add(readerSpeechMediaItem(speechState));
    final session = _audioSession;
    if (speechState.status != ReaderSpeechStatus.playing &&
        speechState.status != ReaderSpeechStatus.loading &&
        session != null) {
      _runDetached(_releaseAudioFocus());
    }
  }

  Future<void> _previewVoiceWithAudioFocus(ReaderSpeechVoice voice) async {
    if (!await _setAudioFocus(true)) return;
    try {
      await _playbackController.previewVoice(voice);
    } finally {
      await _setAudioFocus(false);
    }
  }

  void _handleAudioInterruption(AudioInterruptionEvent event) {
    if (event.begin) {
      _resumeAfterInterruption = value.status == ReaderSpeechStatus.playing;
      if (_resumeAfterInterruption) {
        _runDetached(pause());
      }
      return;
    }
    if (_resumeAfterInterruption) {
      _resumeAfterInterruption = false;
      _runDetached(play());
    }
  }

  Future<void> shutdown() async {
    _playbackController.removeListener(_syncNotification);
    await _interruptionSubscription?.cancel();
    await _noisySubscription?.cancel();
    await stop();
  }

  Future<void> _releaseAudioFocus() async {
    await _setAudioFocus(false);
  }

  Future<bool> _setAudioFocus(bool active) {
    final session = _audioSession;
    if (session == null) return Future.value(true);
    final previous = _audioFocusTail;
    final operation = () async {
      await previous;
      try {
        return await session.setActive(active);
      } on Exception catch (error, stackTrace) {
        _reportBackgroundFailure(error, stackTrace);
        return false;
      }
    }();
    _audioFocusTail = operation.then<void>((_) {});
    return operation;
  }

  void _runDetached(Future<void> operation) {
    unawaited(
      operation.catchError((Object error, StackTrace stackTrace) {
        if (error is Exception) {
          _reportBackgroundFailure(error, stackTrace);
          return;
        }
        Error.throwWithStackTrace(error, stackTrace);
      }),
    );
  }

  void _reportBackgroundFailure(Object error, StackTrace stackTrace) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'reader speech audio session',
      ),
    );
  }
}

abstract interface class ReaderSpeechAudioSession {
  Stream<AudioInterruptionEvent> get interruptionEventStream;
  Stream<void> get becomingNoisyEventStream;

  Future<void> configureForSpeech();
  Future<bool> setActive(bool active);
}

class PlatformReaderSpeechAudioSession implements ReaderSpeechAudioSession {
  PlatformReaderSpeechAudioSession._(this._session);

  final AudioSession _session;

  static Future<PlatformReaderSpeechAudioSession> create() async {
    return PlatformReaderSpeechAudioSession._(await AudioSession.instance);
  }

  @override
  Stream<AudioInterruptionEvent> get interruptionEventStream =>
      _session.interruptionEventStream;

  @override
  Stream<void> get becomingNoisyEventStream =>
      _session.becomingNoisyEventStream;

  @override
  Future<void> configureForSpeech() {
    return _session.configure(const AudioSessionConfiguration.speech());
  }

  @override
  Future<bool> setActive(bool active) => _session.setActive(active);
}

PlaybackState readerSpeechAudioPlaybackState(ReaderSpeechState state) {
  final isPlaying = state.status == ReaderSpeechStatus.playing;
  final isIdle = state.status == ReaderSpeechStatus.idle;
  final controls = isIdle
      ? const <MediaControl>[]
      : <MediaControl>[
          MediaControl.skipToPrevious,
          isPlaying ? MediaControl.pause : MediaControl.play,
          MediaControl.skipToNext,
          MediaControl.stop,
        ];
  return PlaybackState(
    controls: controls,
    androidCompactActionIndices: isIdle ? const [] : const [0, 1, 2],
    processingState: _audioProcessingState(state.status),
    playing: isPlaying,
    speed: 1,
    errorCode: state.status == ReaderSpeechStatus.error ? 1 : null,
    errorMessage: state.errorMessage,
  );
}

MediaItem? readerSpeechMediaItem(ReaderSpeechState state) {
  final chapter = state.chapter;
  if (chapter == null) return null;
  return MediaItem(
    id: chapter.contentApi.isEmpty
        ? 'reader-chapter-${chapter.chapterId}'
        : chapter.contentApi,
    title: chapter.chapterTitle,
    album: chapter.novelTitle,
    artist: 'القراءة الصوتية',
    artUri: _safeArtworkUri(chapter.coverUrl),
    extras: {'chapter_id': chapter.chapterId, 'novel_id': chapter.novelId},
  );
}

AudioProcessingState _audioProcessingState(ReaderSpeechStatus status) {
  return switch (status) {
    ReaderSpeechStatus.idle => AudioProcessingState.idle,
    ReaderSpeechStatus.loading => AudioProcessingState.loading,
    ReaderSpeechStatus.playing ||
    ReaderSpeechStatus.paused => AudioProcessingState.ready,
    ReaderSpeechStatus.error => AudioProcessingState.error,
  };
}

Uri? _safeArtworkUri(String value) {
  final uri = Uri.tryParse(value.trim());
  if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
    return null;
  }
  return uri;
}
