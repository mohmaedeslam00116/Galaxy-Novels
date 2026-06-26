import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/core/config/app_config.dart';
import 'package:galaxy_novels_app/core/network/private_api_client.dart';
import 'package:galaxy_novels_app/features/vip/application/vip_repository.dart';
import 'package:galaxy_novels_app/features/vip/data/private_vip_repository.dart';

void main() {
  test('loads VIP chapters with bearer auth and query parameters', () async {
    late PrivateRawRequest sent;
    final client = PrivateApiClient(
      config: const AppConfig(siteBaseUrl: 'https://example.com/'),
      requestSender: (request) async {
        sent = request;
        return const PrivateRawResponse(
          statusCode: 200,
          body:
              '{"items":[{"id":9,"number":"9","position":9}],'
              '"has_more":false,'
              '"next_cursor":{"order":"","id":0},'
              '"total_available":1}',
        );
      },
    )..updateAccessToken('wra_vip_token');
    final repository = PrivateVipRepository(client: client);

    final page = await repository.loadChapters(
      const VipChapterQuery(
        novelId: 77,
        limit: 25,
        order: VipChapterOrder.desc,
        search: '9',
      ),
    );

    expect(sent.method, 'GET');
    expect(sent.uri.path, '/wp-json/wor-reader-app/v1/vip/chapters');
    expect(sent.uri.queryParameters['novel_id'], '77');
    expect(sent.uri.queryParameters['limit'], '25');
    expect(sent.uri.queryParameters['order'], 'desc');
    expect(sent.uri.queryParameters['search'], '9');
    expect(sent.headers['Authorization'], 'Bearer wra_vip_token');
    expect(sent.headers, isNot(contains('X-WP-Nonce')));
    expect(page.items.single.id, 9);
  });

  test('maps 401 and 403 into VIP access exceptions', () async {
    Future<VipAccessException> loadWith(int statusCode, String code) async {
      final repository = PrivateVipRepository(
        client: PrivateApiClient(
          config: const AppConfig(siteBaseUrl: 'https://example.com/'),
          requestSender: (_) async => PrivateRawResponse(
            statusCode: statusCode,
            body: '{"code":"$code","message":"blocked"}',
          ),
        )..updateAccessToken('wra_vip_token'),
      );
      try {
        await repository.loadChapters(const VipChapterQuery(novelId: 77));
        throw StateError('Expected VipAccessException.');
      } on VipAccessException catch (error) {
        return error;
      }
    }

    expect(
      (await loadWith(401, 'login_required')).reason,
      VipAccessReason.loginRequired,
    );
    expect(
      (await loadWith(403, 'subscription_required')).reason,
      VipAccessReason.subscriptionRequired,
    );
  });
}
