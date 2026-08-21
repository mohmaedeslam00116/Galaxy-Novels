import 'package:flutter/foundation.dart';

import '../../../core/network/private_api_client.dart';
import '../../account/application/auth_repository.dart';
import '../../account/domain/auth_session.dart';
import '../data/comments_error_messages.dart';
import '../domain/comment_interaction.dart';
import '../domain/comment_target.dart';
import '../domain/public_comment.dart';
import 'comments_repository.dart';

enum CommentsStatus { idle, loading, ready, failure }

enum CommentSubmitStatus { saved, signInRequired, busy, failed }

enum CommentInteractionStatus { saved, signInRequired, busy, failed }

class CommentSubmitOutcome {
  const CommentSubmitOutcome(this.status, {this.errorMessage});

  final CommentSubmitStatus status;
  final String? errorMessage;
}

class CommentInteractionOutcome {
  const CommentInteractionOutcome(this.status, {this.errorMessage});

  final CommentInteractionStatus status;
  final String? errorMessage;
}

class CommentsState {
  CommentsState({
    required this.target,
    required this.sort,
    required this.status,
    List<PublicComment> comments = const [],
    this.page = 0,
    this.totalPages = 0,
    this.totalComments = 0,
    Map<CommentReaction, int> reactions = const {},
    this.myReaction,
    this.isLoadingMore = false,
    this.isSubmitting = false,
    this.isInteracting = false,
    this.errorMessage,
    this.loadMoreErrorMessage,
    this.submitErrorMessage,
    this.interactionErrorMessage,
  }) : comments = List<PublicComment>.unmodifiable(comments),
       reactions = Map<CommentReaction, int>.unmodifiable(reactions);

  final CommentTarget target;
  final CommentsSort sort;
  final CommentsStatus status;
  final List<PublicComment> comments;
  final int page;
  final int totalPages;
  final int totalComments;
  final Map<CommentReaction, int> reactions;
  final CommentReaction? myReaction;
  final bool isLoadingMore;
  final bool isSubmitting;
  final bool isInteracting;
  final String? errorMessage;
  final String? loadMoreErrorMessage;
  final String? submitErrorMessage;
  final String? interactionErrorMessage;

  bool get hasNextPage => status == CommentsStatus.ready && page < totalPages;
}

class CommentsController extends ChangeNotifier
    implements ValueListenable<CommentsState> {
  CommentsController({
    required CommentsRepository repository,
    required CommentTarget target,
    AuthRepository? authRepository,
  }) : _repository = repository,
       _authRepository = authRepository,
       _target = target,
       _value = CommentsState(
         target: target,
         sort: CommentsSort.newest,
         status: CommentsStatus.idle,
       );

  final CommentsRepository _repository;
  final AuthRepository? _authRepository;
  final CommentTarget _target;
  CommentsState _value;
  Future<void>? _initialFuture;
  CommentsSort? _initialSort;
  Future<void>? _loadMoreFuture;
  int _loadGeneration = 0;
  bool _disposed = false;

  @override
  CommentsState get value => _value;

  Future<void> loadInitial() {
    if (_value.status == CommentsStatus.ready) {
      return Future.value();
    }
    return _loadFirst(_value.sort);
  }

  Future<void> retry() => _loadFirst(_value.sort, force: true);

  Future<void> changeSort(CommentsSort sort) {
    if (sort == _value.sort) {
      return loadInitial();
    }
    return _loadFirst(sort, force: true);
  }

  Future<void> _loadFirst(CommentsSort sort, {bool force = false}) {
    if (_disposed) {
      return Future.value();
    }
    final active = _initialFuture;
    if (!force && active != null && _initialSort == sort) {
      return active;
    }

    final generation = ++_loadGeneration;
    _loadMoreFuture = null;
    _publish(
      CommentsState(
        target: _target,
        sort: sort,
        status: CommentsStatus.loading,
        isSubmitting: _value.isSubmitting,
        isInteracting: _value.isInteracting,
      ),
    );

    late final Future<void> request;
    request = _performFirst(sort, generation).whenComplete(() {
      if (identical(_initialFuture, request)) {
        _initialFuture = null;
        _initialSort = null;
      }
    });
    _initialFuture = request;
    _initialSort = sort;
    return request;
  }

  Future<void> _performFirst(CommentsSort sort, int generation) async {
    try {
      final page = await _repository.loadPage(
        target: _target,
        sort: sort,
        page: 1,
      );
      if (!_isCurrentLoad(sort, generation)) {
        return;
      }
      _publish(
        CommentsState(
          target: _target,
          sort: sort,
          status: CommentsStatus.ready,
          comments: page.comments,
          page: page.page,
          totalPages: page.totalPages,
          totalComments: page.totalComments,
          reactions: _reactionCountsFromPage(page.reactions),
          isSubmitting: _value.isSubmitting,
          isInteracting: _value.isInteracting,
        ),
      );
    } on Exception catch (error) {
      if (!_isCurrentLoad(sort, generation)) {
        return;
      }
      _publish(
        CommentsState(
          target: _target,
          sort: sort,
          status: CommentsStatus.failure,
          isSubmitting: _value.isSubmitting,
          isInteracting: _value.isInteracting,
          errorMessage: commentsMessageFor(error),
        ),
      );
    }
  }

  Future<void> loadMore() {
    if (_disposed) {
      return Future.value();
    }
    final active = _loadMoreFuture;
    if (active != null) {
      return active;
    }
    final current = _value;
    if (!current.hasNextPage || current.isLoadingMore) {
      return Future.value();
    }

    final generation = _loadGeneration;
    final nextPage = current.page + 1;
    _publish(
      CommentsState(
        target: current.target,
        sort: current.sort,
        status: current.status,
        comments: current.comments,
        page: current.page,
        totalPages: current.totalPages,
        totalComments: current.totalComments,
        reactions: current.reactions,
        myReaction: current.myReaction,
        isLoadingMore: true,
        isSubmitting: current.isSubmitting,
        isInteracting: current.isInteracting,
      ),
    );

    late final Future<void> request;
    request = _performLoadMore(current.sort, nextPage, generation).whenComplete(
      () {
        if (identical(_loadMoreFuture, request)) {
          _loadMoreFuture = null;
        }
      },
    );
    _loadMoreFuture = request;
    return request;
  }

  Future<CommentSubmitOutcome> submitComment({
    required String content,
    int parentId = 0,
    bool isSpoiler = false,
  }) async {
    if (_disposed) {
      return const CommentSubmitOutcome(CommentSubmitStatus.failed);
    }
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      const message = 'اكتب تعليقًا أولًا.';
      _publishSubmitFailure(message);
      return const CommentSubmitOutcome(
        CommentSubmitStatus.failed,
        errorMessage: message,
      );
    }
    if (parentId < 0) {
      const message = 'تعذر تحديد التعليق الذي تريد الرد عليه.';
      _publishSubmitFailure(message);
      return const CommentSubmitOutcome(
        CommentSubmitStatus.failed,
        errorMessage: message,
      );
    }
    if (_value.isSubmitting) {
      return const CommentSubmitOutcome(CommentSubmitStatus.busy);
    }

    final authRepository = _authRepository;
    final userId = _authenticatedUserId;
    if (authRepository != null && userId == null) {
      const message = 'سجل الدخول لكتابة تعليق.';
      _publishSubmitFailure(message);
      return const CommentSubmitOutcome(
        CommentSubmitStatus.signInRequired,
        errorMessage: message,
      );
    }

    _publishSubmitting();

    try {
      final comment = await _repository.submitComment(
        target: _target,
        content: trimmed,
        parentId: parentId,
        isSpoiler: isSpoiler,
      );
      await _awaitActiveInitialLoad();
      if (_disposed) {
        return const CommentSubmitOutcome(CommentSubmitStatus.failed);
      }
      _publishSubmittedComment(comment);
      return const CommentSubmitOutcome(CommentSubmitStatus.saved);
    } on PrivateApiException catch (error) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        await authRepository?.restoreSession();
      }
      final message = commentSubmitMessageFor(error);
      _finishFailedSubmit(message);
      return CommentSubmitOutcome(
        CommentSubmitStatus.failed,
        errorMessage: message,
      );
    } on FormatException {
      const message = 'أرسل الموقع تعليقًا غير صالح. حاول مجددًا.';
      _finishFailedSubmit(message);
      return const CommentSubmitOutcome(
        CommentSubmitStatus.failed,
        errorMessage: message,
      );
    } on ArgumentError {
      const message = 'اكتب تعليقًا أولًا.';
      _finishFailedSubmit(message);
      return const CommentSubmitOutcome(
        CommentSubmitStatus.failed,
        errorMessage: message,
      );
    }
  }

  Future<CommentInteractionOutcome> voteComment({
    required int commentId,
    CommentVote? vote,
  }) async {
    if (_disposed) {
      return const CommentInteractionOutcome(CommentInteractionStatus.failed);
    }
    if (commentId <= 0) {
      const message = 'تعذر تحديد التعليق.';
      _publishInteractionFailure(message);
      return const CommentInteractionOutcome(
        CommentInteractionStatus.failed,
        errorMessage: message,
      );
    }
    if (_value.isInteracting) {
      return const CommentInteractionOutcome(CommentInteractionStatus.busy);
    }
    final authRepository = _authRepository;
    if (authRepository != null && _authenticatedUserId == null) {
      const message = 'سجل الدخول للتفاعل.';
      _publishInteractionFailure(message);
      return const CommentInteractionOutcome(
        CommentInteractionStatus.signInRequired,
        errorMessage: message,
      );
    }

    _publishInteracting();

    try {
      final result = await _repository.voteComment(
        commentId: commentId,
        vote: vote,
      );
      await _awaitActiveInitialLoad();
      if (_disposed) {
        return const CommentInteractionOutcome(CommentInteractionStatus.failed);
      }
      _publishVotedComment(result);
      return const CommentInteractionOutcome(CommentInteractionStatus.saved);
    } on PrivateApiException catch (error) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        await authRepository?.restoreSession();
      }
      final message = commentInteractionMessageFor(error);
      _finishFailedInteraction(message);
      return CommentInteractionOutcome(
        CommentInteractionStatus.failed,
        errorMessage: message,
      );
    } on FormatException {
      const message = 'أرسل الموقع بيانات تفاعل غير صالحة.';
      _finishFailedInteraction(message);
      return const CommentInteractionOutcome(
        CommentInteractionStatus.failed,
        errorMessage: message,
      );
    } on RangeError {
      const message = 'تعذر تحديد التعليق.';
      _finishFailedInteraction(message);
      return const CommentInteractionOutcome(
        CommentInteractionStatus.failed,
        errorMessage: message,
      );
    } on ArgumentError {
      const message = 'تعذر تنفيذ التفاعل الآن.';
      _finishFailedInteraction(message);
      return const CommentInteractionOutcome(
        CommentInteractionStatus.failed,
        errorMessage: message,
      );
    }
  }

  Future<CommentInteractionOutcome> reactToTarget(
    CommentReaction? reaction,
  ) async {
    if (_disposed) {
      return const CommentInteractionOutcome(CommentInteractionStatus.failed);
    }
    if (_value.isInteracting) {
      return const CommentInteractionOutcome(CommentInteractionStatus.busy);
    }
    final authRepository = _authRepository;
    if (authRepository != null && _authenticatedUserId == null) {
      const message = 'سجل الدخول للتفاعل.';
      _publishInteractionFailure(message);
      return const CommentInteractionOutcome(
        CommentInteractionStatus.signInRequired,
        errorMessage: message,
      );
    }

    _publishInteracting();

    try {
      final result = await _repository.reactToTarget(
        target: _target,
        reaction: reaction,
      );
      await _awaitActiveInitialLoad();
      if (_disposed) {
        return const CommentInteractionOutcome(CommentInteractionStatus.failed);
      }
      _publishReactedTarget(result);
      return const CommentInteractionOutcome(CommentInteractionStatus.saved);
    } on PrivateApiException catch (error) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        await authRepository?.restoreSession();
      }
      final message = commentInteractionMessageFor(error);
      _finishFailedInteraction(message);
      return CommentInteractionOutcome(
        CommentInteractionStatus.failed,
        errorMessage: message,
      );
    } on FormatException {
      const message = 'أرسل الموقع بيانات تفاعل غير صالحة.';
      _finishFailedInteraction(message);
      return const CommentInteractionOutcome(
        CommentInteractionStatus.failed,
        errorMessage: message,
      );
    } on ArgumentError {
      const message = 'تعذر تنفيذ التفاعل الآن.';
      _finishFailedInteraction(message);
      return const CommentInteractionOutcome(
        CommentInteractionStatus.failed,
        errorMessage: message,
      );
    }
  }

  Future<void> _performLoadMore(
    CommentsSort sort,
    int nextPage,
    int generation,
  ) async {
    try {
      final page = await _repository.loadPage(
        target: _target,
        sort: sort,
        page: nextPage,
      );
      if (!_isCurrentLoad(sort, generation)) {
        return;
      }

      _publish(
        CommentsState(
          target: _target,
          sort: sort,
          status: CommentsStatus.ready,
          comments: _mergeComments(_value.comments, page.comments),
          page: page.page,
          totalPages: page.totalPages,
          totalComments: page.totalComments,
          reactions: _reactionCountsFromPage(page.reactions),
          myReaction: _value.myReaction,
          isSubmitting: _value.isSubmitting,
          isInteracting: _value.isInteracting,
        ),
      );
    } on Exception catch (error) {
      if (!_isCurrentLoad(sort, generation)) {
        return;
      }
      final current = _value;
      _publish(
        CommentsState(
          target: current.target,
          sort: current.sort,
          status: CommentsStatus.ready,
          comments: current.comments,
          page: current.page,
          totalPages: current.totalPages,
          totalComments: current.totalComments,
          reactions: current.reactions,
          myReaction: current.myReaction,
          isSubmitting: current.isSubmitting,
          isInteracting: current.isInteracting,
          loadMoreErrorMessage: commentsMessageFor(error),
        ),
      );
    }
  }

  List<PublicComment> _mergeComments(
    List<PublicComment> currentComments,
    List<PublicComment> nextComments,
  ) {
    final commentsById = <int, PublicComment>{};
    for (final comment in currentComments) {
      commentsById.putIfAbsent(comment.id, () => comment);
    }
    for (final comment in nextComments) {
      commentsById.putIfAbsent(comment.id, () => comment);
    }
    return commentsById.values.toList(growable: false);
  }

  List<PublicComment> _insertSubmittedComment(
    List<PublicComment> currentComments,
    PublicComment submitted,
  ) {
    if (submitted.parentId <= 0) {
      return [
        submitted,
        for (final comment in currentComments)
          if (comment.id != submitted.id) comment,
      ];
    }

    final rootId = submitted.rootId > 0 ? submitted.rootId : submitted.parentId;
    return [
      for (final comment in currentComments)
        if (comment.id == rootId) _appendReply(comment, submitted) else comment,
    ];
  }

  PublicComment _appendReply(PublicComment root, PublicComment reply) {
    final replies = [
      for (final current in root.replies)
        if (current.id != reply.id) current,
      reply,
    ];
    final count = root.repliesCount >= replies.length
        ? root.repliesCount + 1
        : replies.length;
    return root.copyWith(replies: replies, repliesCount: count);
  }

  List<PublicComment> _applyVoteResult(
    List<PublicComment> currentComments,
    CommentVoteResult result,
  ) {
    return [
      for (final comment in currentComments)
        _updateCommentVote(comment, result),
    ];
  }

  PublicComment _updateCommentVote(
    PublicComment comment,
    CommentVoteResult result,
  ) {
    if (comment.id == result.commentId) {
      return comment.copyWith(
        likeCount: result.likeCount,
        dislikeCount: result.dislikeCount,
        score: result.score,
        myVote: result.vote,
        clearMyVote: result.vote == null,
      );
    }
    if (comment.replies.isEmpty) {
      return comment;
    }
    return comment.copyWith(
      replies: [
        for (final reply in comment.replies) _updateCommentVote(reply, result),
      ],
    );
  }

  Map<CommentReaction, int> _reactionCountsFromPage(
    Map<String, int> rawCounts,
  ) {
    return {
      for (final reaction in CommentReaction.values)
        reaction: rawCounts[reaction.apiValue] ?? 0,
    };
  }

  void _publishSubmitting() {
    final current = _value;
    _publish(
      CommentsState(
        target: current.target,
        sort: current.sort,
        status: current.status,
        comments: current.comments,
        page: current.page,
        totalPages: current.totalPages,
        totalComments: current.totalComments,
        reactions: current.reactions,
        myReaction: current.myReaction,
        isLoadingMore: current.isLoadingMore,
        isInteracting: current.isInteracting,
        isSubmitting: true,
      ),
    );
  }

  void _publishSubmittedComment(PublicComment comment) {
    final current = _value;
    _publish(
      CommentsState(
        target: current.target,
        sort: current.sort,
        status: CommentsStatus.ready,
        comments: _insertSubmittedComment(current.comments, comment),
        page: current.page <= 0 ? 1 : current.page,
        totalPages: current.totalPages,
        totalComments: current.totalComments + 1,
        reactions: current.reactions,
        myReaction: current.myReaction,
        isLoadingMore: current.isLoadingMore,
        isInteracting: current.isInteracting,
      ),
    );
  }

  void _publishSubmitFailure(String message) {
    final current = _value;
    _publish(
      CommentsState(
        target: current.target,
        sort: current.sort,
        status: current.status,
        comments: current.comments,
        page: current.page,
        totalPages: current.totalPages,
        totalComments: current.totalComments,
        reactions: current.reactions,
        myReaction: current.myReaction,
        isLoadingMore: current.isLoadingMore,
        isInteracting: current.isInteracting,
        submitErrorMessage: message,
      ),
    );
  }

  void _finishFailedSubmit(String message) {
    if (_disposed) {
      return;
    }
    _publishSubmitFailure(message);
  }

  void _publishInteracting() {
    final current = _value;
    _publish(
      CommentsState(
        target: current.target,
        sort: current.sort,
        status: current.status,
        comments: current.comments,
        page: current.page,
        totalPages: current.totalPages,
        totalComments: current.totalComments,
        reactions: current.reactions,
        myReaction: current.myReaction,
        isLoadingMore: current.isLoadingMore,
        isSubmitting: current.isSubmitting,
        isInteracting: true,
      ),
    );
  }

  void _publishVotedComment(CommentVoteResult result) {
    final current = _value;
    _publish(
      CommentsState(
        target: current.target,
        sort: current.sort,
        status: current.status,
        comments: _applyVoteResult(current.comments, result),
        page: current.page,
        totalPages: current.totalPages,
        totalComments: current.totalComments,
        reactions: current.reactions,
        myReaction: current.myReaction,
        isLoadingMore: current.isLoadingMore,
        isSubmitting: current.isSubmitting,
      ),
    );
  }

  void _publishReactedTarget(CommentReactionResult result) {
    final current = _value;
    _publish(
      CommentsState(
        target: current.target,
        sort: current.sort,
        status: current.status,
        comments: current.comments,
        page: current.page,
        totalPages: current.totalPages,
        totalComments: current.totalComments,
        reactions: result.counts,
        myReaction: result.reaction,
        isLoadingMore: current.isLoadingMore,
        isSubmitting: current.isSubmitting,
      ),
    );
  }

  void _publishInteractionFailure(String message) {
    final current = _value;
    _publish(
      CommentsState(
        target: current.target,
        sort: current.sort,
        status: current.status,
        comments: current.comments,
        page: current.page,
        totalPages: current.totalPages,
        totalComments: current.totalComments,
        reactions: current.reactions,
        myReaction: current.myReaction,
        isLoadingMore: current.isLoadingMore,
        isSubmitting: current.isSubmitting,
        interactionErrorMessage: message,
      ),
    );
  }

  void _finishFailedInteraction(String message) {
    if (_disposed) {
      return;
    }
    _publishInteractionFailure(message);
  }

  Future<void> _awaitActiveInitialLoad() async {
    final active = _initialFuture;
    if (active == null) {
      return;
    }
    try {
      await active;
    } on Object {
      // A list failure must not turn a successful mutation into a failure.
    }
  }

  bool _isCurrentLoad(CommentsSort sort, int generation) {
    return !_disposed &&
        generation == _loadGeneration &&
        _value.target == _target &&
        _value.sort == sort;
  }

  int? get _authenticatedUserId {
    final session = _authRepository?.value;
    return session?.status == AuthSessionStatus.authenticated
        ? session?.user?.id
        : null;
  }

  void _publish(CommentsState state) {
    if (_disposed) {
      return;
    }
    _value = state;
    notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _loadGeneration++;
    super.dispose();
  }
}
