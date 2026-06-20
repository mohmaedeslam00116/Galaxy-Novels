import '../models/reader_content_data.dart';

abstract class ReaderRepository {
  const ReaderRepository();

  Future<ReaderChapterContent> loadChapter(String contentApi);
}
