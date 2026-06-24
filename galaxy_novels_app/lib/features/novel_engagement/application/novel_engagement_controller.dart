import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/network/private_api_client.dart';
import '../../account/application/auth_repository.dart';
import '../../account/domain/auth_session.dart';
import '../data/novel_engagement_error_messages.dart';
import '../domain/novel_user_state.dart';
import 'novel_engagement_repository.dart';

enum NovelEngagementStatus { guest, loading, ready, failure }

enum RatingSubmitStatus { saved, signInRequired, busy, failed }

class RatingSubmitOutcome {
  const RatingSubmitOutcome(this.status, {this.errorMessage});

  final RatingSubmitStatus status;
  final String? errorMessage;
}

class NovelEngagementState {
  const NovelEngagementState({
    required this.status,
    required this.novelId,
    this.userId,
    this.userState,
    this.isSubmitting = false,
    this.errorMessage,
  });

  final NovelEngagementStatus status;
  final int novelId;
  final int? userId;
  final NovelUserState? userState;
  final bool isSubmitting;
  final String? errorMessage;

  NovelEngagementState startRatingSubmission() {
    return NovelEngagementState(
      status: status,
      novelId: novelId,
      userId: userId,
      userState: userState,
      isSubmitting: true,
    );
  }

  NovelEngagementState completeRatingSubmission(
    NovelUserState updatedUserState,
  ) {
    return NovelEngagementState(
      status: status,
      novelId: novelId,
      userId: userId,
      userState: updatedUserState,
    );
  }

  NovelEngagementState failRatingSubmission(String message) {
    return NovelEngagementState(
      status: status,
      novelId: novelId,
      userId: userId,
      userState: userState,
      errorMessage: message,
    );
  }
}

class NovelEngagementController extends ChangeNotifier
    implements ValueListenable<NovelEngagementState> {
  NovelEngagementController({
    required NovelEngagementRepository repository,
    required AuthRepository authRepository,
  }) : _repository = repository,
       _authRepository = authRepository {
    _authRepository.addListener(_handleAuthChanged);
  }

  final NovelEngagementRepository _repository;
  final AuthRepository _authRepository;

  NovelEngagementState _value = const NovelEngagementState(
    status: NovelEngagementStatus.guest,
    novelId: 0,
  );
  Future<void>? _loadFuture;
  int? _loadUserId;
  int? _loadNovelId;
  int _novelId = 0;
  int _generation = 0;
  bool _disposed = false;

  @override
  NovelEngagementState get value => _value;

  Future<void> loadNovel(int novelId) {
    if (novelId <= 0) {
      return Future.error(RangeError.value(novelId, 'novelId'));
    }
    final sameReadyNovel =
        _novelId == novelId &&
        _value.novelId == novelId &&
        _value.status == NovelEngagementStatus.ready &&
        _value.userId == _authenticatedUserId;
    _novelId = novelId;
    if (sameReadyNovel) {
      return Future.value();
    }
    return _reload(force: true);
  }

  Future<void> retry() {
    if (_novelId <= 0) {
      return Future.value();
    }
    return _reload(force: true);
  }

  Future<RatingSubmitOutcome> submitRating(int rating) async {
    final userId = _authenticatedUserId;
    final current = _value;
    if (userId == null ||
        current.userId != userId ||
        current.userState == null) {
      return const RatingSubmitOutcome(RatingSubmitStatus.signInRequired);
    }
    if (current.isSubmitting) {
      return const RatingSubmitOutcome(RatingSubmitStatus.busy);
    }
    if (rating < 1 || rating > 5) {
      return const RatingSubmitOutcome(
        RatingSubmitStatus.failed,
        errorMessage: 'اختر تقييمًا من نجمة إلى خمس نجوم.',
      );
    }

    final novelId = current.novelId;
    final generation = _generation;
    _publish(current.startRatingSubmission());

    try {
      final savedRating = await _repository.submitRating(
        novelId: novelId,
        rating: rating,
      );
      if (!_isCurrent(novelId, userId, generation)) {
        return const RatingSubmitOutcome(RatingSubmitStatus.failed);
      }
      final userState = _value.userState;
      if (userState == null) {
        return const RatingSubmitOutcome(RatingSubmitStatus.failed);
      }
      _publish(
        _value.completeRatingSubmission(
          userState.copyWith(myRating: savedRating),
        ),
      );
      return const RatingSubmitOutcome(RatingSubmitStatus.saved);
    } on PrivateApiException catch (error) {
      final message = novelEngagementMessageFor(error);
      if (error.statusCode == 401 || error.statusCode == 403) {
        await _authRepository.restoreSession();
      }
      _finishFailedSubmit(novelId, userId, generation, message);
      return RatingSubmitOutcome(
        RatingSubmitStatus.failed,
        errorMessage: message,
      );
    } on FormatException {
      const message = 'أعاد الموقع تقييمًا غير صالح. حاول مجددًا.';
      _finishFailedSubmit(novelId, userId, generation, message);
      return const RatingSubmitOutcome(
        RatingSubmitStatus.failed,
        errorMessage: message,
      );
    }
  }

  Future<void> _reload({required bool force}) {
    final novelId = _novelId;
    if (_disposed || novelId <= 0) {
      return Future.value();
    }
    final userId = _authenticatedUserId;
    if (userId == null) {
      _generation++;
      _loadFuture = null;
      _loadUserId = null;
      _loadNovelId = null;
      _publish(
        NovelEngagementState(
          status: NovelEngagementStatus.guest,
          novelId: novelId,
        ),
      );
      return Future.value();
    }

    final inFlight = _loadFuture;
    if (inFlight != null && _loadUserId == userId && _loadNovelId == novelId) {
      return inFlight;
    }
    if (!force &&
        _value.status == NovelEngagementStatus.ready &&
        _value.userId == userId &&
        _value.novelId == novelId) {
      return Future.value();
    }

    final generation = ++_generation;
    _publish(
      NovelEngagementState(
        status: NovelEngagementStatus.loading,
        novelId: novelId,
        userId: userId,
      ),
    );

    late final Future<void> load;
    load = _performLoad(novelId, userId, generation).whenComplete(() {
      if (identical(_loadFuture, load)) {
        _loadFuture = null;
        _loadUserId = null;
        _loadNovelId = null;
      }
    });
    _loadFuture = load;
    _loadUserId = userId;
    _loadNovelId = novelId;
    return load;
  }

  Future<void> _performLoad(int novelId, int userId, int generation) async {
    try {
      final userState = await _repository.loadState(novelId);
      if (!_isCurrent(novelId, userId, generation)) {
        return;
      }
      _publish(
        NovelEngagementState(
          status: NovelEngagementStatus.ready,
          novelId: novelId,
          userId: userId,
          userState: userState,
        ),
      );
    } on PrivateApiException catch (error) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        await _authRepository.restoreSession();
      }
      if (!_isCurrent(novelId, userId, generation)) {
        return;
      }
      _publish(
        NovelEngagementState(
          status: NovelEngagementStatus.failure,
          novelId: novelId,
          userId: userId,
          errorMessage: novelEngagementMessageFor(error),
        ),
      );
    } on FormatException {
      if (!_isCurrent(novelId, userId, generation)) {
        return;
      }
      _publish(
        NovelEngagementState(
          status: NovelEngagementStatus.failure,
          novelId: novelId,
          userId: userId,
          errorMessage: 'تعذر قراءة حالتك مع الرواية.',
        ),
      );
    }
  }

  void _finishFailedSubmit(
    int novelId,
    int userId,
    int generation,
    String message,
  ) {
    if (!_isCurrent(novelId, userId, generation)) {
      return;
    }
    _publish(_value.failRatingSubmission(message));
  }

  int? get _authenticatedUserId {
    final session = _authRepository.value;
    return session.status == AuthSessionStatus.authenticated
        ? session.user?.id
        : null;
  }

  bool _isCurrent(int novelId, int userId, int generation) {
    return !_disposed &&
        _generation == generation &&
        _novelId == novelId &&
        _authenticatedUserId == userId;
  }

  void _handleAuthChanged() {
    if (_disposed || _novelId <= 0) {
      return;
    }
    final userId = _authenticatedUserId;
    if (_value.userId == userId &&
        (_value.status == NovelEngagementStatus.loading ||
            _value.status == NovelEngagementStatus.ready)) {
      return;
    }
    unawaited(_reload(force: true));
  }

  void _publish(NovelEngagementState next) {
    if (_disposed) {
      return;
    }
    _value = next;
    notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _generation++;
    _authRepository.removeListener(_handleAuthChanged);
    super.dispose();
  }
}
