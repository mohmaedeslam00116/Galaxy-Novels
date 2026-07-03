import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../data/repositories/downloads_repository.dart';
import '../../rewards/application/reader_rewards_repository.dart';
import 'download_progress_notifier.dart';

enum DownloadJobStatus { idle, running, paused, completed, failed, cancelled }

class DownloadJobInProgressException implements Exception {
  const DownloadJobInProgressException();

  @override
  String toString() => 'DownloadJobInProgressException';
}

class DownloadManagerState {
  const DownloadManagerState({
    this.status = DownloadJobStatus.idle,
    this.progress,
    this.isOverlayVisible = false,
    this.errorMessage,
  });

  final DownloadJobStatus status;
  final DownloadBatchProgress? progress;
  final bool isOverlayVisible;
  final String? errorMessage;

  bool get isActive =>
      status == DownloadJobStatus.running || status == DownloadJobStatus.paused;

  bool get canRetry =>
      status == DownloadJobStatus.failed ||
      (status == DownloadJobStatus.completed && (progress?.failed ?? 0) > 0);
}

class DownloadManager {
  DownloadManager({
    required DownloadsRepository repository,
    ReaderRewardsRepository rewardsRepository =
        const NoopReaderRewardsRepository(),
    DownloadProgressNotifier progressNotifier =
        const NoopDownloadProgressNotifier(),
  }) : _repository = repository,
       _rewardsRepository = rewardsRepository,
       _progressNotifier = progressNotifier;

  final DownloadsRepository _repository;
  final ReaderRewardsRepository _rewardsRepository;
  final DownloadProgressNotifier _progressNotifier;
  final ValueNotifier<DownloadManagerState> _state = ValueNotifier(
    const DownloadManagerState(),
  );

  StreamSubscription<DownloadBatchProgress>? _subscription;
  List<ChapterDownloadRequest> _lastRequests = const [];
  Completer<void>? _completion;
  int _reservedDownloadPoints = 0;
  int _refundedDownloadPoints = 0;

  ValueListenable<DownloadManagerState> get state => _state;

  Future<void> downloadChapter(ChapterDownloadRequest request) {
    return startBatch([request], showOverlay: false);
  }

  Future<void> startBatch(
    List<ChapterDownloadRequest> requests, {
    bool showOverlay = true,
  }) {
    if (_state.value.isActive) {
      throw const DownloadJobInProgressException();
    }
    if (requests.isEmpty) {
      return Future.value();
    }

    final chargeableDownloadCount = _chargeableDownloadCount(requests);
    _rewardsRepository.spendForDownload(chargeableDownloadCount);
    _reservedDownloadPoints = chargeableDownloadCount;
    _refundedDownloadPoints = 0;

    _lastRequests = List.unmodifiable(requests);
    final first = requests.first;
    final initialProgress = DownloadBatchProgress(
      novelTitle: first.novelTitle,
      novelCover: first.novelCover,
      total: requests.length,
      completed: 0,
      failed: 0,
      isComplete: false,
    );
    _state.value = DownloadManagerState(
      status: DownloadJobStatus.running,
      progress: initialProgress,
      isOverlayVisible: showOverlay,
    );
    _notifyRunning(initialProgress, isPaused: false);

    final completion = Completer<void>();
    _completion = completion;
    _subscription = _repository
        .downloadChaptersBatch(requests)
        .listen(
          _handleProgress,
          onError: _handleError,
          onDone: _handleDone,
          cancelOnError: true,
        );
    return completion.future;
  }

  void pause() {
    if (_state.value.status != DownloadJobStatus.running) {
      return;
    }
    _subscription?.pause();
    final progress = _state.value.progress;
    _state.value = DownloadManagerState(
      status: DownloadJobStatus.paused,
      progress: progress,
      isOverlayVisible: _state.value.isOverlayVisible,
    );
    if (progress != null) {
      _notifyRunning(progress, isPaused: true);
    }
  }

  void resume() {
    if (_state.value.status != DownloadJobStatus.paused) {
      return;
    }
    _subscription?.resume();
    final progress = _state.value.progress;
    _state.value = DownloadManagerState(
      status: DownloadJobStatus.running,
      progress: progress,
      isOverlayVisible: _state.value.isOverlayVisible,
    );
    if (progress != null) {
      _notifyRunning(progress, isPaused: false);
    }
  }

  Future<void> cancel() async {
    if (!_state.value.isActive) {
      return;
    }
    await _subscription?.cancel();
    _subscription = null;
    _refundOutstandingDownloadPoints();
    unawaited(_progressNotifier.clear());
    _state.value = DownloadManagerState(
      status: DownloadJobStatus.cancelled,
      progress: _state.value.progress,
      isOverlayVisible: _state.value.isOverlayVisible,
    );
    _completeCurrentJob();
  }

  Future<void> retry() {
    if (!_state.value.canRetry || _lastRequests.isEmpty) {
      return Future.value();
    }
    return startBatch(_lastRequests);
  }

  void dismissOverlay() {
    final current = _state.value;
    _state.value = DownloadManagerState(
      status: current.status,
      progress: current.progress,
      errorMessage: current.errorMessage,
    );
  }

  void showOverlay() {
    final current = _state.value;
    if (current.progress == null) {
      return;
    }
    _state.value = DownloadManagerState(
      status: current.status,
      progress: current.progress,
      errorMessage: current.errorMessage,
      isOverlayVisible: true,
    );
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _refundOutstandingDownloadPoints();
    _completeCurrentJob();
    _state.dispose();
  }

  void _handleProgress(DownloadBatchProgress progress) {
    _refundFailedDownloadPoints(progress);
    final status = progress.isComplete
        ? DownloadJobStatus.completed
        : _state.value.status;
    _state.value = DownloadManagerState(
      status: status,
      progress: progress,
      isOverlayVisible: _state.value.isOverlayVisible,
    );
    if (progress.isComplete) {
      unawaited(_progressNotifier.showCompleted(progress));
    } else {
      _notifyRunning(progress, isPaused: status == DownloadJobStatus.paused);
    }
  }

  void _handleError(Object error, StackTrace stackTrace) {
    _refundOutstandingDownloadPoints();
    final progress = _state.value.progress;
    final message = _errorMessage(error);
    _state.value = DownloadManagerState(
      status: DownloadJobStatus.failed,
      progress: progress,
      isOverlayVisible: true,
      errorMessage: message,
    );
    unawaited(
      _progressNotifier.showFailed(progress: progress, message: message),
    );
    _subscription = null;
    _completeCurrentJob(error, stackTrace);
  }

  void _handleDone() {
    _refundOutstandingDownloadPoints();
    final current = _state.value;
    if (current.status == DownloadJobStatus.running ||
        current.status == DownloadJobStatus.paused) {
      _state.value = DownloadManagerState(
        status: DownloadJobStatus.completed,
        progress: current.progress,
        isOverlayVisible: current.isOverlayVisible,
      );
      final progress = current.progress;
      if (progress != null) {
        unawaited(_progressNotifier.showCompleted(progress));
      }
    }
    _subscription = null;
    _completeCurrentJob();
  }

  void _completeCurrentJob([Object? error, StackTrace? stackTrace]) {
    _clearDownloadPointReservation();
    final completion = _completion;
    _completion = null;
    if (completion == null || completion.isCompleted) {
      return;
    }
    if (error != null) {
      completion.completeError(error, stackTrace);
    } else {
      completion.complete();
    }
  }

  int _chargeableDownloadCount(List<ChapterDownloadRequest> requests) {
    final seenContentApis = <String>{};
    var count = 0;
    for (final request in requests) {
      final contentApi = request.chapter.effectiveContentApi;
      if (contentApi.isEmpty ||
          _repository.state.value.contains(contentApi) ||
          !seenContentApis.add(contentApi)) {
        continue;
      }
      count++;
    }
    return count;
  }

  void _refundFailedDownloadPoints(DownloadBatchProgress progress) {
    final failedSinceLastProgress = progress.failed - _refundedDownloadPoints;
    if (failedSinceLastProgress <= 0) {
      return;
    }
    final remainingReservation =
        _reservedDownloadPoints - _refundedDownloadPoints;
    final refundCount = failedSinceLastProgress > remainingReservation
        ? remainingReservation
        : failedSinceLastProgress;
    _refundDownloadPoints(refundCount);
  }

  void _refundOutstandingDownloadPoints() {
    if (_reservedDownloadPoints <= 0) {
      return;
    }

    final progress = _state.value.progress;
    final completedCount = progress?.completed ?? 0;
    final failedCount = progress?.failed ?? 0;
    final unrefundedFailedCount = failedCount - _refundedDownloadPoints;
    final settledCount = completedCount + failedCount;
    final unreportedCount = _reservedDownloadPoints - settledCount;
    _refundDownloadPoints(
      _positive(unrefundedFailedCount) + _positive(unreportedCount),
    );
  }

  void _refundDownloadPoints(int chapterCount) {
    if (chapterCount <= 0) {
      return;
    }
    final remainingReservation =
        _reservedDownloadPoints - _refundedDownloadPoints;
    final refundCount = chapterCount > remainingReservation
        ? remainingReservation
        : chapterCount;
    if (refundCount <= 0) {
      return;
    }
    _rewardsRepository.refundDownloadPoints(refundCount);
    _refundedDownloadPoints += refundCount;
  }

  void _clearDownloadPointReservation() {
    _reservedDownloadPoints = 0;
    _refundedDownloadPoints = 0;
  }

  void _notifyRunning(
    DownloadBatchProgress progress, {
    required bool isPaused,
  }) {
    unawaited(_progressNotifier.showRunning(progress, isPaused: isPaused));
  }
}

String _errorMessage(Object error) {
  if (error is DownloadLimitExceededException) {
    return 'وصلت إلى حد ${error.maxChapters} فصل محمل';
  }
  if (error is InsufficientDownloadPointsException) {
    return 'رصيد النقاط لا يكفي لتحميل الفصول.';
  }
  return 'تعذر إكمال التنزيل. تحقق من الاتصال ثم أعد المحاولة.';
}

int _positive(int value) => value < 0 ? 0 : value;
