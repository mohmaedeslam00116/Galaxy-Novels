import 'package:galaxy_novels_app/features/vip/application/vip_repository.dart';
import 'package:galaxy_novels_app/features/vip/domain/vip_chapter.dart';

class FakeVipRepository implements VipRepository {
  const FakeVipRepository({
    this.page = const VipChapterPage(
      items: [],
      hasMore: false,
      nextCursorOrder: '',
      nextCursorId: 0,
      totalAvailable: 0,
    ),
  });

  final VipChapterPage page;

  @override
  Future<VipChapterPage> loadChapters(VipChapterQuery query) async => page;
}
