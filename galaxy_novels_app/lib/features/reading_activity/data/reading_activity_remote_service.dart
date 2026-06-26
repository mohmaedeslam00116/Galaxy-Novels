import '../../../core/network/private_api_client.dart';
import '../domain/reading_activity_event.dart';

class ReadingActivitySyncResult {
  const ReadingActivitySyncResult({
    required this.accepted,
    required this.duplicates,
  });

  final int accepted;
  final int duplicates;
}

class ReadingActivityRemoteService {
  const ReadingActivityRemoteService({required PrivateApiClient client})
    : _client = client;

  final PrivateApiClient _client;

  Future<ReadingActivitySyncResult> sync(
    List<ReadingActivityEvent> events,
  ) async {
    if (events.isEmpty) {
      return const ReadingActivitySyncResult(accepted: 0, duplicates: 0);
    }
    final response = await _client.postAuthenticated(
      'reading/sync',
      body: {
        'items': events
            .take(50)
            .map((event) => event.toRequestJson())
            .toList(growable: false),
      },
    );
    return ReadingActivitySyncResult(
      accepted: _asInt(response['accepted']),
      duplicates: _asInt(response['duplicates']),
    );
  }
}

int _asInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
