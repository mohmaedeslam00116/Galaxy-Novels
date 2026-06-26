import '../../../data/models/reader_content_data.dart';
import '../../../data/repositories/reader_repository.dart';
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
      return _publicReader.loadChapter(contentApi);
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
}
