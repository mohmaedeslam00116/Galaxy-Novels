import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/features/reader/application/reader_speech_controller.dart';
import 'package:galaxy_novels_app/features/reader/data/reader_speech_audio_handler.dart';
import 'package:galaxy_novels_app/features/reader/domain/reader_speech_models.dart';

void main() {
  test('playing speech maps to lock-screen controls and ready state', () {
    final playback = readerSpeechAudioPlaybackState(
      _state(ReaderSpeechStatus.playing),
    );

    expect(playback.playing, isTrue);
    expect(playback.processingState, AudioProcessingState.ready);
    expect(playback.controls.map((control) => control.action), [
      MediaAction.skipToPrevious,
      MediaAction.pause,
      MediaAction.skipToNext,
      MediaAction.stop,
    ]);
    expect(playback.androidCompactActionIndices, [0, 1, 2]);
  });

  test('speech chapter maps to notification metadata without chapter text', () {
    final item = readerSpeechMediaItem(_state(ReaderSpeechStatus.paused));

    expect(item?.id, '/chapters/12');
    expect(item?.title, 'الفصل الثاني عشر');
    expect(item?.album, 'رواية المجرة');
    expect(item?.artist, 'القراءة الصوتية');
    expect(item?.artUri, Uri.parse('https://example.com/cover.jpg'));
    expect(item?.extras, isNot(contains('text')));
  });

  test('speech error maps to audio-service error state', () {
    final playback = readerSpeechAudioPlaybackState(
      _state(ReaderSpeechStatus.error),
    );

    expect(playback.playing, isFalse);
    expect(playback.processingState, AudioProcessingState.error);
  });

  test(
    'audio interruptions pause and resume while unplugging only pauses',
    () async {
      final controller = _FakeSpeechController(
        _state(ReaderSpeechStatus.playing),
      );
      final session = _FakeAudioSession();
      final handler = ReaderSpeechAudioHandler(
        playbackController: controller,
        audioSession: session,
      );
      await handler.initializeAudioSession();

      session.interruptions.add(
        AudioInterruptionEvent(true, AudioInterruptionType.pause),
      );
      await _flushEvents();
      expect(controller.pauseCalls, 1);

      session.interruptions.add(
        AudioInterruptionEvent(false, AudioInterruptionType.pause),
      );
      await _flushEvents();
      expect(controller.playCalls, 1);

      controller.setState(_state(ReaderSpeechStatus.playing));
      session.noisy.add(null);
      await _flushEvents();
      expect(controller.pauseCalls, 2);

      session.interruptions.add(
        AudioInterruptionEvent(false, AudioInterruptionType.pause),
      );
      await _flushEvents();
      expect(controller.playCalls, 1);

      await handler.shutdown();
      await session.dispose();
    },
  );

  test('terminal speech errors release audio focus', () async {
    final controller = _FakeSpeechController(
      _state(ReaderSpeechStatus.playing),
    );
    final session = _FakeAudioSession();
    final handler = ReaderSpeechAudioHandler(
      playbackController: controller,
      audioSession: session,
    );
    await handler.initializeAudioSession();
    session.activeChanges.clear();

    controller.setState(_state(ReaderSpeechStatus.error));
    await _flushEvents();

    expect(session.activeChanges, contains(false));
    await handler.shutdown();
    await session.dispose();
  });

  test(
    'rapid interruption end waits for focus release before reacquiring',
    () async {
      final controller = _FakeSpeechController(
        _state(ReaderSpeechStatus.playing),
      );
      final session = _FakeAudioSession();
      final handler = ReaderSpeechAudioHandler(
        playbackController: controller,
        audioSession: session,
      );
      await handler.initializeAudioSession();
      session.activeChanges.clear();
      final delayedDeactivation = Completer<bool>();
      session.delayedDeactivation = delayedDeactivation;

      session.interruptions.add(
        AudioInterruptionEvent(true, AudioInterruptionType.pause),
      );
      await _flushEvents();
      expect(session.activeChanges, [false]);

      session.interruptions.add(
        AudioInterruptionEvent(false, AudioInterruptionType.pause),
      );
      await _flushEvents();
      expect(session.activeChanges.last, isFalse);

      delayedDeactivation.complete(true);
      await _flushEvents();
      await _flushEvents();

      expect(controller.playCalls, 1);
      expect(session.activeChanges.last, isTrue);
      await handler.shutdown();
      await session.dispose();
    },
  );

  test('audio handler delegates persisted session restoration', () async {
    final controller = _FakeSpeechController(ReaderSpeechState.idle);
    final handler = ReaderSpeechAudioHandler(playbackController: controller);

    await handler.restoreSession((checkpoint) => _UnusedChapterSource());

    expect(controller.restoreCalls, 1);
    await handler.shutdown();
  });
}

Future<void> _flushEvents() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

ReaderSpeechState _state(ReaderSpeechStatus status) {
  return ReaderSpeechState(
    status: status,
    chapter: const ReaderSpeechChapter(
      chapterId: 12,
      novelId: 8,
      contentApi: '/chapters/12',
      novelTitle: 'رواية المجرة',
      chapterTitle: 'الفصل الثاني عشر',
      coverUrl: 'https://example.com/cover.jpg',
      previousContentApi: '/chapters/11',
      nextContentApi: '/chapters/13',
      blocks: [],
      contentFingerprint: 'fingerprint',
    ),
    blockIndex: 0,
    characterStart: 0,
    characterEnd: 0,
    errorMessage: status == ReaderSpeechStatus.error ? 'فشل المحرك' : null,
  );
}

class _FakeAudioSession implements ReaderSpeechAudioSession {
  final interruptions = StreamController<AudioInterruptionEvent>.broadcast();
  final noisy = StreamController<void>.broadcast();
  final activeChanges = <bool>[];
  Completer<bool>? delayedDeactivation;

  @override
  Stream<AudioInterruptionEvent> get interruptionEventStream =>
      interruptions.stream;

  @override
  Stream<void> get becomingNoisyEventStream => noisy.stream;

  @override
  Future<void> configureForSpeech() async {}

  @override
  Future<bool> setActive(bool active) async {
    activeChanges.add(active);
    final completer = delayedDeactivation;
    if (!active && completer != null) {
      delayedDeactivation = null;
      return completer.future;
    }
    return true;
  }

  Future<void> dispose() async {
    await interruptions.close();
    await noisy.close();
  }
}

class _FakeSpeechController extends ChangeNotifier
    implements ReaderSpeechController, RestorableReaderSpeechController {
  _FakeSpeechController(this._value);

  ReaderSpeechState _value;
  int pauseCalls = 0;
  int playCalls = 0;
  int restoreCalls = 0;

  void setState(ReaderSpeechState state) {
    _value = state;
    notifyListeners();
  }

  @override
  ReaderSpeechState get value => _value;

  @override
  ReaderSpeechPreferences get preferences => ReaderSpeechPreferences.defaults;

  @override
  List<ReaderSpeechVoice> get availableVoices => const [];

  @override
  ReaderSpeechSleepTimer get sleepTimer => ReaderSpeechSleepTimer.off;

  @override
  DateTime? get sleepTimerEndsAt => null;

  @override
  void bindChapterSource(ReaderSpeechChapterSource source) {}

  @override
  Future<void> pause() async {
    pauseCalls += 1;
    setState(_state(ReaderSpeechStatus.paused));
  }

  @override
  Future<void> play() async {
    playCalls += 1;
    setState(_state(ReaderSpeechStatus.playing));
  }

  @override
  Future<void> prepareChapter(
    ReaderSpeechChapter chapter, {
    int? visibleBlockIndex,
  }) async {}

  @override
  Future<void> restoreSession(
    ReaderSpeechChapterSource Function(ReaderSpeechCheckpoint checkpoint)
    sourceFactory,
  ) async {
    restoreCalls += 1;
  }

  @override
  Future<void> previewVoice(ReaderSpeechVoice voice) async {}

  @override
  Future<void> setSleepTimer(ReaderSpeechSleepTimer timer) async {}

  @override
  Future<void> skipNextBlock() async {}

  @override
  Future<void> skipPreviousBlock() async {}

  @override
  Future<void> startFromBlock(int blockIndex) async {}

  @override
  Future<void> stop() async {
    setState(_state(ReaderSpeechStatus.idle));
  }

  @override
  Future<void> updatePreferences(ReaderSpeechPreferences preferences) async {}
}

class _UnusedChapterSource implements ReaderSpeechChapterSource {
  @override
  Future<void> didStartChapter(ReaderSpeechChapter chapter) async {}

  @override
  Future<ReaderSpeechChapter> loadChapter(String contentApi) {
    throw UnimplementedError();
  }
}
