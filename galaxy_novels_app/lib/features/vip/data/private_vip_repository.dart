import '../../../core/network/private_api_client.dart';
import '../application/vip_repository.dart';
import '../domain/vip_chapter.dart';

class PrivateVipRepository implements VipRepository {
  const PrivateVipRepository({required PrivateApiClient client})
    : _client = client;

  final PrivateApiClient _client;

  @override
  Future<VipChapterPage> loadChapters(VipChapterQuery query) async {
    try {
      final params = <String, String>{
        'novel_id': query.novelId.toString(),
        'limit': query.limit.toString(),
        'order': query.order == VipChapterOrder.desc ? 'desc' : 'asc',
      };
      if (query.cursorOrder.isNotEmpty) {
        params['cursor_order'] = query.cursorOrder;
        params['cursor_id'] = query.cursorId.toString();
      }
      if (query.search.trim().isNotEmpty) {
        params['search'] = query.search.trim();
      }

      final path = Uri(
        path: 'vip/chapters',
        queryParameters: params,
      ).toString();
      final json = await _client.getAuthenticated(path);
      return VipChapterPage.fromJson(json);
    } on PrivateApiException catch (error) {
      throw _vipExceptionFrom(error);
    }
  }
}

VipAccessException _vipExceptionFrom(PrivateApiException error) {
  if (error.statusCode == 401) {
    return VipAccessException(VipAccessReason.loginRequired, error.message);
  }
  if (error.statusCode == 403) {
    return VipAccessException(
      VipAccessReason.subscriptionRequired,
      error.message,
    );
  }
  return VipAccessException(VipAccessReason.unavailable, error.message);
}
