import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/features/reader/data/stored_reader_term_replacement_repository.dart';
import 'package:galaxy_novels_app/features/reader/domain/reader_term_replacement.dart';

void main() {
  const globalHero = ReaderTermReplacement(
    source: 'البطل',
    replacement: 'المغامر',
    scope: ReaderTermScope.allNovels,
    novelId: 0,
  );
  const novelHero = ReaderTermReplacement(
    source: 'البطل',
    replacement: 'الفارس',
    scope: ReaderTermScope.currentNovel,
    novelId: 7,
  );

  test('current novel rules override global rules without leaking', () {
    const text = 'عاد البطل، لكن البطلان بقيا في القصر.';

    expect(
      applyReaderTermReplacements(text, [globalHero, novelHero], 7),
      'عاد الفارس، لكن البطلان بقيا في القصر.',
    );
    expect(
      applyReaderTermReplacements(text, [globalHero, novelHero], 9),
      'عاد المغامر، لكن البطلان بقيا في القصر.',
    );
  });

  test('longer terms win and replacements do not cascade', () {
    const rules = [
      ReaderTermReplacement(
        source: 'سيد السيف',
        replacement: 'حارس النصل',
        scope: ReaderTermScope.allNovels,
        novelId: 0,
      ),
      ReaderTermReplacement(
        source: 'السيف',
        replacement: 'النصل',
        scope: ReaderTermScope.allNovels,
        novelId: 0,
      ),
      ReaderTermReplacement(
        source: 'حارس',
        replacement: 'قائد',
        scope: ReaderTermScope.allNovels,
        novelId: 0,
      ),
    ];

    expect(
      applyReaderTermReplacements('وصل سيد السيف ومعه السيف.', rules, 1),
      'وصل حارس النصل ومعه النصل.',
    );
  });

  test('replacement segments identify only the changed text', () {
    final segments = segmentReaderTermReplacements(
      'عاد البطل إلى القصر.',
      const [globalHero],
      9,
    );

    expect(segments.map((segment) => segment.text), [
      'عاد ',
      'المغامر',
      ' إلى القصر.',
    ]);
    expect(segments.map((segment) => segment.isReplacement), [
      false,
      true,
      false,
    ]);
  });

  test('stored repository saves, edits, deletes, and restores rules', () async {
    final store = _MemoryTermStore();
    final repository = StoredReaderTermReplacementRepository(store: store);

    await repository.save(globalHero);
    await repository.save(novelHero);
    await repository.save(
      const ReaderTermReplacement(
        source: 'البطل',
        replacement: 'الرحالة',
        scope: ReaderTermScope.allNovels,
        novelId: 0,
      ),
      replacing: globalHero,
    );

    expect(repository.value, hasLength(2));
    expect(repository.value, isNot(contains(globalHero)));

    final restored = StoredReaderTermReplacementRepository(store: store);
    await restored.load();
    expect(restored.value, repository.value);

    await restored.remove(novelHero);
    expect(restored.value, hasLength(1));
  });
}

class _MemoryTermStore implements ReaderTermReplacementStore {
  String? raw;

  @override
  Future<String?> read() async => raw;

  @override
  Future<void> write(String value) async => raw = value;
}
