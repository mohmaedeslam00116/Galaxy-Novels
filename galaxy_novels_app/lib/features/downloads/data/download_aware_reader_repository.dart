import '../../../data/models/reader_content_data.dart';
import '../../../data/repositories/reader_repository.dart';
import '../application/download_repository.dart';

class DownloadAwareReaderRepository extends ReaderRepository {
  const DownloadAwareReaderRepository({
    required ReaderRepository network,
    required DownloadRepository downloads,
  }) : _network = network,
       _downloads = downloads;

  final ReaderRepository _network;
  final DownloadRepository _downloads;

  @override
  Future<ReaderChapterContent> loadChapter(String contentApi) {
    final uri = Uri.tryParse(contentApi);
    if (uri?.scheme == 'galaxy-download') {
      return _downloads.loadOffline(contentApi);
    }
    return _network.loadChapter(contentApi);
  }
}
