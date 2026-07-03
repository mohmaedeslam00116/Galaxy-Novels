import '../../../core/network/private_api_client.dart';
import '../../../data/models/reading_progress.dart';

class ReadingHistoryRemoteService {
  const ReadingHistoryRemoteService({required PrivateApiClient client})
    : _client = client;

  final PrivateApiClient _client;

  Future<List<ReadingProgress>> fetchHistory() async {
    final response = await _client.getAuthenticated('me/history');
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
  final contentApi = _historyChapterContentApi(chapter, chapterId);
  return ReadingProgress(
    novelId: _asInt(json['novelId']),
    novelTitle: _asString(json['title']),
    chapterId: chapterId,
    chapterTitle: chapterLabel.isNotEmpty ? chapterLabel : chapterTitle,
    contentApi: contentApi,
    coverUrl: _historyCoverUrl(json),
    updatedAt:
        lastReadAt ??
        chapterReadAt ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
  );
}

String _historyCoverUrl(Map<String, dynamic> json) {
  final cover = _asMap(json['cover']);
  return _firstNonEmptyString([
    cover['medium'],
    cover['large'],
    cover['thumbnail'],
    cover['url'],
    json['coverUrl'],
    json['cover_url'],
    json['cover_medium'],
    json['cover_thumbnail'],
    _asMap(json['links'])['cover'],
  ]);
}

String _historyChapterContentApi(Map<String, dynamic> chapter, int chapterId) {
  if (chapterId <= 0) {
    return '';
  }

  final explicitApi = _firstNonEmptyString([
    chapter['content_api'],
    chapter['contentApi'],
    chapter['api'],
    _asMap(chapter['links'])['content_api'],
    _asMap(chapter['links'])['contentApi'],
  ]);
  if (explicitApi.isNotEmpty) {
    return explicitApi;
  }

  if (_isVipChapter(chapter)) {
    return '/wp-json/wor-reader-app/v1/vip/chapters/$chapterId';
  }
  return '/wp-json/wor-reader-app/v1/chapters/$chapterId';
}

String _firstNonEmptyString(List<Object?> values) {
  for (final value in values) {
    final text = _asString(value);
    if (text.isNotEmpty) {
      return text;
    }
  }
  return '';
}

bool _isVipChapter(Map<String, dynamic> chapter) {
  for (final key in const [
    'is_vip',
    'isVip',
    'vip',
    'private',
    'is_private',
    'requires_vip',
  ]) {
    if (_asBool(chapter[key])) {
      return true;
    }
  }

  for (final key in const ['type', 'kind', 'source', 'access']) {
    final text = _asString(chapter[key]).toLowerCase();
    if (text == 'vip' || text == 'private') {
      return true;
    }
  }
  return false;
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

bool _asBool(Object? input) {
  if (input is bool) {
    return input;
  }
  if (input is num) {
    return input != 0;
  }
  final text = _asString(input).toLowerCase();
  return text == 'true' || text == '1' || text == 'yes';
}
