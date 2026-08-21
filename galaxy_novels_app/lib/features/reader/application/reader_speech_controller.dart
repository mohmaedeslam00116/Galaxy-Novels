import 'dart:async';

import 'package:flutter/foundation.dart';

import 'reader_speech_narration.dart';
import 'reader_speech_repository.dart';
import '../domain/reader_speech_models.dart';

class ReaderSpeechProgress {
  const ReaderSpeechProgress({required this.start, required this.end});

  final int start;
  final int end;
}

class ReaderSpeechInterruptedException implements Exception {
  const ReaderSpeechInterruptedException();
}

class ReaderSpeechEngineException implements Exception {
  const ReaderSpeechEngineException(
    this.message, {
    this.code = 'unknown',
    this.failureType = 'engine',
  });

  final String message;
  final String code;
  final String failureType;

  @override
  String toString() => message;
}

abstract interface class ReaderTextToSpeechEngine {
  Stream<ReaderSpeechProgress> get progress;
  ReaderSpeechVoice? get selectedVoice;

  Future<void> initialize();

  Future<List<ReaderSpeechVoice>> discoverVoices();

  Future<int> maxInputLength();

  Future<void> selectVoice(ReaderSpeechVoice voice);

  Future<void> setRateMultiplier(double multiplier);

  Future<void> speak(String text);

  Future<void> stop();
}

abstract interface class ReaderSpeechChapterSource {
  Future<ReaderSpeechChapter> loadChapter(String contentApi);

  Future<void> didStartChapter(ReaderSpeechChapter chapter);
}

abstract interface class ReaderSpeechController
    implements ValueListenable<ReaderSpeechState> {
  ReaderSpeechPreferences get preferences;
  List<ReaderSpeechVoice> get availableVoices;
  ReaderSpeechSleepTimer get sleepTimer;
  DateTime? get sleepTimerEndsAt;

  void bindChapterSource(ReaderSpeechChapterSource source);

  Future<void> prepareChapter(
    ReaderSpeechChapter chapter, {
    int? visibleBlockIndex,
  });

  Future<void> play();
  Future<void> pause();
  Future<void> stop();
  Future<void> skipPreviousBlock();
  Future<void> skipNextBlock();
  Future<void> startFromBlock(int blockIndex);
  Future<void> updatePreferences(ReaderSpeechPreferences preferences);
  Future<void> previewVoice(ReaderSpeechVoice voice);
  Future<void> setSleepTimer(ReaderSpeechSleepTimer timer);
}

abstract interface class RestorableReaderSpeechController {
  Future<void> restoreSession(
    ReaderSpeechChapterSource Function(ReaderSpeechCheckpoint checkpoint)
    sourceFactory,
  );
}

class ReaderSpeechPlaybackController extends ChangeNotifier
    implements ReaderSpeechController, RestorableReaderSpeechController {
  ReaderSpeechPlaybackController({
    required ReaderTextToSpeechEngine engine,
    required ReaderSpeechRepository repository,
    Duration pauseTimeout = const Duration(minutes: 10),
    Map<ReaderSpeechSleepTimer, Duration> sleepTimerDurations = const {},
  }) : _engine = engine,
       _repository = repository,
       _pauseTimeout = pauseTimeout,
       _sleepTimerDurations = sleepTimerDurations {
    _progressSubscription = _engine.progress.listen(_applyProgress);
  }

  final ReaderTextToSpeechEngine _engine;
  final ReaderSpeechRepository _repository;
  final Duration _pauseTimeout;
  final Map<ReaderSpeechSleepTimer, Duration> _sleepTimerDurations;

  late final StreamSubscription<ReaderSpeechProgress> _progressSubscription;
  ReaderSpeechChapterSource? _boundChapterSource;
  ReaderSpeechChapterSource? _sessionChapterSource;
  ReaderSpeechState _value = ReaderSpeechState.idle;
  List<ReaderSpeechVoice> _availableVoices = const [];
  ReaderSpeechChapter? _chapter;
  Future<_ReaderSpeechPrefetchResult>? _prefetchedNextChapter;
  Timer? _pauseTimer;
  Timer? _sleepTimerClock;
  ReaderSpeechSleepTimer _sleepTimer = ReaderSpeechSleepTimer.off;
  DateTime? _sleepTimerEndsAt;
  int _queueIndex = 0;
  int _characterOffset = 0;
  int _activeChunkStart = 0;
  int _maxInputLength = 4000;
  int _generation = 0;
  bool _shouldPlay = false;
  bool _pauseAtChunkBoundary = false;
  bool _announceChapterTitle = false;
  String? _noticeMessage;

  @override
  ReaderSpeechState get value => _value;

  @override
  ReaderSpeechPreferences get preferences => _repository.value;

  @override
  List<ReaderSpeechVoice> get availableVoices => _availableVoices;

  @override
  ReaderSpeechSleepTimer get sleepTimer => _sleepTimer;

  @override
  DateTime? get sleepTimerEndsAt => _sleepTimerEndsAt;

  @override
  void bindChapterSource(ReaderSpeechChapterSource source) {
    _boundChapterSource = source;
  }

  @override
  Future<void> prepareChapter(
    ReaderSpeechChapter chapter, {
    int? visibleBlockIndex,
  }) async {
    final generation = ++_generation;
    _shouldPlay = false;
    try {
      await _engine.stop();
      if (!_isCurrent(generation)) return;
      await _repository.load();
      if (!_isCurrent(generation)) return;
      _chapter = chapter;
      _sessionChapterSource = _boundChapterSource;
      _prefetchedNextChapter = null;
      if (chapter.blocks.isEmpty) {
        _publishError('لا يوجد نص قابل للقراءة الصوتية في هذا الفصل.');
        return;
      }
      _restorePosition(chapter, visibleBlockIndex ?? 0);
      _publishState(ReaderSpeechStatus.paused);
    } on ReaderSpeechEngineException catch (error) {
      if (_isCurrent(generation)) _publishError(error.message);
    } on Exception {
      if (_isCurrent(generation)) {
        _publishError('تعذر تجهيز الفصل للقراءة الصوتية. حاول مرة أخرى.');
      }
    }
  }

  @override
  Future<void> restoreSession(
    ReaderSpeechChapterSource Function(ReaderSpeechCheckpoint checkpoint)
    sourceFactory,
  ) async {
    if (_chapter != null) return;
    final restorationGeneration = _generation;
    try {
      await _repository.load();
      if (_chapter != null || restorationGeneration != _generation) return;
      final checkpoint = _repository.checkpoint;
      if (checkpoint == null || checkpoint.contentApi.trim().isEmpty) return;
      final source = sourceFactory(checkpoint);
      final chapter = await source.loadChapter(checkpoint.contentApi);
      if (_chapter != null || restorationGeneration != _generation) return;
      if (!_checkpointMatchesChapter(checkpoint, chapter)) return;
      bindChapterSource(source);
      await prepareChapter(chapter);
    } on Exception {
      // Restoration is best-effort; opening the reader can prepare it again.
    }
  }

  @override
  Future<void> play() async {
    if (_chapter == null || _shouldPlay) return;
    final generation = ++_generation;
    _shouldPlay = false;
    _cancelPauseTimer();
    _publishState(ReaderSpeechStatus.loading);
    try {
      await _configureEngine();
    } on ReaderSpeechEngineException catch (error) {
      if (_isCurrent(generation)) _publishError(error.message);
      return;
    } on Exception {
      if (_isCurrent(generation)) {
        _publishError('تعذر تجهيز محرك القراءة الصوتية. حاول مرة أخرى.');
      }
      return;
    }
    if (!_isCurrent(generation)) return;
    _shouldPlay = true;
    _publishState(ReaderSpeechStatus.playing);
    _prefetchNextChapterIfNeeded();
    _startSpeakingLoop(generation);
  }

  @override
  Future<void> pause() async {
    if (_chapter == null) return;
    final generation = ++_generation;
    _shouldPlay = false;
    try {
      await _engine.stop();
      if (!_isCurrent(generation)) return;
      await _saveCheckpoint();
      if (!_isCurrent(generation)) return;
      _publishState(ReaderSpeechStatus.paused);
      _schedulePauseTimeout();
    } on ReaderSpeechEngineException catch (error) {
      if (_isCurrent(generation)) _publishError(error.message);
    } on Exception {
      if (_isCurrent(generation)) {
        _publishError('تعذر إيقاف القراءة الصوتية مؤقتًا.');
      }
    }
  }

  @override
  Future<void> stop() async {
    final generation = ++_generation;
    _shouldPlay = false;
    _cancelTimers();
    try {
      await _engine.stop();
      if (!_isCurrent(generation)) return;
      await _saveCheckpoint();
      if (_isCurrent(generation)) _publishState(ReaderSpeechStatus.idle);
    } on ReaderSpeechEngineException catch (error) {
      if (_isCurrent(generation)) _publishError(error.message);
    } on Exception {
      if (_isCurrent(generation)) {
        _publishError('تعذر إيقاف القراءة الصوتية بأمان.');
      }
    }
  }

  @override
  Future<void> skipPreviousBlock() async {
    if (_chapter == null) return;
    final nextIndex = _queueIndex > 0 ? _queueIndex - 1 : 0;
    await _moveToQueueIndex(nextIndex);
  }

  @override
  Future<void> skipNextBlock() async {
    final chapter = _chapter;
    if (chapter == null) return;
    if (_queueIndex + 1 >= chapter.blocks.length) return;
    await _moveToQueueIndex(_queueIndex + 1);
  }

  @override
  Future<void> startFromBlock(int blockIndex) async {
    final chapter = _chapter;
    if (chapter == null) return;
    final nextIndex = chapter.blocks.indexWhere(
      (block) => block.sourceIndex >= blockIndex,
    );
    await _moveToQueueIndex(nextIndex < 0 ? 0 : nextIndex);
  }

  @override
  Future<void> updatePreferences(ReaderSpeechPreferences preferences) async {
    final wasPlaying = _shouldPlay;
    final voiceChanged =
        preferences.engineId != this.preferences.engineId ||
        preferences.voiceName != this.preferences.voiceName ||
        preferences.voiceLocale != this.preferences.voiceLocale;
    final generation = ++_generation;
    _shouldPlay = false;
    try {
      if (wasPlaying) await _engine.stop();
      if (!_isCurrent(generation)) return;
      await _repository.updatePreferences(preferences);
      if (!_isCurrent(generation)) return;
      if (voiceChanged) _noticeMessage = null;
      notifyListeners();
      if (!wasPlaying) return;
      _characterOffset = 0;
      await _configureEngine();
      if (!_isCurrent(generation)) return;
      _shouldPlay = true;
      _publishState(ReaderSpeechStatus.playing);
      _startSpeakingLoop(generation);
    } on ReaderSpeechEngineException catch (error) {
      if (_isCurrent(generation)) _publishError(error.message);
    } on Exception {
      if (_isCurrent(generation)) {
        _publishError('تعذر تطبيق إعدادات القراءة الصوتية.');
      }
    }
  }

  @override
  Future<void> previewVoice(ReaderSpeechVoice voice) async {
    final wasPlaying = _shouldPlay;
    if (wasPlaying) await pause();
    try {
      await _engine.selectVoice(voice);
      await _engine.setRateMultiplier(preferences.rate);
      await _engine.speak('مرحبًا بك في القراءة الصوتية من مجرة الروايات.');
    } on ReaderSpeechInterruptedException {
      return;
    } on ReaderSpeechEngineException catch (error) {
      _publishError(error.message);
    }
  }

  @override
  Future<void> setSleepTimer(ReaderSpeechSleepTimer timer) async {
    _sleepTimerClock?.cancel();
    _sleepTimer = timer;
    _sleepTimerEndsAt = _timerEnd(timer);
    _pauseAtChunkBoundary = false;
    final duration = _timerDuration(timer);
    if (duration != null) {
      _sleepTimerClock = Timer(duration, () => _pauseAtChunkBoundary = true);
    }
    notifyListeners();
  }

  Future<void> _configureEngine() async {
    final savedVoiceId = _savedVoiceId(preferences);
    await _engine.initialize();
    _availableVoices = await _engine.discoverVoices();
    final voice = _requiredVoice();
    await _engine.selectVoice(voice);
    final selectedVoice = _engine.selectedVoice ?? voice;
    if (savedVoiceId != null && selectedVoice.id != savedVoiceId) {
      _noticeMessage =
          'لم يعد الصوت المحفوظ متاحًا؛ تم اختيار أفضل صوت عربي يعمل دون إنترنت.';
    }
    await _persistSelectedVoice(selectedVoice);
    await _engine.setRateMultiplier(preferences.rate);
    _maxInputLength = await _engine.maxInputLength();
    notifyListeners();
  }

  ReaderSpeechVoice _requiredVoice() {
    final voice = resolveReaderSpeechVoice(_availableVoices, preferences);
    if (voice != null) return voice;
    throw const ReaderSpeechEngineException(
      'لم يتم العثور على صوت عربي. نزّل صوتًا عربيًا من إعدادات الهاتف.',
    );
  }

  Future<void> _persistSelectedVoice(ReaderSpeechVoice voice) async {
    if (preferences.engineId == voice.engineId &&
        preferences.voiceName == voice.name &&
        preferences.voiceLocale == voice.locale) {
      return;
    }
    await _repository.updatePreferences(
      preferences.copyWith(
        engineId: voice.engineId,
        voiceName: voice.name,
        voiceLocale: voice.locale,
      ),
    );
  }

  void _startSpeakingLoop(int generation) {
    unawaited(_speakUntilStopped(generation));
  }

  Future<void> _speakUntilStopped(int generation) async {
    try {
      while (_canContinue(generation)) {
        await _announceTitleIfNeeded(generation);
        if (!_canContinue(generation)) return;
        await _speakCurrentBlock(generation);
        if (!_canContinue(generation)) return;
        await _completeCurrentBlock(generation);
      }
    } on ReaderSpeechInterruptedException {
      return;
    } on ReaderSpeechEngineException catch (error) {
      await _finishWithError(error.message, generation);
    } on Exception {
      await _finishWithError(
        'تعذر متابعة القراءة الصوتية. حاول مرة أخرى.',
        generation,
      );
    }
  }

  Future<void> _speakCurrentBlock(int generation) async {
    final chapter = _chapter!;
    final block = chapter.blocks[_queueIndex];
    final chunks = splitReaderSpeechBlock(
      block,
      maxInputLength: _maxInputLength,
    );
    for (final chunk in chunks) {
      if (!_canContinue(generation) || chunk.end <= _characterOffset) continue;
      final speechStart = _characterOffset.clamp(chunk.start, chunk.end);
      _activeChunkStart = speechStart;
      await _engine.speak(block.text.substring(speechStart, chunk.end));
      if (!_canContinue(generation)) return;
      _characterOffset = chunk.end;
      final selectedVoice = _engine.selectedVoice;
      if (selectedVoice != null) {
        await _persistSelectedVoice(selectedVoice);
        if (!_canContinue(generation)) return;
      }
      if (_pauseAtChunkBoundary) {
        await pause();
        return;
      }
    }
  }

  Future<void> _completeCurrentBlock(int generation) async {
    await _saveCheckpoint();
    if (!_canContinue(generation)) return;
    final chapter = _chapter!;
    if (_queueIndex + 1 < chapter.blocks.length) {
      _queueIndex += 1;
      _characterOffset = 0;
      _publishState(ReaderSpeechStatus.playing);
      _prefetchNextChapterIfNeeded();
      return;
    }
    await _completeChapter(generation);
  }

  Future<void> _completeChapter(int generation) async {
    if (_sleepTimer == ReaderSpeechSleepTimer.endOfChapter ||
        !preferences.autoNextChapter) {
      await stop();
      return;
    }
    ReaderSpeechChapter? nextChapter;
    try {
      nextChapter = await _nextChapter();
    } on _ReaderSpeechChapterLoadException {
      if (_canContinue(generation)) {
        _prefetchedNextChapter = null;
        _publishError('تعذر تحميل الفصل التالي. حاول مرة أخرى من القارئ.');
      }
      return;
    }
    if (!_canContinue(generation)) return;
    if (nextChapter == null) {
      if (_value.status != ReaderSpeechStatus.error) await stop();
      return;
    }
    final source = _sessionChapterSource;
    if (source != null) {
      await source.didStartChapter(nextChapter);
      if (!_canContinue(generation)) return;
    }
    _chapter = nextChapter;
    _queueIndex = 0;
    _characterOffset = 0;
    _prefetchedNextChapter = null;
    _announceChapterTitle = true;
    _publishState(ReaderSpeechStatus.playing);
    _prefetchNextChapterIfNeeded();
  }

  Future<ReaderSpeechChapter?> _nextChapter() async {
    final chapter = _chapter!;
    final source = _sessionChapterSource;
    if (chapter.nextContentApi.isEmpty || source == null) return null;
    final prefetched = _prefetchedNextChapter;
    if (prefetched != null) {
      final result = await prefetched;
      if (result.chapter != null) return result.chapter;
      throw const _ReaderSpeechChapterLoadException();
    }
    try {
      return await source.loadChapter(chapter.nextContentApi);
    } on Exception {
      throw const _ReaderSpeechChapterLoadException();
    }
  }

  Future<void> _announceTitleIfNeeded(int generation) async {
    if (!_announceChapterTitle || !_canContinue(generation)) return;
    _announceChapterTitle = false;
    final title = _chapter?.chapterTitle.trim() ?? '';
    if (title.isNotEmpty) await _engine.speak(title);
  }

  void _prefetchNextChapterIfNeeded() {
    final chapter = _chapter!;
    final remaining = chapter.blocks.length - _queueIndex - 1;
    final source = _sessionChapterSource;
    if (_sleepTimer == ReaderSpeechSleepTimer.endOfChapter ||
        !preferences.autoNextChapter ||
        remaining > 5 ||
        source == null ||
        chapter.nextContentApi.isEmpty ||
        _prefetchedNextChapter != null) {
      return;
    }
    _prefetchedNextChapter = source
        .loadChapter(chapter.nextContentApi)
        .then(
          _ReaderSpeechPrefetchResult.success,
          onError: (Object error, StackTrace stackTrace) {
            if (error is Exception) {
              return const _ReaderSpeechPrefetchResult.failure();
            }
            Error.throwWithStackTrace(error, stackTrace);
          },
        );
  }

  Future<void> _moveToQueueIndex(int nextIndex) async {
    final wasPlaying = _shouldPlay;
    final generation = ++_generation;
    _shouldPlay = false;
    try {
      await _engine.stop();
      if (!_isCurrent(generation)) return;
      _queueIndex = nextIndex;
      _characterOffset = 0;
      await _saveCheckpoint();
      if (!_isCurrent(generation)) return;
      _publishState(
        wasPlaying ? ReaderSpeechStatus.playing : ReaderSpeechStatus.paused,
      );
      if (wasPlaying) {
        _shouldPlay = true;
        _startSpeakingLoop(generation);
      }
    } on ReaderSpeechEngineException catch (error) {
      if (_isCurrent(generation)) _publishError(error.message);
    } on Exception {
      if (_isCurrent(generation)) {
        _publishError('تعذر الانتقال إلى الفقرة المطلوبة.');
      }
    }
  }

  void _restorePosition(ReaderSpeechChapter chapter, int visibleBlockIndex) {
    final checkpoint = _repository.checkpoint;
    if (checkpoint != null && _checkpointMatchesChapter(checkpoint, chapter)) {
      _queueIndex = _queueIndexForSource(chapter, checkpoint.blockIndex);
      _characterOffset = checkpoint.characterOffset.clamp(
        0,
        chapter.blocks[_queueIndex].text.length,
      );
      return;
    }
    _queueIndex = _queueIndexForSource(chapter, visibleBlockIndex);
    _characterOffset = 0;
  }

  int _queueIndexForSource(ReaderSpeechChapter chapter, int sourceIndex) {
    final index = chapter.blocks.indexWhere(
      (block) => block.sourceIndex >= sourceIndex,
    );
    return index < 0 ? 0 : index;
  }

  void _applyProgress(ReaderSpeechProgress progress) {
    if (!_shouldPlay || _chapter == null) return;
    final block = _chapter!.blocks[_queueIndex];
    _characterOffset = (_activeChunkStart + progress.start).clamp(
      0,
      block.text.length,
    );
    _value = _value.copyWith(
      blockIndex: block.sourceIndex,
      characterStart: _characterOffset,
      characterEnd: (_activeChunkStart + progress.end).clamp(
        _characterOffset,
        block.text.length,
      ),
      clearError: true,
    );
    notifyListeners();
  }

  Future<void> _saveCheckpoint() async {
    final chapter = _chapter;
    if (chapter == null || chapter.blocks.isEmpty) return;
    final queueIndex = _queueIndex.clamp(0, chapter.blocks.length - 1);
    final checkpoint = ReaderSpeechCheckpoint(
      novelId: chapter.novelId,
      chapterId: chapter.chapterId,
      contentApi: chapter.contentApi,
      blockIndex: chapter.blocks[queueIndex].sourceIndex,
      characterOffset: _characterOffset,
      contentFingerprint: chapter.contentFingerprint,
      novelTitle: chapter.novelTitle,
      chapterTitle: chapter.chapterTitle,
      coverUrl: chapter.coverUrl,
    );
    await _repository.saveCheckpoint(checkpoint);
  }

  Future<void> _finishWithError(String message, int generation) async {
    if (!_isCurrent(generation)) return;
    _shouldPlay = false;
    try {
      await _saveCheckpoint();
    } on Exception {
      // The playback failure remains the actionable error for the user.
    }
    if (_isCurrent(generation)) _publishError(message);
  }

  void _publishState(ReaderSpeechStatus status) {
    final chapter = _chapter;
    final block = chapter == null || chapter.blocks.isEmpty
        ? null
        : chapter.blocks[_queueIndex];
    _value = ReaderSpeechState(
      status: status,
      chapter: chapter,
      blockIndex: block?.sourceIndex ?? 0,
      characterStart: _characterOffset,
      characterEnd: _characterOffset,
      errorMessage: null,
      noticeMessage: _noticeMessage,
    );
    notifyListeners();
  }

  void _publishError(String message) {
    _shouldPlay = false;
    _value = _value.copyWith(
      status: ReaderSpeechStatus.error,
      errorMessage: message,
      noticeMessage: _noticeMessage,
    );
    notifyListeners();
  }

  bool _canContinue(int generation) =>
      _shouldPlay && generation == _generation && _chapter != null;

  bool _isCurrent(int generation) => generation == _generation;

  void _schedulePauseTimeout() {
    _cancelPauseTimer();
    _pauseTimer = Timer(_pauseTimeout, () => unawaited(stop()));
  }

  void _cancelPauseTimer() {
    _pauseTimer?.cancel();
    _pauseTimer = null;
  }

  void _cancelTimers() {
    _cancelPauseTimer();
    _sleepTimerClock?.cancel();
    _sleepTimerClock = null;
    _sleepTimer = ReaderSpeechSleepTimer.off;
    _sleepTimerEndsAt = null;
    _pauseAtChunkBoundary = false;
  }

  DateTime? _timerEnd(ReaderSpeechSleepTimer timer) {
    final duration = _timerDuration(timer);
    return duration == null ? null : DateTime.now().add(duration);
  }

  Duration? _timerDuration(ReaderSpeechSleepTimer timer) {
    final overridden = _sleepTimerDurations[timer];
    if (overridden != null) return overridden;
    return switch (timer) {
      ReaderSpeechSleepTimer.minutes15 => const Duration(minutes: 15),
      ReaderSpeechSleepTimer.minutes30 => const Duration(minutes: 30),
      ReaderSpeechSleepTimer.minutes60 => const Duration(minutes: 60),
      ReaderSpeechSleepTimer.off || ReaderSpeechSleepTimer.endOfChapter => null,
    };
  }

  @override
  void dispose() {
    _cancelTimers();
    unawaited(_progressSubscription.cancel());
    unawaited(_engine.stop());
    super.dispose();
  }
}

class _ReaderSpeechPrefetchResult {
  const _ReaderSpeechPrefetchResult.success(this.chapter);
  const _ReaderSpeechPrefetchResult.failure() : chapter = null;

  final ReaderSpeechChapter? chapter;
}

class _ReaderSpeechChapterLoadException implements Exception {
  const _ReaderSpeechChapterLoadException();
}

String _normalizedContentApi(String value) {
  var normalized = value.trim();
  while (normalized.length > 1 && normalized.endsWith('/')) {
    normalized = normalized.substring(0, normalized.length - 1);
  }
  return normalized;
}

String? _savedVoiceId(ReaderSpeechPreferences preferences) {
  final engineId = preferences.engineId;
  final voiceName = preferences.voiceName;
  final voiceLocale = preferences.voiceLocale;
  if (engineId == null || voiceName == null || voiceLocale == null) return null;
  return '$engineId|$voiceName|$voiceLocale';
}

bool _checkpointMatchesChapter(
  ReaderSpeechCheckpoint checkpoint,
  ReaderSpeechChapter chapter,
) {
  return checkpoint.novelId == chapter.novelId &&
      checkpoint.chapterId == chapter.chapterId &&
      _normalizedContentApi(checkpoint.contentApi) ==
          _normalizedContentApi(chapter.contentApi) &&
      checkpoint.contentFingerprint == chapter.contentFingerprint;
}
