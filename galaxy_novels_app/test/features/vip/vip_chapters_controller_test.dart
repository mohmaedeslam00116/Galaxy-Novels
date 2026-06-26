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
