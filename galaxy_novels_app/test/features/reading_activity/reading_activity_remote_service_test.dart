import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/core/config/app_config.dart';
import 'package:galaxy_novels_app/core/network/private_api_client.dart';
import 'package:galaxy_novels_app/features/reading_activity/data/reading_activity_remote_service.dart';
import 'package:galaxy_novels_app/features/reading_activity/domain/reading_activity_event.dart';

void main() {
  test('posts at most fifty immutable events to reading sync', () async {
    late PrivateRawRequest captured;
    final client = PrivateApiClient(
      config: const AppConfig(siteBaseUrl: 'https://example.com/'),
      requestSender: (request) async {
        captured = request;
        return const PrivateRawResponse(
          statusCode: 200,
          body: '{"success":true,"accepted":49,"duplicates":1}',
        );
      },
    )..updateNonce('test-nonce');
    final service = ReadingActivityRemoteService(client: client);

    final response = await service.sync(List.generate(55, _eventAt));
    final body = jsonDecode(captured.body!) as Map<String, dynamic>;

    expect(captured.uri.path, endsWith('/reading/sync'));
    expect(captured.headers['X-WP-Nonce'], 'test-nonce');
    expect(body['items'], hasLength(50));
    expect(body.containsKey('final'), isFalse);
    expect(response.accepted, 49);
    expect(response.duplicates, 1);
  });
}

ReadingActivityEvent _eventAt(int index) {
  return ReadingActivityEvent(
    ownerUserId: 7,
    eventId: 'event-$index',
    novelId: 42,
    chapterId: 500 + index,
    activeSeconds: 10,
    openSeconds: 12,
    progress: 20,
    completed: false,
    views: index == 0 ? 1 : 0,
    readAt: DateTime.utc(2026, 6, 23),
  );
}
