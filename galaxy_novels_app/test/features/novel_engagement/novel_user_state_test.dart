import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/features/novel_engagement/domain/novel_user_state.dart';

void main() {
  test('parses a complete per-novel user state', () {
    final state = NovelUserState.fromResponse({
      'novel_id': 123,
      'favorite': true,
      'my_rating': 4,
      'last_read': {
        'chapter_id': 555,
        'chapter_url': '/chapter-555/',
        'progress': 96,
        'updated_at': '2026-06-18T10:00:00+00:00',
      },
      'vip': {'active': true, 'can_read_private': true},
    }, expectedNovelId: 123);

    expect(state.novelId, 123);
    expect(state.favorite, isTrue);
    expect(state.myRating, 4);
    expect(state.lastRead.chapterId, 555);
    expect(state.lastRead.chapterUrl, '/chapter-555/');
    expect(state.lastRead.progress, 96);
    expect(state.lastRead.updatedAt, DateTime.parse('2026-06-18T10:00:00Z'));
    expect(state.vip.active, isTrue);
    expect(state.vip.canReadPrivate, isTrue);
  });

  test('uses safe optional defaults and clamps progress', () {
    final state = NovelUserState.fromResponse({
      'novel_id': 123,
      'my_rating': 9,
      'last_read': {'chapter_id': -2, 'progress': 140},
    }, expectedNovelId: 123);

    expect(state.favorite, isFalse);
    expect(state.myRating, 0);
    expect(state.lastRead.chapterId, 0);
    expect(state.lastRead.progress, 100);
    expect(state.lastRead.updatedAt, isNull);
    expect(state.vip.active, isFalse);
  });

  test('rejects a response for another novel', () {
    expect(
      () =>
          NovelUserState.fromResponse({'novel_id': 999}, expectedNovelId: 123),
      throwsFormatException,
    );
  });

  test('copyWith changes only the requested personal field', () {
    final state = NovelUserState.fromResponse({
      'novel_id': 123,
      'favorite': true,
      'my_rating': 2,
    }, expectedNovelId: 123);

    final updated = state.copyWith(myRating: 5);

    expect(updated.myRating, 5);
    expect(updated.favorite, isTrue);
    expect(updated.lastRead, same(state.lastRead));
    expect(updated.vip, same(state.vip));
  });
}
