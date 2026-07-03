import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/core/config/app_config.dart';
import 'package:galaxy_novels_app/core/network/private_api_client.dart';
import 'package:galaxy_novels_app/features/history/data/reading_history_remote_service.dart';

void main() {
  test('maps account history without inventing whole-novel progress', () async {
    late PrivateRawRequest capturedRequest;
    final client = PrivateApiClient(
      config: const AppConfig(siteBaseUrl: 'https://example.com/'),
      requestSender: (request) async {
        capturedRequest = request;
        return const PrivateRawResponse(
          statusCode: 200,
          body: '''
            {"items":[{
              "novelId":42,
              "title":"رواية الحساب",
              "lastReadAt":"2026-06-23T12:30:00+00:00",
              "chapterCount":18,
              "lastChapter":{
                "chapterId":501,
                "label":"الفصل 18",
                "title":"عنوان طويل",
                "readAt":"2026-06-23T12:29:00+00:00"
              }
            }]}
          ''',
        );
      },
    )..updateAccessToken('wra_test_token');
    final service = ReadingHistoryRemoteService(client: client);

    final history = await service.fetchHistory();

    expect(capturedRequest.uri.path, endsWith('/me/history'));
    expect(capturedRequest.headers['Authorization'], 'Bearer wra_test_token');
    expect(capturedRequest.headers, isNot(contains('X-WP-Nonce')));
    expect(history.single.novelId, 42);
    expect(history.single.chapterId, 501);
    expect(history.single.chapterTitle, 'الفصل 18');
    expect(
      history.single.contentApi,
      '/wp-json/wor-reader-app/v1/chapters/501',
    );
    expect(history.single.completionFraction, isNull);
    expect(history.single.completionPercent, isNull);
  });

  test('preserves VIP chapter content API from account history', () async {
    final client = PrivateApiClient(
      config: const AppConfig(siteBaseUrl: 'https://example.com/'),
      requestSender: (_) async {
        return const PrivateRawResponse(
          statusCode: 200,
          body: '''
            {"items":[{
              "novelId":42,
              "title":"رواية VIP",
              "lastReadAt":"2026-06-23T12:30:00+00:00",
              "lastChapter":{
                "chapterId":275,
                "label":"الفصل 275",
                "is_vip":true,
                "content_api":"/wp-json/wor-reader-app/v1/vip/chapters/275",
                "readAt":"2026-06-23T12:29:00+00:00"
              }
            }]}
          ''',
        );
      },
    )..updateAccessToken('wra_test_token');
    final service = ReadingHistoryRemoteService(client: client);

    final history = await service.fetchHistory();

    expect(history.single.chapterId, 275);
    expect(
      history.single.contentApi,
      '/wp-json/wor-reader-app/v1/vip/chapters/275',
    );
    expect(history.single.completionPercent, isNull);
  });

  test('maps a novel cover from account history when provided', () async {
    final client = PrivateApiClient(
      config: const AppConfig(siteBaseUrl: 'https://example.com/'),
      requestSender: (_) async {
        return const PrivateRawResponse(
          statusCode: 200,
          body: '''
            {"items":[{
              "novelId":42,
              "title":"رواية بغلاف",
              "cover":{
                "thumbnail":"/wp-content/uploads/covers/small.jpg",
                "medium":"/wp-content/uploads/covers/medium.jpg"
              },
              "lastReadAt":"2026-06-23T12:30:00+00:00",
              "lastChapter":{
                "chapterId":501,
                "label":"الفصل 18",
                "readAt":"2026-06-23T12:29:00+00:00"
              }
            }]}
          ''',
        );
      },
    )..updateAccessToken('wra_test_token');
    final service = ReadingHistoryRemoteService(client: client);

    final history = await service.fetchHistory();

    expect(history.single.coverUrl, '/wp-content/uploads/covers/medium.jpg');
  });

  test(
    'builds a VIP content API when history only marks the chapter as VIP',
    () async {
      final client = PrivateApiClient(
        config: const AppConfig(siteBaseUrl: 'https://example.com/'),
        requestSender: (_) async {
          return const PrivateRawResponse(
            statusCode: 200,
            body: '''
            {"items":[{
              "novelId":42,
              "title":"رواية VIP",
              "lastReadAt":"2026-06-23T12:30:00+00:00",
              "lastChapter":{
                "chapterId":276,
                "label":"الفصل 276",
                "vip":true,
                "readAt":"2026-06-23T12:29:00+00:00"
              }
            }]}
          ''',
          );
        },
      )..updateAccessToken('wra_test_token');
      final service = ReadingHistoryRemoteService(client: client);

      final history = await service.fetchHistory();

      expect(
        history.single.contentApi,
        '/wp-json/wor-reader-app/v1/vip/chapters/276',
      );
    },
  );
}
