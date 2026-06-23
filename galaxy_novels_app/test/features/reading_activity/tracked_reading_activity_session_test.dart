import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/features/reading_activity/application/tracked_reading_activity_session.dart';
import 'package:galaxy_novels_app/features/reading_activity/domain/reading_activity_event.dart';

void main() {
  test('checkpoint creates one stable event and forwards it once', () async {
    final events = <ReadingActivityEvent>[];
    final start = DateTime.utc(2026, 6, 23, 12);
    var now = start;
    final session = TrackedReadingActivitySession(
      ownerUserId: 7,
      novelId: 42,
      chapterId: 501,
      now: () => now,
      enqueue: (event) async => events.add(event),
    );
    addTearDown(session.finish);
    session.recordInteraction(30);
    now = start.add(const Duration(seconds: 20));

    await session.checkpoint();
    await session.checkpoint();

    expect(events, hasLength(1));
    expect(events.single.ownerUserId, 7);
    expect(events.single.activeSeconds, 20);
    expect(events.single.openSeconds, 20);
    expect(events.single.progress, 30);
    expect(events.single.eventId, isNotEmpty);
  });
}
