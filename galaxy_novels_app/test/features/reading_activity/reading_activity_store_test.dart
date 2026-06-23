import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/features/reading_activity/data/shared_preferences_reading_activity_store.dart';
import 'package:galaxy_novels_app/features/reading_activity/domain/reading_activity_event.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('stores queues independently by account', () async {
    final store = SharedPreferencesReadingActivityStore();
    await store.write(7, [_event(ownerUserId: 7, eventId: 'event-7')]);
    await store.write(8, [_event(ownerUserId: 8, eventId: 'event-8')]);

    expect((await store.read(7)).single.eventId, 'event-7');
    expect((await store.read(8)).single.eventId, 'event-8');
  });

  test('keeps the newest five hundred events', () async {
    final store = SharedPreferencesReadingActivityStore();
    final events = List.generate(
      501,
      (index) => _event(eventId: 'event-$index'),
    );

    await store.write(7, events);
    final restored = await store.read(7);

    expect(restored, hasLength(500));
    expect(restored.first.eventId, 'event-1');
    expect(restored.last.eventId, 'event-500');
  });

  test('malformed persisted queue is cleared safely', () async {
    SharedPreferences.setMockInitialValues({
      'reading_activity_queue.v1.7': '{broken-json',
    });
    final store = SharedPreferencesReadingActivityStore();

    expect(await store.read(7), isEmpty);
    expect(await store.read(7), isEmpty);
  });
}

ReadingActivityEvent _event({int ownerUserId = 7, String eventId = 'event'}) {
  return ReadingActivityEvent(
    ownerUserId: ownerUserId,
    eventId: eventId,
    novelId: 42,
    chapterId: 501,
    activeSeconds: 10,
    openSeconds: 12,
    progress: 20,
    completed: false,
    views: 0,
    readAt: DateTime.utc(2026, 6, 23),
  );
}
