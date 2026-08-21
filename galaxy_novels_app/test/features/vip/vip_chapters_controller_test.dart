import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/features/vip/application/vip_chapters_controller.dart';
import 'package:galaxy_novels_app/features/vip/application/vip_repository.dart';
import 'package:galaxy_novels_app/features/vip/domain/vip_chapter.dart';

void main() {
  test('loads initial VIP chapters once', () async {
    final repository = _FakeVipRepository([
      const VipChapterPage(
        items: [
          VipChapter(
            id: 1,
            number: '1',
            position: 1,
            order: '1.000000',
            title: 'فصل خاص',
            url: '',
            publicAt: '',
            views: 0,
            comments: 0,
          ),
        ],
        hasMore: false,
        nextCursorOrder: '',
        nextCursorId: 0,
        totalAvailable: 1,
      ),
    ]);
    final controller = VipChaptersController(
      repository: repository,
      novelId: 9,
    );

    await controller.loadInitial();
    await controller.loadInitial();

    expect(controller.value.status, VipChaptersStatus.ready);
    expect(controller.value.chapters.single.id, 1);
    expect(repository.queries, hasLength(1));
    expect(repository.queries.single.novelId, 9);
  });

  test('loads additional pages from the saved cursor', () async {
    final repository = _FakeVipRepository([
      const VipChapterPage(
        items: [
          VipChapter(
            id: 1,
            number: '1',
            position: 1,
            order: '1.000000',
            title: '',
            url: '',
            publicAt: '',
            views: 0,
            comments: 0,
          ),
        ],
        hasMore: true,
        nextCursorOrder: '1.000000',
        nextCursorId: 1,
        totalAvailable: 2,
      ),
      const VipChapterPage(
        items: [
          VipChapter(
            id: 2,
            number: '2',
            position: 2,
            order: '2.000000',
            title: '',
            url: '',
            publicAt: '',
            views: 0,
            comments: 0,
          ),
        ],
        hasMore: false,
        nextCursorOrder: '',
        nextCursorId: 0,
        totalAvailable: 2,
      ),
    ]);
    final controller = VipChaptersController(
      repository: repository,
      novelId: 9,
    );

    await controller.loadInitial();
    await controller.loadMore();

    expect(controller.value.chapters.map((chapter) => chapter.id), [1, 2]);
    expect(repository.queries.last.cursorOrder, '1.000000');
    expect(repository.queries.last.cursorId, 1);
  });

  test('loads every VIP page for an all-chapters request', () async {
    final repository = _FakeVipRepository([
      _vipPage(id: 1, hasMore: true, nextId: 1, total: 3),
      _vipPage(id: 2, hasMore: true, nextId: 2, total: 3),
      _vipPage(id: 3, hasMore: false, nextId: 0, total: 3),
    ]);
    final controller = VipChaptersController(
      repository: repository,
      novelId: 9,
    );

    final loadedAll = await controller.loadAll();

    expect(loadedAll, isTrue);
    expect(controller.value.chapters.map((chapter) => chapter.id), [1, 2, 3]);
    expect(repository.queries, hasLength(3));
  });

  test('all-chapters failure preserves confirmed VIP pages', () async {
    final repository = _SequenceVipRepository([
      _vipPage(id: 1, hasMore: true, nextId: 1, total: 2),
      const VipAccessException(
        VipAccessReason.unavailable,
        'تعذر تحميل البقية',
      ),
    ]);
    final controller = VipChaptersController(
      repository: repository,
      novelId: 9,
    );

    final loadedAll = await controller.loadAll();

    expect(loadedAll, isFalse);
    expect(controller.value.status, VipChaptersStatus.ready);
    expect(controller.value.chapters.single.id, 1);
    expect(controller.value.hasMore, isTrue);
    expect(controller.value.errorMessage, 'تعذر تحميل البقية');
  });

  test('maps subscription errors into blocked state', () async {
    final controller = VipChaptersController(
      repository: const _FailingVipRepository(
        VipAccessException(
          VipAccessReason.subscriptionRequired,
          'اشتراك VIP مطلوب',
        ),
      ),
      novelId: 9,
    );

    await controller.loadInitial();

    expect(controller.value.status, VipChaptersStatus.subscriptionRequired);
    expect(controller.value.errorMessage, 'اشتراك VIP مطلوب');
  });

  test('maps login errors into the shared expired-session message', () async {
    final controller = VipChaptersController(
      repository: const _FailingVipRepository(
        VipAccessException(VipAccessReason.loginRequired, 'expired'),
      ),
      novelId: 9,
    );

    await controller.loadInitial();

    expect(controller.value.status, VipChaptersStatus.loginRequired);
    expect(
      controller.value.errorMessage,
      'انتهت الجلسة، سجل الدخول مرة أخرى للمتابعة.',
    );
  });

  test('ignores a late VIP response after dispose', () async {
    final response = Completer<VipChapterPage>();
    const emptyPage = VipChapterPage(
      items: [],
      hasMore: false,
      nextCursorOrder: '',
      nextCursorId: 0,
      totalAvailable: 0,
    );
    addTearDown(() {
      if (!response.isCompleted) {
        response.complete(emptyPage);
      }
    });
    final controller = VipChaptersController(
      repository: _PendingVipRepository(response.future),
      novelId: 9,
    );

    final pending = controller.loadInitial();
    controller.dispose();
    response.complete(emptyPage);

    await expectLater(pending, completes);
  });
}

class _FakeVipRepository implements VipRepository {
  _FakeVipRepository(this.pages);

  final List<VipChapterPage> pages;
  final queries = <VipChapterQuery>[];

  @override
  Future<VipChapterPage> loadChapters(VipChapterQuery query) async {
    queries.add(query);
    return pages.removeAt(0);
  }
}

class _FailingVipRepository implements VipRepository {
  const _FailingVipRepository(this.error);

  final Object error;

  @override
  Future<VipChapterPage> loadChapters(VipChapterQuery query) {
    return Future.error(error);
  }
}

class _PendingVipRepository implements VipRepository {
  const _PendingVipRepository(this.response);

  final Future<VipChapterPage> response;

  @override
  Future<VipChapterPage> loadChapters(VipChapterQuery query) => response;
}

VipChapterPage _vipPage({
  required int id,
  required bool hasMore,
  required int nextId,
  required int total,
}) {
  return VipChapterPage(
    items: [
      VipChapter(
        id: id,
        number: '$id',
        position: id,
        order: '$id.000000',
        title: '',
        url: '',
        publicAt: '',
        views: 0,
        comments: 0,
      ),
    ],
    hasMore: hasMore,
    nextCursorOrder: hasMore ? '$nextId.000000' : '',
    nextCursorId: nextId,
    totalAvailable: total,
  );
}

class _SequenceVipRepository implements VipRepository {
  _SequenceVipRepository(this.responses);

  final List<Object> responses;

  @override
  Future<VipChapterPage> loadChapters(VipChapterQuery query) async {
    final response = responses.removeAt(0);
    if (response is VipChapterPage) return response;
    throw response;
  }
}
