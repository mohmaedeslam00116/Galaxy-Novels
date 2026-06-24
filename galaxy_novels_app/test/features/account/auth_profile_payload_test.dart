import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/features/account/data/auth_profile_payload.dart';

void main() {
  group('AuthProfilePayload.fromResponse', () {
    test('parses the authenticated user profile', () {
      final payload = AuthProfilePayload.fromResponse({
        'user': _userJson(),
      }, expectedUserId: 7);

      expect(payload.user.id, 7);
      expect(payload.user.xp.total, 1840);
      expect(payload.user.xp.today, 35);
      expect(payload.user.xp.rank.display, 'Pathfinder');
    });

    test('rejects a profile for a different user', () {
      expect(
        () => AuthProfilePayload.fromResponse({
          'user': _userJson(),
        }, expectedUserId: 8),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects a response without a user object', () {
      expect(
        () => AuthProfilePayload.fromResponse({}, expectedUserId: 7),
        throwsA(isA<FormatException>()),
      );
    });
  });
}

Map<String, dynamic> _userJson() {
  return {
    'id': 7,
    'display_name': 'Galaxy Reader',
    'avatar': 'https://example.com/avatar.jpg',
    'vip': {
      'active': true,
      'tier': 'gold',
      'label': 'Gold',
      'expires_at': '2026-12-31T23:59:59Z',
    },
    'xp': {
      'total': 1840,
      'today': 35,
      'seconds_total': 7200,
      'chapters_total': 42,
      'rank': {'level': 5, 'display': 'Pathfinder'},
    },
  };
}
