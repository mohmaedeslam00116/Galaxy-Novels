import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/features/reader/application/reader_speech_controller.dart';
import 'package:galaxy_novels_app/features/reader/application/reader_speech_repository.dart';
import 'package:galaxy_novels_app/features/reader/domain/reader_speech_models.dart';

void main() {
  test(
    'matching checkpoint resumes from its paragraph and character',
    () async {
      final repository = _MemoryReaderSpeechRepository(
        checkpoint: const ReaderSpeechCheckpoint(
          novelId: 8,
          chapterId: 12,
          contentApi: '/chapters/12',
          blockIndex: 1,
          characterOffset: 4,
          contentFingerprint: 'chapter-fingerprint',
        ),
      );
      final controller = ReaderSpeechPlaybackController(
        engine: _FakeSpeechEngine(),
        repository: repository,
      );

      await controller.prepareChapter(_chapter(), visibleBlockIndex: 0);

      expect(controller.value.status, ReaderSpeechStatus.paused);
      expect(controller.value.blockIndex, 1);
      expect(controller.value.characterStart, 4);
    },
  );

  test('stale checkpoint starts from the visible paragraph', () async {
    final repository = _MemoryReaderSpeechRepository(
      checkpoint: const ReaderSpeechCheckpoint(
        novelId: 8,
        chapterId: 12,
        contentApi: '/chapters/12',
        blockIndex: 0,
        characterOffset: 7,
        contentFingerprint: 'old-content',
      ),
    );
    final controller = ReaderSpeechPlaybackController(
      engine: _FakeSpeechEngine(),
      repository: repository,
    );

    await controller.prepareChapter(_chapter(), visibleBlockIndex: 1);

    expect(controller.value.blockIndex, 1);
    expect(controller.value.characterStart, 0);
  });

  test('checkpoint from another novel is never restored', () async {
    final repository = _MemoryReaderSpeechRepository(
      checkpoint: const ReaderSpeechCheckpoint(
        novelId: 99,
        chapterId: 12,
        contentApi: '/chapters/12',
        blockIndex: 1,
        characterOffset: 4,
        contentFingerprint: 'chapter-fingerprint',
      ),
    );
    final controller = ReaderSpeechPlaybackController(
      engine: _FakeSpeechEngine(),
      repository: repository,
    );

    await controller.prepareChapter(_chapter(), visibleBlockIndex: 0);

    expect(controller.value.blockIndex, 0);
    expect(controller.value.characterStart, 0);
  });

  test(
    'service restoration rebuilds a matching checkpoint as paused',
    () async {
      final repository = _MemoryReaderSpeechRepository(
        checkpoint: const ReaderSpeechCheckpoint(
          novelId: 8,
          chapterId: 12,
          contentApi: '/chapters/12',
          blockIndex: 1,
          characterOffset: 3,
          contentFingerprint: 'chapter-fingerprint',
          novelTitle: 'رواية المجرة',
        ),
      );
      final source = _FakeChapterSource(_chapter());
      final controller = ReaderSpeechPlaybackController(
        engine: _FakeSpeechEngine(),
        repository: repository,
      );

      await controller.restoreSession((checkpoint) => source);

      expect(source.loadedApis, ['/chapters/12']);
      expect(controller.value.status, ReaderSpeechStatus.paused);
      expect(controller.value.blockIndex, 1);
      expect(controller.value.characterStart, 3);
    },
  );

  test('delayed restoration cannot replace a user chapter', () async {
    final repository = _MemoryReaderSpeechRepository(
      checkpoint: const ReaderSpeechCheckpoint(
        novelId: 8,
        chapterId: 12,
        contentApi: '/chapters/12',
        blockIndex: 0,
        characterOffset: 0,
        contentFingerprint: 'chapter-fingerprint',
      ),
    );
    final source = _DelayedChapterSource();
    final controller = ReaderSpeechPlaybackController(
      engine: _FakeSpeechEngine(),
      repository: repository,
    );
    final restoration = controller.restoreSession((checkpoint) => source);
    await _flushAsyncWork();

    await controller.prepareChapter(_nextChapter());
    source.complete(_chapter());
    await restoration;

    expect(controller.value.status, ReaderSpeechStatus.paused);
    expect(controller.value.chapter?.chapterId, 13);
  });

  test(
    'play selects the offline Arabic voice and reports word progress',
    () async {
      final engine = _FakeSpeechEngine();
      final controller = ReaderSpeechPlaybackController(
        engine: engine,
        repository: _MemoryReaderSpeechRepository(),
      );
      await controller.prepareChapter(_chapter(), visibleBlockIndex: 0);

      await controller.play();
      await _flushAsyncWork();

      expect(controller.value.status, ReaderSpeechStatus.playing);
      expect(engine.selectedVoice?.name, 'offline-arabic');
      expect(engine.spokenTexts.single, 'الفقرة الأولى.');

      engine.emitProgress(2, 7);
      await _flushAsyncWork();

      expect(controller.value.characterStart, 2);
      expect(controller.value.characterEnd, 7);

      await controller.pause();
      expect(controller.value.status, ReaderSpeechStatus.paused);
    },
  );

  test('pausing saves the current listening checkpoint', () async {
    final repository = _MemoryReaderSpeechRepository();
    final engine = _FakeSpeechEngine();
    final controller = ReaderSpeechPlaybackController(
      engine: engine,
      repository: repository,
    );
    await controller.prepareChapter(_chapter(), visibleBlockIndex: 0);
    await controller.play();
    await _flushAsyncWork();
    engine.emitProgress(3, 8);
    await _flushAsyncWork();

    await controller.pause();

    expect(repository.checkpoint?.blockIndex, 0);
    expect(repository.checkpoint?.characterOffset, 3);
    expect(repository.checkpoint?.contentFingerprint, 'chapter-fingerprint');
  });

  test('missing Arabic voices produces a recoverable error state', () async {
    final controller = ReaderSpeechPlaybackController(
      engine: _FakeSpeechEngine(voices: const []),
      repository: _MemoryReaderSpeechRepository(),
    );
    await controller.prepareChapter(_chapter(), visibleBlockIndex: 0);

    await controller.play();
    await _flushAsyncWork();

    expect(controller.value.status, ReaderSpeechStatus.error);
    expect(controller.value.errorMessage, contains('صوت عربي'));
  });

  test(
    'chapter completion announces and continues into the next chapter',
    () async {
      final engine = _FakeSpeechEngine();
      final source = _FakeChapterSource(_nextChapter());
      final controller = ReaderSpeechPlaybackController(
        engine: engine,
        repository: _MemoryReaderSpeechRepository(),
      )..bindChapterSource(source);
      await controller.prepareChapter(_singleBlockChapter());
      await controller.play();
      await _flushAsyncWork();

      engine.completeSpeech();
      await _flushAsyncWork();

      expect(source.loadedApis, ['/chapters/13']);
      expect(controller.value.chapter?.chapterId, 13);
      expect(engine.spokenTexts, ['نهاية الفصل.', 'الفصل التالي']);
    },
  );

  test('chapter load failure remains an actionable error', () async {
    final engine = _FakeSpeechEngine();
    final controller = ReaderSpeechPlaybackController(
      engine: engine,
      repository: _MemoryReaderSpeechRepository(),
    )..bindChapterSource(_FailingChapterSource());
    await controller.prepareChapter(_singleBlockChapter());
    await controller.play();
    await _flushAsyncWork();

    engine.completeSpeech();
    await _flushAsyncWork();

    expect(controller.value.status, ReaderSpeechStatus.error);
    expect(controller.value.errorMessage, contains('الفصل التالي'));
  });

  test('stopping during next chapter load keeps playback stopped', () async {
    final engine = _FakeSpeechEngine();
    final source = _DelayedChapterSource();
    final controller = ReaderSpeechPlaybackController(
      engine: engine,
      repository: _MemoryReaderSpeechRepository(),
    )..bindChapterSource(source);
    await controller.prepareChapter(_singleBlockChapter());
    await controller.play();
    await _flushAsyncWork();
    engine.completeSpeech();
    await _flushAsyncWork();
    expect(source.loadedApis, ['/chapters/13']);

    await controller.stop();
    source.complete(_nextChapter());
    await _flushAsyncWork();

    expect(controller.value.status, ReaderSpeechStatus.idle);
    expect(controller.value.chapter?.chapterId, 12);
    expect(source.startedChapters, isEmpty);
  });

  test('a newly prepared chapter wins over a delayed next chapter', () async {
    final engine = _FakeSpeechEngine();
    final source = _DelayedChapterSource();
    final controller = ReaderSpeechPlaybackController(
      engine: engine,
      repository: _MemoryReaderSpeechRepository(),
    )..bindChapterSource(source);
    await controller.prepareChapter(_singleBlockChapter());
    await controller.play();
    await _flushAsyncWork();
    engine.completeSpeech();
    await _flushAsyncWork();

    final replacement = _nextChapter();
    await controller.prepareChapter(replacement);
    source.complete(replacement);
    await _flushAsyncWork();

    expect(controller.value.status, ReaderSpeechStatus.paused);
    expect(controller.value.chapter?.chapterId, 13);
    expect(source.startedChapters, isEmpty);
  });

  test('stale next chapter failure cannot replace a newer chapter', () async {
    final engine = _FakeSpeechEngine();
    final source = _DelayedFailingChapterSource();
    final controller = ReaderSpeechPlaybackController(
      engine: engine,
      repository: _MemoryReaderSpeechRepository(),
    )..bindChapterSource(source);
    await controller.prepareChapter(_singleBlockChapter());
    await controller.play();
    await _flushAsyncWork();
    engine.completeSpeech();
    await _flushAsyncWork();

    await controller.prepareChapter(_nextChapter());
    source.fail();
    await _flushAsyncWork();

    expect(controller.value.status, ReaderSpeechStatus.paused);
    expect(controller.value.chapter?.chapterId, 13);
    expect(controller.value.errorMessage, isNull);
  });

  test('selected fallback voice is persisted for later sessions', () async {
    final repository = _MemoryReaderSpeechRepository();
    final controller = ReaderSpeechPlaybackController(
      engine: _FakeSpeechEngine(),
      repository: repository,
    );
    await controller.prepareChapter(_chapter());

    await controller.play();
    await _flushAsyncWork();

    expect(repository.value.engineId, 'engine');
    expect(repository.value.voiceName, 'offline-arabic');
    await controller.pause();
  });

  test('missing saved voice falls back with a visible notice', () async {
    final repository = _MemoryReaderSpeechRepository(
      preferences: ReaderSpeechPreferences.defaults.copyWith(
        engineId: 'missing.engine',
        voiceName: 'missing.voice',
        voiceLocale: 'ar-EG',
      ),
    );
    final controller = ReaderSpeechPlaybackController(
      engine: _FakeSpeechEngine(),
      repository: repository,
    );
    await controller.prepareChapter(_chapter());

    await controller.play();
    await _flushAsyncWork();

    expect(controller.value.noticeMessage, contains('لم يعد الصوت المحفوظ'));
    expect(repository.value.voiceName, 'offline-arabic');
    await controller.pause();
  });

  test(
    'a later bound source cannot steal the active playback session',
    () async {
      final engine = _FakeSpeechEngine();
      final firstSource = _FakeChapterSource(_nextChapter());
      final secondSource = _FakeChapterSource(_nextChapter());
      final controller = ReaderSpeechPlaybackController(
        engine: engine,
        repository: _MemoryReaderSpeechRepository(),
      )..bindChapterSource(firstSource);
      await controller.prepareChapter(_singleBlockChapter());
      controller.bindChapterSource(secondSource);
      await controller.play();
      await _flushAsyncWork();

      engine.completeSpeech();
      await _flushAsyncWork();

      expect(firstSource.loadedApis, ['/chapters/13']);
      expect(secondSource.loadedApis, isEmpty);
    },
  );

  test(
    'end-of-chapter sleep timer prevents automatic chapter loading',
    () async {
      final engine = _FakeSpeechEngine();
      final source = _FakeChapterSource(_nextChapter());
      final controller = ReaderSpeechPlaybackController(
        engine: engine,
        repository: _MemoryReaderSpeechRepository(),
      )..bindChapterSource(source);
      await controller.prepareChapter(_singleBlockChapter());
      await controller.setSleepTimer(ReaderSpeechSleepTimer.endOfChapter);
      await controller.play();
      await _flushAsyncWork();

      engine.completeSpeech();
      await _flushAsyncWork();

      expect(source.loadedApis, isEmpty);
      expect(controller.value.status, ReaderSpeechStatus.idle);
    },
  );

  test(
    'paused playback is stopped after the configured retention timeout',
    () async {
      final controller = ReaderSpeechPlaybackController(
        engine: _FakeSpeechEngine(),
        repository: _MemoryReaderSpeechRepository(),
        pauseTimeout: Duration.zero,
      );
      await controller.prepareChapter(_chapter());
      await controller.pause();
      await _flushAsyncWork();

      expect(controller.value.status, ReaderSpeechStatus.idle);
    },
  );

  test('sleep timer pauses after the current engine chunk', () async {
    final repository = _MemoryReaderSpeechRepository();
    final engine = _FakeSpeechEngine(maxSpeechInputLength: 8);
    final controller = ReaderSpeechPlaybackController(
      engine: engine,
      repository: repository,
      sleepTimerDurations: const {
        ReaderSpeechSleepTimer.minutes15: Duration.zero,
      },
    );
    final chapter = ReaderSpeechChapter(
      chapterId: 12,
      novelId: 8,
      contentApi: '/chapters/12',
      novelTitle: 'رواية المجرة',
      chapterTitle: 'فصل طويل',
      coverUrl: '',
      previousContentApi: '',
      nextContentApi: '',
      blocks: const [
        ReaderSpeechBlock(
          sourceIndex: 0,
          kind: ReaderSpeechBlockKind.paragraph,
          text: 'جملة أولى. جملة ثانية طويلة.',
        ),
      ],
      contentFingerprint: 'long-block',
    );
    await controller.prepareChapter(chapter);
    await controller.setSleepTimer(ReaderSpeechSleepTimer.minutes15);
    await controller.play();
    await _flushAsyncWork();
    expect(engine.spokenTexts, hasLength(1));

    engine.completeSpeech();
    await _flushAsyncWork();

    expect(controller.value.status, ReaderSpeechStatus.paused);
    expect(engine.spokenTexts, hasLength(1));
    expect(repository.checkpoint!.characterOffset, greaterThan(0));
    expect(
      repository.checkpoint!.characterOffset,
      lessThan(chapter.blocks.single.text.length),
    );
  });
}

ReaderSpeechChapter _chapter() {
  return const ReaderSpeechChapter(
    chapterId: 12,
    novelId: 8,
    contentApi: '/chapters/12',
    novelTitle: 'رواية المجرة',
    chapterTitle: 'اللقاء',
    coverUrl: '',
    previousContentApi: '/chapters/11',
    nextContentApi: '/chapters/13',
    blocks: [
      ReaderSpeechBlock(
        sourceIndex: 0,
        kind: ReaderSpeechBlockKind.paragraph,
        text: 'الفقرة الأولى.',
      ),
      ReaderSpeechBlock(
        sourceIndex: 1,
        kind: ReaderSpeechBlockKind.paragraph,
        text: 'الفقرة الثانية.',
      ),
    ],
    contentFingerprint: 'chapter-fingerprint',
  );
}

ReaderSpeechChapter _singleBlockChapter() {
  return const ReaderSpeechChapter(
    chapterId: 12,
    novelId: 8,
    contentApi: '/chapters/12',
    novelTitle: 'رواية المجرة',
    chapterTitle: 'اللقاء',
    coverUrl: '',
    previousContentApi: '/chapters/11',
    nextContentApi: '/chapters/13',
    blocks: [
      ReaderSpeechBlock(
        sourceIndex: 0,
        kind: ReaderSpeechBlockKind.paragraph,
        text: 'نهاية الفصل.',
      ),
    ],
    contentFingerprint: 'single-block',
  );
}

ReaderSpeechChapter _nextChapter() {
  return const ReaderSpeechChapter(
    chapterId: 13,
    novelId: 8,
    contentApi: '/chapters/13',
    novelTitle: 'رواية المجرة',
    chapterTitle: 'الفصل التالي',
    coverUrl: '',
    previousContentApi: '/chapters/12',
    nextContentApi: '',
    blocks: [
      ReaderSpeechBlock(
        sourceIndex: 0,
        kind: ReaderSpeechBlockKind.paragraph,
        text: 'بداية جديدة.',
      ),
    ],
    contentFingerprint: 'next-chapter',
  );
}

Future<void> _flushAsyncWork() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

class _FakeSpeechEngine implements ReaderTextToSpeechEngine {
  _FakeSpeechEngine({
    List<ReaderSpeechVoice> voices = const [
      ReaderSpeechVoice(
        engineId: 'engine',
        name: 'offline-arabic',
        locale: 'ar-EG',
        quality: 400,
        latency: 200,
        networkRequired: false,
      ),
    ],
    this.maxSpeechInputLength = 4000,
  }) : _voices = voices;

  final List<ReaderSpeechVoice> _voices;
  final int maxSpeechInputLength;
  final _progress = StreamController<ReaderSpeechProgress>.broadcast();
  final List<String> spokenTexts = [];
  Completer<void>? _speechCompletion;
  @override
  ReaderSpeechVoice? selectedVoice;

  @override
  Stream<ReaderSpeechProgress> get progress => _progress.stream;

  void emitProgress(int start, int end) {
    _progress.add(ReaderSpeechProgress(start: start, end: end));
  }

  void completeSpeech() {
    if (_speechCompletion?.isCompleted == false) {
      _speechCompletion?.complete();
    }
  }

  @override
  Future<List<ReaderSpeechVoice>> discoverVoices() async => _voices;

  @override
  Future<void> initialize() async {}

  @override
  Future<int> maxInputLength() async => maxSpeechInputLength;

  @override
  Future<void> selectVoice(ReaderSpeechVoice voice) async {
    selectedVoice = voice;
  }

  @override
  Future<void> setRateMultiplier(double multiplier) async {}

  @override
  Future<void> speak(String text) {
    spokenTexts.add(text);
    _speechCompletion = Completer<void>();
    return _speechCompletion!.future;
  }

  @override
  Future<void> stop() async {
    if (_speechCompletion?.isCompleted == false) {
      _speechCompletion?.completeError(
        const ReaderSpeechInterruptedException(),
      );
    }
  }
}

class _FakeChapterSource implements ReaderSpeechChapterSource {
  _FakeChapterSource(this.nextChapter);

  final ReaderSpeechChapter nextChapter;
  final List<String> loadedApis = [];

  @override
  Future<void> didStartChapter(ReaderSpeechChapter chapter) async {}

  @override
  Future<ReaderSpeechChapter> loadChapter(String contentApi) async {
    loadedApis.add(contentApi);
    return nextChapter;
  }
}

class _FailingChapterSource implements ReaderSpeechChapterSource {
  @override
  Future<void> didStartChapter(ReaderSpeechChapter chapter) async {}

  @override
  Future<ReaderSpeechChapter> loadChapter(String contentApi) async {
    throw Exception('next chapter failed');
  }
}

class _DelayedChapterSource implements ReaderSpeechChapterSource {
  final _completion = Completer<ReaderSpeechChapter>();
  final List<String> loadedApis = [];
  final List<int> startedChapters = [];

  void complete(ReaderSpeechChapter chapter) => _completion.complete(chapter);

  @override
  Future<void> didStartChapter(ReaderSpeechChapter chapter) async {
    startedChapters.add(chapter.chapterId);
  }

  @override
  Future<ReaderSpeechChapter> loadChapter(String contentApi) {
    loadedApis.add(contentApi);
    return _completion.future;
  }
}

class _DelayedFailingChapterSource implements ReaderSpeechChapterSource {
  final _completion = Completer<ReaderSpeechChapter>();

  void fail() => _completion.completeError(Exception('delayed failure'));

  @override
  Future<void> didStartChapter(ReaderSpeechChapter chapter) async {}

  @override
  Future<ReaderSpeechChapter> loadChapter(String contentApi) {
    return _completion.future;
  }
}

class _MemoryReaderSpeechRepository implements ReaderSpeechRepository {
  _MemoryReaderSpeechRepository({
    this.checkpoint,
    ReaderSpeechPreferences? preferences,
  }) : _preferences = preferences ?? ReaderSpeechPreferences.defaults;

  @override
  ReaderSpeechCheckpoint? checkpoint;

  ReaderSpeechPreferences _preferences;

  @override
  ReaderSpeechPreferences get value => _preferences;

  @override
  Future<void> clearCheckpoint() async {
    checkpoint = null;
  }

  @override
  Future<void> load() async {}

  @override
  Future<void> saveCheckpoint(ReaderSpeechCheckpoint nextCheckpoint) async {
    checkpoint = nextCheckpoint;
  }

  @override
  Future<void> updatePreferences(ReaderSpeechPreferences preferences) async {
    _preferences = preferences;
  }

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}
}
