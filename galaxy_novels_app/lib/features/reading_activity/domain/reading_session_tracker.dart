class ReadingActivityDelta {
  const ReadingActivityDelta({
    required this.activeSeconds,
    required this.openSeconds,
    required this.progress,
    required this.completed,
    required this.views,
  });

  final int activeSeconds;
  final int openSeconds;
  final int progress;
  final bool completed;
  final int views;
}

class ReadingSessionTracker {
  ReadingSessionTracker({
    required DateTime startedAt,
    this.inactivityTimeout = const Duration(seconds: 60),
  }) : _lastSampleAt = startedAt,
       _activeUntil = startedAt;

  final Duration inactivityTimeout;

  DateTime _lastSampleAt;
  DateTime _activeUntil;
  bool _foreground = true;
  int _openMilliseconds = 0;
  int _activeMilliseconds = 0;
  int _progress = 0;
  int _sentProgress = 0;
  bool _viewPending = true;
  bool _completedSent = false;

  void recordInteraction(DateTime now, {required int progress}) {
    _accrue(now);
    _progress = _progress > progress ? _progress : progress.clamp(0, 100);
    if (_foreground) {
      _activeUntil = now.add(inactivityTimeout);
    }
  }

  void pause(DateTime now) {
    _accrue(now);
    _foreground = false;
    _activeUntil = now;
  }

  void resume(DateTime now) {
    if (now.isAfter(_lastSampleAt)) {
      _lastSampleAt = now;
    }
    _foreground = true;
    _activeUntil = now;
  }

  ReadingActivityDelta? checkpoint(DateTime now) {
    _accrue(now);
    final activeSeconds = _activeMilliseconds ~/ 1000;
    final openSeconds = _openMilliseconds ~/ 1000;
    final progressChanged = _progress > _sentProgress;
    final completed = _progress >= 92 && !_completedSent;
    if (!_viewPending && activeSeconds <= 0 && !progressChanged && !completed) {
      return null;
    }

    final delta = ReadingActivityDelta(
      activeSeconds: activeSeconds.clamp(0, 300),
      openSeconds: openSeconds.clamp(0, 900),
      progress: _progress,
      completed: completed,
      views: _viewPending ? 1 : 0,
    );
    _activeMilliseconds = 0;
    _openMilliseconds = 0;
    _sentProgress = _progress;
    _viewPending = false;
    if (completed) {
      _completedSent = true;
    }
    return delta;
  }

  void _accrue(DateTime now) {
    if (!now.isAfter(_lastSampleAt)) {
      return;
    }
    if (_foreground) {
      _openMilliseconds += now.difference(_lastSampleAt).inMilliseconds;
      final activeEnd = now.isBefore(_activeUntil) ? now : _activeUntil;
      if (activeEnd.isAfter(_lastSampleAt)) {
        _activeMilliseconds += activeEnd
            .difference(_lastSampleAt)
            .inMilliseconds;
      }
    }
    _lastSampleAt = now;
  }
}
