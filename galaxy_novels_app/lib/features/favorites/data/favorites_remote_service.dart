import '../../../core/network/private_api_client.dart';
import '../domain/favorite_item.dart';

class FavoritesRemoteService {
  const FavoritesRemoteService({required PrivateApiClient client})
    : _client = client;

  final PrivateApiClient _client;

  Future<List<FavoriteItem>> fetchFavorites() async {
    final response = await _requestWithNonceRefresh(
      () => _client.getAuthenticated('me/favorites'),
    );
    return _asList(response['items'])
        .map((item) => _favoriteFromServer(_asMap(item)))
        .where((item) => item.id > 0 && item.title.isNotEmpty)
        .toList(growable: false);
  }

  Future<int> syncChanges(List<FavoriteChange> changes) async {
    if (changes.isEmpty) {
      return 0;
    }
    final response = await _requestWithNonceRefresh(
      () => _client.postAuthenticated(
        'me/favorites/sync',
        body: {
          'changes': changes
              .map((change) => change.toRequestJson())
              .toList(growable: false),
        },
      ),
    );
    return _asInt(response['accepted']);
  }

  Future<Map<String, dynamic>> _requestWithNonceRefresh(
    Future<Map<String, dynamic>> Function() request,
  ) async {
    try {
      return await request();
    } on PrivateApiException catch (error) {
      final nonceExpired =
          error.code == 'wor_reader_app_bad_nonce' ||
          error.code == 'missing_nonce';
      if (!nonceExpired) {
        rethrow;
      }

      final session = await _client.getPublic('session');
      final nonce = session['nonce']?.toString().trim() ?? '';
      if (session['logged_in'] != true || nonce.isEmpty) {
        throw const PrivateApiException(
          statusCode: 401,
          code: 'wor_reader_app_login_required',
          message: 'The private session has expired.',
        );
      }
      _client.updateNonce(nonce);
      return request();
    }
  }
}

FavoriteItem _favoriteFromServer(Map<String, dynamic> json) {
  final id = _asInt(json['id']);
  return FavoriteItem(
    id: id,
    title: json['title']?.toString().trim() ?? '',
    url: json['url']?.toString().trim() ?? '',
    cover: json['cover']?.toString().trim() ?? '',
    manifestPath: favoriteManifestPath(id),
    addedAt:
        DateTime.tryParse(json['added_at']?.toString() ?? '')?.toUtc() ??
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

int _asInt(Object? input) {
  if (input is int) {
    return input;
  }
  if (input is num) {
    return input.toInt();
  }
  return int.tryParse(input?.toString() ?? '') ?? 0;
}
