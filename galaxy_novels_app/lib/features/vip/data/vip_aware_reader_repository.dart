import '../../../data/models/reader_content_data.dart';
import '../../../data/repositories/reader_repository.dart';
import '../application/vip_repository.dart';
import 'private_vip_repository.dart';
import 'vip_reader_request.dart';

class VipAwareReaderRepository implements ReaderRepository {
  const VipAwareReaderRepository({
    required ReaderRepository publicReader,
    required PrivateVipRepository vipRepository,
  }) : _publicReader = publicReader,
       _vipRepository = vipRepository;

  final ReaderRepository _publicReader;
  final PrivateVipRepository _vipRepository;

  @override
  Future<ReaderChapterContent> loadChapter(String contentApi) {
    final vipRequest = VipReaderRequest.tryParse(contentApi);
    if (vipRequest == null) {
      return _loadPublicChapter(contentApi);
    }

    return switch (vipRequest.kind) {
      VipReaderRequestKind.chapter => _vipRepository.loadChapterById(
        vipRequest.chapterId,
      ),
      VipReaderRequestKind.nextAfter => _vipRepository.loadNextAfter(
        vipRequest.chapterId,
      ),
    };
  }

  Future<ReaderChapterContent> _loadPublicChapter(String contentApi) async {
    final content = await _publicReader.loadChapter(contentApi);
    if (!_needsVipContinuation(content)) {
      return content;
    }

    try {
      final page = await _vipRepository.loadChapters(
        VipChapterQuery(novelId: content.novelId, limit: 1),
      );
      if (page.items.isEmpty) {
        return content;
      }
      final nextChapter = page.items.first;
      final nextApi = nextChapter.contentApi.isNotEmpty
          ? nextChapter.contentApi
          : VipReaderRequest.chapter(nextChapter.id);
      if (nextApi.isEmpty) {
        return content;
      }
      return _withNextNavigation(content, nextApi, nextChapter.id);
    } on VipAccessException {
      return content;
    } catch (_) {
      return content;
    }
  }
}

bool _needsVipContinuation(ReaderChapterContent content) {
  return content.navigation.nextApi.isEmpty && content.novelId > 0;
}

ReaderChapterContent _withNextNavigation(
  ReaderChapterContent content,
  String nextApi,
  int nextId,
) {
  return ReaderChapterContent(
    id: content.id,
    novelId: content.novelId,
    label: content.label,
    title: content.title,
    displayTitle: content.displayTitle,
    position: content.position,
    total: content.total,
    contentHtml: content.contentHtml,
    navigation: ReaderChapterNavigation(
      previousApi: content.navigation.previousApi,
      nextApi: nextApi,
      previousId: content.navigation.previousId,
      nextId: nextId,
    ),
  );
}
