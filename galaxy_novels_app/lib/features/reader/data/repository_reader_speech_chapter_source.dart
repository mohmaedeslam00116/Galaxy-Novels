import '../../../data/repositories/reader_repository.dart';
import '../application/reader_advanced_terminology_repository.dart';
import '../application/reader_speech_controller.dart';
import '../application/reader_speech_narration.dart';
import '../application/reader_term_replacement_repository.dart';
import '../domain/reader_speech_models.dart';

/// Loads speech chapters without depending on an open reader screen.
class RepositoryReaderSpeechChapterSource implements ReaderSpeechChapterSource {
  RepositoryReaderSpeechChapterSource({
    required ReaderRepository readerRepository,
    required ReaderTermReplacementRepository termRepository,
    required ReaderAdvancedTerminologyRepository advancedRepository,
    required ReaderSpeechCheckpoint checkpoint,
  }) : _readerRepository = readerRepository,
       _termRepository = termRepository,
       _advancedRepository = advancedRepository,
       _novelTitle = checkpoint.novelTitle,
       _coverUrl = checkpoint.coverUrl;

  final ReaderRepository _readerRepository;
  final ReaderTermReplacementRepository _termRepository;
  final ReaderAdvancedTerminologyRepository _advancedRepository;
  final String _novelTitle;
  final String _coverUrl;

  @override
  Future<ReaderSpeechChapter> loadChapter(String contentApi) async {
    await Future.wait([_termRepository.load(), _advancedRepository.load()]);
    final content = await _readerRepository.loadChapter(contentApi);
    return buildReaderSpeechChapter(
      ReaderSpeechChapterRequest(
        content: content,
        contentApi: contentApi,
        novelTitle: _novelTitle,
        coverUrl: _coverUrl,
        personalReplacements: _termRepository.value,
        advancedState: _advancedRepository.value,
      ),
    );
  }

  @override
  Future<void> didStartChapter(ReaderSpeechChapter chapter) async {}
}
