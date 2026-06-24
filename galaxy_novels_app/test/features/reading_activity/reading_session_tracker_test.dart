import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/features/reading_activity/domain/reading_session_tracker.dart';

void main() {
  test('counts foreground open time and sixty seconds of idle activity', () {
    final start = DateTime.utc(2026, 6, 23, 12);
    final tracker = ReadingSessionTracker(startedAt: start);

    tracker.recordInteraction(start, progress: 10);
    final delta = tracker.checkpoint(start.add(const Duration(seconds: 90)));

    expect(delta, isNotNull);
    expect(delta!.openSeconds, 90);
    expect(delta.activeSeconds, 60);
    expect(delta.progress, 10);
    expect(delta.views, 1);
  });

  test('does not count background time and waits after resume', () {
    final start = DateTime.utc(2026, 6, 23, 12);
    final tracker = ReadingSessionTracker(startedAt: start)
      ..recordInteraction(start, progress: 20)
      ..pause(start.add(const Duration(seconds: 20)))
      ..resume(start.add(const Duration(minutes: 2)));

    final delta = tracker.checkpoint(
      start.add(const Duration(minutes: 2, seconds: 30)),
    );

    expect(delta, isNotNull);
    expect(delta!.openSeconds, 50);
    expect(delta.activeSeconds, 20);
  });

  test('marks the chapter complete at ninety two percent', () {
    final start = DateTime.utc(2026, 6, 23, 12);
    final tracker = ReadingSessionTracker(startedAt: start)
      ..recordInteraction(start, progress: 92);

    final delta = tracker.checkpoint(start.add(const Duration(seconds: 1)));

    expect(delta, isNotNull);
    expect(delta!.progress, 92);
    expect(delta.completed, isTrue);
  });
}
