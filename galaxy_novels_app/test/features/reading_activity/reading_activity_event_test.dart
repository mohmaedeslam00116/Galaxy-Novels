import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/features/reading_activity/domain/reading_activity_event.dart';

void main() {
  test('keeps owner metadata locally and omits it from server requests', () {
    final event = ReadingActivityEvent(
      ownerUserId: 7,
      eventId: 'app:7:501:1:a1b2c3d4',
      novelId: 42,
      chapterId: 501,
      activeSeconds: 48,
      openSeconds: 60,
      progress: 37,
      completed: false,
      views: 1,
      readAt: DateTime.utc(2026, 6, 23, 12, 30),
    );

    final restored = ReadingActivityEvent.fromStorageJson(
      event.toStorageJson(),
    );

    expect(restored.ownerUserId, 7);
    expect(restored.eventId, event.eventId);
    expect(restored.toRequestJson(), {
      'event_id': event.eventId,
      'object_type': 'chapter',
      'object_id': 501,
      'parent_id': 42,
      'reading_seconds': 48,
      'open_seconds': 60,
      'progress': 37,
      'completed': false,
      'views': 1,
      'read_at': '2026-06-23T12:30:00.000Z',
    });
  });

  test('clamps request counters to the server limits', () {
    final event = ReadingActivityEvent(
      ownerUserId: 7,
      eventId: 'event-limits',
      novelId: 42,
      chapterId: 501,
      activeSeconds: 900,
      openSeconds: 1200,
      progress: 130,
      completed: true,
      views: 4,
      readAt: DateTime.utc(2026, 6, 23),
    );

    final request = event.toRequestJson();

    expect(request['reading_seconds'], 300);
    expect(request['open_seconds'], 900);
    expect(request['progress'], 100);
    expect(request['views'], 1);
  });

  test('rejects invalid persisted event identity', () {
    expect(
      () => ReadingActivityEvent.fromStorageJson({
        'ownerUserId': 0,
        'eventId': '',
        'novelId': 42,
        'chapterId': 501,
        'activeSeconds': 10,
        'openSeconds': 12,
        'progress': 20,
        'completed': false,
        'views': 0,
        'readAt': '2026-06-23T00:00:00.000Z',
      }),
      throwsFormatException,
    );
  });
}
