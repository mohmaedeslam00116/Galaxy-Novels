import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/data/models/reader_content_data.dart';
import 'package:galaxy_novels_app/data/repositories/reader_repository.dart';
import 'package:galaxy_novels_app/features/downloads/application/download_repository.dart';
import 'package:galaxy_novels_app/features/downloads/data/download_aware_reader_repository.dart';

void main() {
  test(
    'routes local chapter URIs to downloads and remote paths to network',
    () async {
      final network = _ReaderRepository();
      final downloads = _DownloadRepository();
      final repository = DownloadAwareReaderRepository(
        network: network,
        downloads: downloads,
      );

      await repository.loadChapter('galaxy-download://chapter/public%3A71');
      await repository.loadChapter('/chapters/72');

      expect(downloads.loaded, ['galaxy-download://chapter/public%3A71']);
      expect(network.loaded, ['/chapters/72']);
    },
  );
}

class _ReaderRepository extends ReaderRepository {
  final loaded = <String>[];

  @override
  Future<ReaderChapterContent> loadChapter(String contentApi) async {
    loaded.add(contentApi);
    return _content;
  }
}

class _DownloadRepository extends NoopDownloadRepository {
  final loaded = <String>[];

  @override
  Future<ReaderChapterContent> loadOffline(String offlineUri) async {
    loaded.add(offlineUri);
    return _content;
  }
}

const _content = ReaderChapterContent(
  id: 71,
  novelId: 7,
  label: 'الفصل 71',
  title: '',
  displayTitle: 'الفصل 71',
  position: 71,
  total: 100,
  contentHtml: '<p>المحتوى</p>',
  navigation: ReaderChapterNavigation(
    previousApi: '',
    nextApi: '',
    previousId: 0,
    nextId: 0,
  ),
);
