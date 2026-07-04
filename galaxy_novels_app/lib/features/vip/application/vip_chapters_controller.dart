import 'package:flutter/foundation.dart';

import '../../../core/session/session_messages.dart';
import '../domain/vip_chapter.dart';
import 'vip_repository.dart';

enum VipChaptersStatus {
  idle,
  loading,
  ready,
  loginRequired,
  subscriptionRequired,
  failure,
}

class VipChaptersState {
  const VipChaptersState({
    required this.status,
    this.chapters = const [],
    this.hasMore = false,
    this.nextCursorOrder = '',
    this.nextCursorId = 0,
    this.totalAvailable = 0,
    this.errorMessage,
    this.isLoadingMore = false,
  });

  const VipChaptersState.idle() : this(status: VipChaptersStatus.idle);

  final VipChaptersStatus status;
  final List<VipChapter> chapters;
  final bool hasMore;
  final String nextCursorOrder;
  final int nextCursorId;
  final int totalAvailable;
  final String? errorMessage;
  final bool isLoadingMore;

  VipChaptersState copyWith({
    VipChaptersStatus? status,
    List<VipChapter>? chapters,
    bool? hasMore,
    String? nextCursorOrder,
    int? nextCursorId,
    int? totalAvailable,
    String? errorMessage,
    bool? isLoadingMore,
  }) {
    return VipChaptersState(
      status: status ?? this.status,
      chapters: chapters ?? this.chapters,
      hasMore: hasMore ?? this.hasMore,
      nextCursorOrder: nextCursorOrder ?? this.nextCursorOrder,
      nextCursorId: nextCursorId ?? this.nextCursorId,
      totalAvailable: totalAvailable ?? this.totalAvailable,
      errorMessage: errorMessage ?? this.errorMessage,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class VipChaptersController extends ValueNotifier<VipChaptersState> {
  VipChaptersController({
    required VipRepository repository,
    required int novelId,
  }) : _repository = repository,
       _novelId = novelId,
       super(const VipChaptersState.idle());

  final VipRepository _repository;
  final int _novelId;

  Future<void> loadInitial() async {
    if (value.status == VipChaptersStatus.loading ||
        value.status == VipChaptersStatus.ready) {
      return;
    }

    value = const VipChaptersState(status: VipChaptersStatus.loading);
    await _load(const _VipLoadCursor.initial(), reset: true);
  }

  Future<void> retry() async {
    value = const VipChaptersState(status: VipChaptersStatus.loading);
    await _load(const _VipLoadCursor.initial(), reset: true);
  }

  Future<void> loadMore() async {
    if (value.isLoadingMore || !value.hasMore) {
      return;
    }

    final previous = value;
    value = previous.copyWith(isLoadingMore: true);
    await _load(
      _VipLoadCursor(
        order: previous.nextCursorOrder,
        id: previous.nextCursorId,
      ),
      reset: false,
    );
  }

  Future<void> _load(_VipLoadCursor cursor, {required bool reset}) async {
    try {
      final page = await _repository.loadChapters(
        VipChapterQuery(
          novelId: _novelId,
          cursorOrder: reset ? '' : cursor.order,
          cursorId: reset ? 0 : cursor.id,
          limit: 50,
        ),
      );
      value = VipChaptersState(
        status: VipChaptersStatus.ready,
        chapters: reset ? page.items : [...value.chapters, ...page.items],
        hasMore: page.hasMore,
        nextCursorOrder: page.nextCursorOrder,
        nextCursorId: page.nextCursorId,
        totalAvailable: page.totalAvailable,
      );
    } on VipAccessException catch (error) {
      value = VipChaptersState(
        status: switch (error.reason) {
          VipAccessReason.loginRequired => VipChaptersStatus.loginRequired,
          VipAccessReason.subscriptionRequired =>
            VipChaptersStatus.subscriptionRequired,
          VipAccessReason.unavailable => VipChaptersStatus.failure,
        },
        errorMessage: error.reason == VipAccessReason.loginRequired
            ? sessionExpiredMessage
            : error.message,
      );
    } catch (_) {
      value = const VipChaptersState(
        status: VipChaptersStatus.failure,
        errorMessage: 'تعذر تحميل فصول VIP الآن.',
      );
    }
  }
}

class _VipLoadCursor {
  const _VipLoadCursor({required this.order, required this.id});

  const _VipLoadCursor.initial() : this(order: '', id: 0);

  final String order;
  final int id;
}
