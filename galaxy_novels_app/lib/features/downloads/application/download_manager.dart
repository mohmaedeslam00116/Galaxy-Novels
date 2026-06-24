import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../data/repositories/downloads_repository.dart';

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
  DownloadManager({required DownloadsRepository repository})
    : _repository = repository;

  final DownloadsRepository _repository;
  final ValueNotifier<DownloadManagerState> _state = ValueNotifier(
    const DownloadManagerState(),
  );

  StreamSubscription<DownloadBatchProgress>? _subscription;
  List<ChapterDownloadRequest> _lastRequests = const [];
  Completer<void>? _completion;

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

    _lastRequests = List.unmodifiable(requests);
    final first = requests.first;
    _state.value = DownloadManagerState(
      status: DownloadJobStatus.running,
      progress: DownloadBatchProgress(
        novelTitle: first.novelTitle,
        novelCover: first.novelCover,
        total: requests.length,
        completed: 0,
        failed: 0,
        isComplete: false,
      ),
      isOverlayVisible: showOverlay,
    );

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
    _state.value = DownloadManagerState(
      status: DownloadJobStatus.paused,
      progress: _state.value.progress,
      isOverlayVisible: _state.value.isOverlayVisible,
    );
  }

  void resume() {
    if (_state.value.status != DownloadJobStatus.paused) {
      return;
    }
    _subscription?.resume();
    _state.value = DownloadManagerState(
      status: DownloadJobStatus.running,
      progress: _state.value.progress,
      isOverlayVisible: _state.value.isOverlayVisible,
    );
  }

  Future<void> cancel() async {
    if (!_state.value.isActive) {
      return;
    }
    await _subscription?.cancel();
    _subscription = null;
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
    _completeCurrentJob();
    _state.dispose();
  }

  void _handleProgress(DownloadBatchProgress progress) {
    final status = progress.isComplete
        ? DownloadJobStatus.completed
        : _state.value.status;
    _state.value = DownloadManagerState(
      status: status,
      progress: progress,
      isOverlayVisible: _state.value.isOverlayVisible,
    );
  }

  void _handleError(Object error, StackTrace stackTrace) {
    final progress = _state.value.progress;
    _state.value = DownloadManagerState(
      status: DownloadJobStatus.failed,
      progress: progress,
      isOverlayVisible: true,
      errorMessage: _errorMessage(error),
    );
    _subscription = null;
    _completeCurrentJob(error, stackTrace);
  }

  void _handleDone() {
    final current = _state.value;
    if (current.status == DownloadJobStatus.running ||
        current.status == DownloadJobStatus.paused) {
      _state.value = DownloadManagerState(
        status: DownloadJobStatus.completed,
        progress: current.progress,
        isOverlayVisible: current.isOverlayVisible,
      );
    }
    _subscription = null;
    _completeCurrentJob();
  }

  void _completeCurrentJob([Object? error, StackTrace? stackTrace]) {
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
}

String _errorMessage(Object error) {
  if (error is DownloadLimitExceededException) {
    return 'وصلت إلى حد ${error.maxChapters} فصل محمل';
  }
  return 'تعذر إكمال التنزيل. تحقق من الاتصال ثم أعد المحاولة.';
}
