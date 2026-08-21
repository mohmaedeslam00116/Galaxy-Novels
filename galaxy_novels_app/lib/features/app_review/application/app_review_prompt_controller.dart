import 'dart:async';

import '../../../core/analytics/app_analytics.dart';
import '../domain/app_review_prompt_state.dart';
import 'app_review_policy_repository.dart';
import 'app_review_prompt_store.dart';
import 'play_app_review_gateway.dart';

enum AppReviewRequestResult {
  notScheduled,
  deferred,
  unavailable,
  requested,
  failed,
}

class AppReviewPromptController {
  AppReviewPromptController({
    required AppReviewPolicyRepository policies,
    required AppReviewPromptStore store,
    required PlayAppReviewGateway play,
    required AppAnalytics analytics,
    DateTime Function()? now,
  }) : _policies = policies,
       _store = store,
       _play = play,
       _analytics = analytics,
       _now = now ?? DateTime.now;

  static const completionThreshold = 92;
  static const unavailableRetryDelay = Duration(days: 7);

  final AppReviewPolicyRepository _policies;
  final AppReviewPromptStore _store;
  final PlayAppReviewGateway _play;
  final AppAnalytics _analytics;
  final DateTime Function() _now;

  AppReviewPromptState? _state;
  final Set<int> _completedChapterIds = <int>{};
  bool _readingSessionActive = false;
  bool _sessionHasCompletion = false;
  bool _sessionHadFullScreenAd = false;
  bool _requestScheduled = false;
  bool _requestInProgress = false;
  Future<void>? _initialization;
  Future<void> _mutationTail = Future<void>.value();

  AppReviewPromptState? get state => _state;
  bool get requestScheduled => _requestScheduled;

  Future<void> initialize() => _initialization ??= _initialize();

  Future<void> _initialize() async {
    await _policies.loadCached();
    _policies.startRealtimeUpdates();
    try {
      await _policies.refresh();
    } on Exception {
      // The cached policy, or safe defaults, remain active offline.
    }
    _state = await _store.read();
    if (_state == null) {
      _state = AppReviewPromptState.initial(_now().toUtc());
      await _store.write(_state!);
    }
  }

  void startReadingSession() {
    _readingSessionActive = true;
    _sessionHasCompletion = false;
    _sessionHadFullScreenAd = false;
    _completedChapterIds.clear();
  }

  Future<void> recordChapterProgress({
    required int chapterId,
    required int progress,
  }) async {
    if (!_readingSessionActive ||
        progress < completionThreshold ||
        !_completedChapterIds.add(chapterId)) {
      return;
    }
    await _ensureInitialized();
    _sessionHasCompletion = true;
    await _mutateState(
      (current) => current.copyWith(
        completedChapterCount: current.completedChapterCount + 1,
      ),
    );
  }

  void markFullScreenAdShown() {
    if (_readingSessionActive) _sessionHadFullScreenAd = true;
  }

  Future<bool> finishReadingSession() async {
    if (!_readingSessionActive) return false;
    _readingSessionActive = false;
    await _ensureInitialized();
    if (_sessionHasCompletion) {
      await _mutateState(
        (current) => current.copyWith(
          qualifyingSessionCount: current.qualifyingSessionCount + 1,
        ),
      );
    }
    final shouldSchedule =
        _sessionHasCompletion &&
        !_sessionHadFullScreenAd &&
        _isEligible(_now().toUtc());
    _sessionHasCompletion = false;
    _sessionHadFullScreenAd = false;
    _completedChapterIds.clear();
    if (shouldSchedule) {
      _requestScheduled = true;
      _log('app_review_eligible');
    }
    return shouldSchedule;
  }

  Future<AppReviewRequestResult> tryRequestReview({
    required bool canPresent,
  }) async {
    await _ensureInitialized();
    if (!_requestScheduled || !_isEligible(_now().toUtc())) {
      return AppReviewRequestResult.notScheduled;
    }
    if (!canPresent || _requestInProgress) {
      return AppReviewRequestResult.deferred;
    }
    final now = _now().toUtc();
    final lastUnavailable = _state!.lastUnavailableAt;
    if (lastUnavailable != null &&
        now.difference(lastUnavailable) < unavailableRetryDelay) {
      return AppReviewRequestResult.deferred;
    }

    _requestInProgress = true;
    try {
      final available = await _play.isAvailable();
      if (!available) {
        await _mutateState(
          (current) => current.copyWith(lastUnavailableAt: now),
        );
        _log('app_review_unavailable');
        return AppReviewRequestResult.unavailable;
      }
      await _play.requestReview();
      await _mutateState(
        (current) => current.copyWith(
          lastAutomaticAttemptAt: now,
          automaticAttemptCount: current.automaticAttemptCount + 1,
          clearLastUnavailable: true,
        ),
      );
      _requestScheduled = false;
      _log('app_review_requested');
      return AppReviewRequestResult.requested;
    } on Exception {
      await _mutateState((current) => current.copyWith(lastUnavailableAt: now));
      _log('app_review_failed');
      return AppReviewRequestResult.failed;
    } finally {
      _requestInProgress = false;
    }
  }

  Future<bool> openStoreListing() async {
    await _ensureInitialized();
    try {
      await _play.openStoreListing();
      final openedAt = _now().toUtc();
      await _mutateState(
        (current) => current.copyWith(lastManualStoreOpenAt: openedAt),
      );
      _requestScheduled = false;
      _log('app_review_store_opened');
      return true;
    } on Exception {
      _log('app_review_store_open_failed');
      return false;
    }
  }

  bool _isEligible(DateTime now) {
    final policy = _policies.value;
    final state = _state;
    if (state == null ||
        !policy.enabled ||
        state.automaticAttemptCount >= policy.maximumAttempts ||
        now.difference(state.firstOpenedAt).inDays < policy.minimumDays ||
        state.completedChapterCount < policy.minimumCompletedChapters ||
        state.qualifyingSessionCount < policy.minimumSessions) {
      return false;
    }
    final lastContact = _laterOf(
      state.lastAutomaticAttemptAt,
      state.lastManualStoreOpenAt,
    );
    return lastContact == null ||
        now.difference(lastContact).inDays >= policy.cooldownDays;
  }

  DateTime? _laterOf(DateTime? first, DateTime? second) {
    if (first == null) return second;
    if (second == null) return first;
    return first.isAfter(second) ? first : second;
  }

  Future<void> _ensureInitialized() async {
    await initialize();
  }

  Future<void> _mutateState(
    AppReviewPromptState Function(AppReviewPromptState current) transform,
  ) {
    final completion = Completer<void>();
    _mutationTail = _mutationTail.then((_) async {
      try {
        await _ensureInitialized();
        final next = transform(_state!);
        await _store.write(next);
        _state = next;
        completion.complete();
      } on Object catch (error, stackTrace) {
        // Complete the caller with the error while keeping later writes usable.
        completion.completeError(error, stackTrace);
      }
    });
    return completion.future;
  }

  void _log(String name) {
    unawaited(_analytics.logEvent(name));
  }

  void dispose() {
    _policies.dispose();
  }
}
