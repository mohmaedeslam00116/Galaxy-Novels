import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/data/models/reading_progress.dart';
import 'package:galaxy_novels_app/data/repositories/stored_reading_history_repository.dart';

void main() {
  test('records latest reading progress and persists it as json', () async {
    final store = _FakeReadingHistoryStore();
    final repository = StoredReadingHistoryRepository(store: store);

    final progress = ReadingProgress(
      novelId: 99,
      novelTitle: 'تفاصيل الاختبار',
      chapterId: 10,
      chapterTitle: 'الفصل 10',
      contentApi: '/wp-json/wor-reader-app/v1/chapters/10',
      updatedAt: DateTime.utc(2026, 6, 20, 10),
    );

    await repository.record(progress);

    expect(store.value, contains('"novelTitle":"تفاصيل الاختبار"'));
    expect(store.value, contains('"chapterId":10'));

    final loaded = await repository.load();

    expect(loaded, hasLength(1));
    expect(loaded.single.novelTitle, 'تفاصيل الاختبار');
    expect(loaded.single.chapterTitle, 'الفصل 10');
    expect(loaded.single.contentApi, '/wp-json/wor-reader-app/v1/chapters/10');
  });

  test('keeps one latest entry per novel and sorts by recency', () async {
    final repository = StoredReadingHistoryRepository(
      store: _FakeReadingHistoryStore(),
    );

    await repository.record(
      ReadingProgress(
        novelId: 1,
        novelTitle: 'الأولى',
        chapterId: 10,
        chapterTitle: 'الفصل 10',
        contentApi: '/chapters/10',
        updatedAt: DateTime.utc(2026, 6, 20, 10),
      ),
    );
    await repository.record(
      ReadingProgress(
        novelId: 2,
        novelTitle: 'الثانية',
        chapterId: 20,
        chapterTitle: 'الفصل 20',
        contentApi: '/chapters/20',
        updatedAt: DateTime.utc(2026, 6, 20, 11),
      ),
    );
    await repository.record(
      ReadingProgress(
        novelId: 1,
        novelTitle: 'الأولى',
        chapterId: 11,
        chapterTitle: 'الفصل 11',
        contentApi: '/chapters/11',
        updatedAt: DateTime.utc(2026, 6, 20, 12),
      ),
    );

    final loaded = await repository.load();

    expect(loaded.map((item) => item.novelId), [1, 2]);
    expect(loaded.first.chapterTitle, 'الفصل 11');
  });
}

class _FakeReadingHistoryStore implements ReadingHistoryStore {
  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String value) async {
    this.value = value;
  }
}
