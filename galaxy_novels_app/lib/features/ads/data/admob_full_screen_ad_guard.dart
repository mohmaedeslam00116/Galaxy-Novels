class AdMobFullScreenAdGuard {
  AdMobFullScreenAdGuard({DateTime Function()? now})
    : _now = now ?? DateTime.now;

  static final shared = AdMobFullScreenAdGuard();

  bool _isShowing = false;
  final DateTime Function() _now;
  DateTime? _lastShownAt;

  bool tryAcquire() {
    if (_isShowing) {
      return false;
    }
    _isShowing = true;
    return true;
  }

  void release() {
    _isShowing = false;
  }

  void markShown() {
    _lastShownAt = _now().toUtc();
  }

  bool hasElapsed(Duration minimumSpacing) {
    final lastShownAt = _lastShownAt;
    return lastShownAt == null ||
        _now().toUtc().difference(lastShownAt) >= minimumSpacing;
  }
}
