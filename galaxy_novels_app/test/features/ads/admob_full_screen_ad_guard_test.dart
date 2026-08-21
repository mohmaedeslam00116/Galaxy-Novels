import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/features/ads/data/admob_full_screen_ad_guard.dart';

void main() {
  test('full-screen guard enforces shared spacing after any shown ad', () {
    var now = DateTime.utc(2026, 8, 10, 12);
    final guard = AdMobFullScreenAdGuard(now: () => now);

    expect(guard.hasElapsed(const Duration(minutes: 5)), isTrue);
    guard.markShown();
    expect(guard.hasElapsed(const Duration(minutes: 5)), isFalse);

    now = now.add(const Duration(minutes: 5));
    expect(guard.hasElapsed(const Duration(minutes: 5)), isTrue);
  });
}
