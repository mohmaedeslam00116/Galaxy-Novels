import '../../../core/network/private_api_client.dart';
import '../../../data/models/reading_progress.dart';

class ReadingHistoryRemoteService {
  const ReadingHistoryRemoteService({required PrivateApiClient client})
    : _client = client;

  final PrivateApiClient _client;

  Future<List<ReadingProgress>> fetchHistory() async {
    final response = await _client.getAuthenticatedWithNonceRefresh(
      'me/history',
    );
    return _asList(response['items'])
        .map((entry) => _progressFromServer(_asMap(entry)))
        .where((progress) => progress.novelId > 0 && progress.chapterId > 0)
        .toList(growable: false);
  }
}

ReadingProgress _progressFromServer(Map<String, dynamic> json) {
  final chapter = _asMap(json['lastChapter']);
  final chapterId = _asInt(chapter['chapterId']);
  final lastReadAt = _asDateTime(json['lastReadAt']);
  final chapterReadAt = _asDateTime(chapter['readAt']);
  final chapterLabel = _asString(chapter['label']);
  final chapterTitle = _asString(chapter['title']);
  return ReadingProgress(
    novelId: _asInt(json['novelId']),
    novelTitle: _asString(json['title']),
    chapterId: chapterId,
    chapterTitle: chapterLabel.isNotEmpty ? chapterLabel : chapterTitle,
    contentApi: chapterId > 0
        ? '/wp-json/wor-reader-app/v1/chapters/$chapterId'
        : '',
    updatedAt:
        lastReadAt ??
        chapterReadAt ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
  );
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

List<Object?> _asList(Object? input) {
  return input is List ? input.cast<Object?>() : const [];
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
