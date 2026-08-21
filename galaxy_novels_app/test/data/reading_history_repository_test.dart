import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/data/models/reading_progress.dart';
import 'package:galaxy_novels_app/data/repositories/reading_history_repository.dart';
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
      chapterPosition: 10,
      chaptersTotal: 120,
      updatedAt: DateTime.utc(2026, 6, 20, 10),
    );

    await repository.record(progress);

    expect(store.value, contains('"novelTitle":"تفاصيل الاختبار"'));
    expect(store.value, contains('"chapterId":10'));
    expect(store.value, contains('"chapterPosition":10'));
    expect(store.value, contains('"chaptersTotal":120'));

    final loaded = await repository.load();

    expect(loaded, hasLength(1));
    expect(loaded.single.novelTitle, 'تفاصيل الاختبار');
    expect(loaded.single.chapterTitle, 'الفصل 10');
    expect(loaded.single.contentApi, '/wp-json/wor-reader-app/v1/chapters/10');
    expect(loaded.single.chapterPosition, 10);
    expect(loaded.single.chaptersTotal, 120);
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

  test(
    'serializes concurrent records in the same scope without losing entries',
    () async {
      final store = _BlockingReadingHistoryStore(
        blockedScope: ReadingHistoryScope.user(7),
      );
      final repository = StoredReadingHistoryRepository(store: store);
      final scope = ReadingHistoryScope.user(7);
      final first = repository.recordForScope(
        scope,
        _progress(1, DateTime.utc(2026, 6, 20, 10)),
      );
      await store.blockedWriteStarted.future;

      final second = repository.recordForScope(
        scope,
        _progress(2, DateTime.utc(2026, 6, 20, 11)),
      );
      store.releaseBlockedWrite.complete();
      await Future.wait([first, second]);

      final loaded = await repository.loadForScope(scope);
      expect(loaded.map((item) => item.novelId), [2, 1]);
    },
  );

  test('a failed scoped write does not block the next record', () async {
    final store = _FakeReadingHistoryStore()..remainingWriteFailures = 1;
    final repository = StoredReadingHistoryRepository(store: store);
    final scope = ReadingHistoryScope.user(7);

    await expectLater(
      repository.recordForScope(
        scope,
        _progress(1, DateTime.utc(2026, 6, 20, 10)),
      ),
      throwsA(isA<StateError>()),
    );
    await repository.recordForScope(
      scope,
      _progress(2, DateTime.utc(2026, 6, 20, 11)),
    );

    final loaded = await repository.loadForScope(scope);
    expect(loaded.map((item) => item.novelId), [2]);
  });

  test('mutations in different scopes do not block each other', () async {
    final store = _BlockingReadingHistoryStore(
      blockedScope: ReadingHistoryScope.guest,
    );
    final repository = StoredReadingHistoryRepository(store: store);
    final accountScope = ReadingHistoryScope.user(7);
    final guestRecord = repository.recordForScope(
      ReadingHistoryScope.guest,
      _progress(1, DateTime.utc(2026, 6, 20, 10)),
    );
    await store.blockedWriteStarted.future;
    var accountCompleted = false;
    final accountRecord = repository
        .recordForScope(
          accountScope,
          _progress(2, DateTime.utc(2026, 6, 20, 11)),
        )
        .then((_) => accountCompleted = true);

    try {
      await Future<void>.delayed(Duration.zero);
      expect(accountCompleted, isTrue);
    } finally {
      if (!store.releaseBlockedWrite.isCompleted) {
        store.releaseBlockedWrite.complete();
      }
      await Future.wait([guestRecord, accountRecord]);
    }

    expect((await repository.loadForScope(accountScope)).single.novelId, 2);
  });
}

class _FakeReadingHistoryStore implements ReadingHistoryStore {
  final Map<ReadingHistoryScope, String> values = {};
  int remainingWriteFailures = 0;

  String? get value => values[ReadingHistoryScope.guest];

  @override
  Future<String?> read(ReadingHistoryScope scope) async => values[scope];

  @override
  Future<void> write(ReadingHistoryScope scope, String value) async {
    if (remainingWriteFailures > 0) {
      remainingWriteFailures -= 1;
      throw StateError('write failed');
    }
    values[scope] = value;
  }
}

class _BlockingReadingHistoryStore extends _FakeReadingHistoryStore {
  _BlockingReadingHistoryStore({required this.blockedScope});

  final ReadingHistoryScope blockedScope;
  final Completer<void> blockedWriteStarted = Completer<void>();
  final Completer<void> releaseBlockedWrite = Completer<void>();
  bool _hasBlocked = false;

  @override
  Future<void> write(ReadingHistoryScope scope, String value) async {
    if (scope == blockedScope && !_hasBlocked) {
      _hasBlocked = true;
      blockedWriteStarted.complete();
      await releaseBlockedWrite.future;
    }
    await super.write(scope, value);
  }
}

ReadingProgress _progress(int novelId, DateTime updatedAt) {
  return ReadingProgress(
    novelId: novelId,
    novelTitle: 'رواية $novelId',
    chapterId: novelId * 10,
    chapterTitle: 'الفصل ${novelId * 10}',
    contentApi: '/chapters/${novelId * 10}',
    updatedAt: updatedAt,
  );
}
