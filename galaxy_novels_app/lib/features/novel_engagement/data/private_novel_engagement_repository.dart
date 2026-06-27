import '../../../core/network/private_api_client.dart';
import '../application/novel_engagement_repository.dart';
import '../domain/novel_user_state.dart';

class PrivateNovelEngagementRepository implements NovelEngagementRepository {
  const PrivateNovelEngagementRepository({required PrivateApiClient client})
    : _client = client;

  final PrivateApiClient _client;

  @override
  Future<NovelUserState> loadState(int novelId) async {
    if (novelId <= 0) {
      throw RangeError.value(novelId, 'novelId');
    }
    final response = await _client.getAuthenticated('me/novels/$novelId');
    final state = NovelUserState.fromResponse(
      response,
      expectedNovelId: novelId,
    );
    final historyLastRead = await _loadHistoryLastRead(novelId);
    if (historyLastRead == null || historyLastRead.chapterId <= 0) {
      return state;
    }
    return state.copyWith(lastRead: historyLastRead);
  }

  @override
  Future<int> submitRating({required int novelId, required int rating}) async {
    if (novelId <= 0) {
      throw RangeError.value(novelId, 'novelId');
    }
    if (rating < 1 || rating > 5) {
      throw RangeError.range(rating, 1, 5, 'rating');
    }

    final response = await _client.postAuthenticated(
      'ratings/novel/$novelId',
      body: {'rating': rating},
    );
    final savedRating = int.tryParse(response['rating']?.toString() ?? '') ?? 0;
    if (savedRating < 1 || savedRating > 5) {
      throw const FormatException('Invalid saved rating payload.');
    }
    return savedRating;
  }

  Future<NovelLastRead?> _loadHistoryLastRead(int novelId) async {
    try {
      final response = await _client.getAuthenticated(
        'me/history/novel/$novelId',
      );
      return _historyLastReadFromResponse(response, expectedNovelId: novelId);
    } on PrivateApiException {
      return null;
    } on FormatException {
      return null;
    }
  }
}

NovelLastRead? _historyLastReadFromResponse(
  Map<String, dynamic> response, {
  required int expectedNovelId,
}) {
  final payload = _historyPayload(response);
  final novelId = _asInt(
    payload['novel_id'] ?? payload['novelId'] ?? payload['id'],
  );
  if (novelId > 0 && novelId != expectedNovelId) {
    throw const FormatException('Unexpected novel history payload.');
  }

  final directLastRead = _asMap(payload['last_read'] ?? payload['lastRead']);
  if (directLastRead.isNotEmpty) {
    final lastRead = NovelLastRead.fromJson(directLastRead);
    return lastRead.chapterId > 0 ? lastRead : null;
  }

  final chapter = _asMap(
    payload['lastChapter'] ?? payload['last_chapter'] ?? payload['chapter'],
  );
  final chapterId = _asInt(
    chapter['chapterId'] ??
        chapter['chapter_id'] ??
        payload['chapterId'] ??
        payload['chapter_id'],
  );
  if (chapterId <= 0) {
    return null;
  }

  return NovelLastRead(
    chapterId: chapterId.clamp(0, 0x7fffffff).toInt(),
    chapterUrl: _asString(
      chapter['chapterUrl'] ??
          chapter['chapter_url'] ??
          payload['chapterUrl'] ??
          payload['chapter_url'],
    ),
    progress: _asInt(
      chapter['progress'] ?? payload['progress'],
    ).clamp(0, 100).toInt(),
    updatedAt:
        _asDateTime(payload['lastReadAt'] ?? payload['last_read_at']) ??
        _asDateTime(
          chapter['readAt'] ??
              chapter['read_at'] ??
              payload['updatedAt'] ??
              payload['updated_at'],
        ),
  );
}

Map<String, dynamic> _historyPayload(Map<String, dynamic> response) {
  final data = _asMap(response['data']);
  if (data.isNotEmpty) {
    return data;
  }
  final item = _asMap(response['item']);
  if (item.isNotEmpty) {
    return item;
  }
  final history = _asMap(response['history']);
  if (history.isNotEmpty) {
    return history;
  }
  final items = response['items'];
  if (items is List && items.isNotEmpty) {
    return _asMap(items.first);
  }
  return response;
}

Map<String, dynamic> _asMap(Object? input) {
  if (input is Map<String, dynamic>) {
    return input;
  }
  if (input is Map) {
    return input.map((key, value) => MapEntry(key.toString(), value));
  }
  return const {};
}

String _asString(Object? input) => input?.toString().trim() ?? '';

int _asInt(Object? input) {
  if (input is int) {
    return input;
  }
  if (input is num) {
    return input.toInt();
  }
  return int.tryParse(input?.toString() ?? '') ?? 0;
}

DateTime? _asDateTime(Object? input) {
  return DateTime.tryParse(_asString(input))?.toUtc();
}
