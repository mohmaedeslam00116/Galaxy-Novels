import 'dart:async';
import 'dart:math';

import '../domain/reading_activity_event.dart';
import '../domain/reading_session_tracker.dart';
import 'reading_activity_recorder.dart';

typedef ReadingActivityEnqueue =
    Future<void> Function(ReadingActivityEvent event);

class TrackedReadingActivitySession implements ReadingActivitySession {
  TrackedReadingActivitySession({
    required this.ownerUserId,
    required this.novelId,
    required this.chapterId,
    required DateTime Function() now,
    required ReadingActivityEnqueue enqueue,
  }) : _now = now,
       _enqueue = enqueue {
    final startedAt = _now();
    _tracker = ReadingSessionTracker(startedAt: startedAt)
      ..recordInteraction(startedAt, progress: 0);
    _startTimer();
  }

  static final Random _random = Random.secure();

  final int ownerUserId;
  final int novelId;
  final int chapterId;
  final DateTime Function() _now;
  final ReadingActivityEnqueue _enqueue;

  late final ReadingSessionTracker _tracker;
  Timer? _timer;
  bool _finished = false;

  @override
  void recordInteraction(int progress) {
    if (_finished) {
      return;
    }
    _tracker.recordInteraction(_now(), progress: progress);
  }

  @override
  Future<void> checkpoint() async {
    if (_finished) {
      return;
    }
    await _emitCheckpoint(_now());
  }

  @override
  Future<void> pause() async {
    if (_finished) {
      return;
    }
    _timer?.cancel();
    _timer = null;
    final pausedAt = _now();
    _tracker.pause(pausedAt);
    await _emitCheckpoint(pausedAt);
  }

  @override
  void resume() {
    if (_finished || _timer != null) {
      return;
    }
    _tracker.resume(_now());
    _startTimer();
  }

  @override
  Future<void> finish() async {
    if (_finished) {
      return;
    }
    _timer?.cancel();
    _timer = null;
    final finishedAt = _now();
    _tracker.pause(finishedAt);
    _finished = true;
    await _emitCheckpoint(finishedAt);
  }

  Future<void> _emitCheckpoint(DateTime readAt) async {
    final delta = _tracker.checkpoint(readAt);
    if (delta == null) {
      return;
    }
    await _enqueue(
      ReadingActivityEvent(
        ownerUserId: ownerUserId,
        eventId: _createEventId(readAt),
        novelId: novelId,
        chapterId: chapterId,
        activeSeconds: delta.activeSeconds,
        openSeconds: delta.openSeconds,
        progress: delta.progress,
        completed: delta.completed,
        views: delta.views,
        readAt: readAt,
      ),
    );
  }

  void _startTimer() {
    _timer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => unawaited(checkpoint()),
    );
  }

  String _createEventId(DateTime readAt) {
    final first = _random.nextInt(1 << 16).toRadixString(16).padLeft(4, '0');
    final second = _random.nextInt(1 << 16).toRadixString(16).padLeft(4, '0');
    return 'app:$ownerUserId:$chapterId:${readAt.toUtc().microsecondsSinceEpoch}:$first$second';
  }
}
