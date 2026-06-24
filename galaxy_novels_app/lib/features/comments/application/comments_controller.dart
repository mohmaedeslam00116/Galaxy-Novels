import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../data/comments_error_messages.dart';
import '../domain/comment_target.dart';
import '../domain/public_comment.dart';
import 'comments_repository.dart';

enum CommentsStatus { idle, loading, ready, failure }

class CommentsState {
  CommentsState({
    required this.target,
    required this.sort,
    required this.status,
    List<PublicComment> comments = const [],
    this.page = 0,
    this.totalPages = 0,
    this.totalComments = 0,
    this.isLoadingMore = false,
    this.errorMessage,
    this.loadMoreErrorMessage,
  }) : comments = List<PublicComment>.unmodifiable(comments);

  final CommentTarget target;
  final CommentsSort sort;
  final CommentsStatus status;
  final List<PublicComment> comments;
  final int page;
  final int totalPages;
  final int totalComments;
  final bool isLoadingMore;
  final String? errorMessage;
  final String? loadMoreErrorMessage;

  bool get hasNextPage => status == CommentsStatus.ready && page < totalPages;
}

class CommentsController extends ChangeNotifier
    implements ValueListenable<CommentsState> {
  CommentsController({
    required CommentsRepository repository,
    required CommentTarget target,
  }) : _repository = repository,
       _target = target,
       _value = CommentsState(
         target: target,
         sort: CommentsSort.newest,
         status: CommentsStatus.idle,
       );

  final CommentsRepository _repository;
  final CommentTarget _target;
  CommentsState _value;
  Future<void>? _initialFuture;
  CommentsSort? _initialSort;
  Future<void>? _loadMoreFuture;
  int _generation = 0;
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

    final generation = ++_generation;
    _loadMoreFuture = null;
    _publish(
      CommentsState(
        target: _target,
        sort: sort,
        status: CommentsStatus.loading,
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
      if (!_isCurrent(sort, generation)) {
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
        ),
      );
    } on Object catch (error) {
      if (!_isCurrent(sort, generation)) {
        return;
      }
      _publish(
        CommentsState(
          target: _target,
          sort: sort,
          status: CommentsStatus.failure,
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

    final generation = _generation;
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
        isLoadingMore: true,
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
      if (!_isCurrent(sort, generation)) {
        return;
      }

      final merged = LinkedHashMap<int, PublicComment>();
      for (final comment in _value.comments) {
        merged.putIfAbsent(comment.id, () => comment);
      }
      for (final comment in page.comments) {
        merged.putIfAbsent(comment.id, () => comment);
      }
      _publish(
        CommentsState(
          target: _target,
          sort: sort,
          status: CommentsStatus.ready,
          comments: merged.values.toList(growable: false),
          page: page.page,
          totalPages: page.totalPages,
          totalComments: page.totalComments,
        ),
      );
    } on Object catch (error) {
      if (!_isCurrent(sort, generation)) {
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
          loadMoreErrorMessage: commentsMessageFor(error),
        ),
      );
    }
  }

  bool _isCurrent(CommentsSort sort, int generation) {
    return !_disposed &&
        generation == _generation &&
        _value.target == _target &&
        _value.sort == sort;
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
    _generation++;
    super.dispose();
  }
}
