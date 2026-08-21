import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/data/models/reader_content_data.dart';
import 'package:galaxy_novels_app/features/reader/application/reader_speech_narration.dart';
import 'package:galaxy_novels_app/features/reader/domain/reader_advanced_terminology.dart';
import 'package:galaxy_novels_app/features/reader/domain/reader_speech_models.dart';
import 'package:galaxy_novels_app/features/reader/domain/reader_term_replacement.dart';

void main() {
  test('narration uses the same replaced and hidden text as the reader', () {
    const content = ReaderChapterContent(
      id: 12,
      novelId: 8,
      label: 'الفصل 12',
      title: 'عنوان داخلي',
      displayTitle: 'اللقاء',
      position: 12,
      total: 40,
      contentHtml: '<h2>مقدمة</h2><p>قال آدم عبارة الحارس ثم رحل.</p>',
      navigation: ReaderChapterNavigation(
        previousApi: '/chapters/11',
        nextApi: '/chapters/13',
        previousId: 11,
        nextId: 13,
      ),
    );
    const advancedState = ReaderAdvancedTerminologyState(
      accessUnlocked: true,
      packEnabled: false,
      pack: null,
      features: ReaderPackFeatureSelection.enabled,
      personalRemovals: [
        ReaderTextRemovalRule(
          source: 'عبارة الحارس',
          scope: ReaderTermScope.currentNovel,
          novelId: 8,
        ),
      ],
      personalExceptions: [],
      disabledReplacementSources: {},
      replacementOverrides: {},
      disabledGuardSentences: {},
      guardOverrides: {},
      disabledExceptions: {},
      exceptionOverrides: {},
    );

    final chapter = buildReaderSpeechChapter(
      ReaderSpeechChapterRequest(
        content: content,
        contentApi: '/chapters/12',
        novelTitle: 'رواية المجرة',
        coverUrl: 'https://example.com/cover.jpg',
        personalReplacements: const [
          ReaderTermReplacement(
            source: 'آدم',
            replacement: 'آدَم',
            scope: ReaderTermScope.currentNovel,
            novelId: 8,
          ),
        ],
        advancedState: advancedState,
      ),
    );

    expect(chapter.blocks.map((block) => block.text), [
      'مقدمة',
      'قال آدَم ثم رحل.',
    ]);
    expect(chapter.blocks.map((block) => block.sourceIndex), [0, 1]);
    expect(chapter.nextContentApi, '/chapters/13');
    expect(chapter.contentFingerprint, isNotEmpty);
  });

  test('speech chunker preserves UTF-16 ranges within the engine limit', () {
    const block = ReaderSpeechBlock(
      sourceIndex: 4,
      kind: ReaderSpeechBlockKind.paragraph,
      text: 'قال الأول جملة طويلة. ثم ظهر 🌌 في السماء بلا توقف',
    );

    final chunks = splitReaderSpeechBlock(block, maxInputLength: 22);

    expect(chunks, isNotEmpty);
    expect(chunks.every((chunk) => chunk.text.length <= 22), isTrue);
    expect(
      chunks.map((chunk) => block.text.substring(chunk.start, chunk.end)),
      chunks.map((chunk) => chunk.text),
    );
    expect(chunks.any((chunk) => chunk.text.contains('🌌')), isTrue);
    expect(
      chunks.any(
        (chunk) =>
            chunk.text.codeUnits.isNotEmpty &&
            chunk.text.codeUnits.last >= 0xD800 &&
            chunk.text.codeUnits.last <= 0xDBFF,
      ),
      isFalse,
    );
  });

  test('speech chunker returns no chunks for whitespace-only text', () {
    const block = ReaderSpeechBlock(
      sourceIndex: 0,
      kind: ReaderSpeechBlockKind.paragraph,
      text: '   ',
    );

    expect(splitReaderSpeechBlock(block, maxInputLength: 20), isEmpty);
  });
}
