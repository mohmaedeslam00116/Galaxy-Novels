import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/core/config/app_config.dart';
import 'package:galaxy_novels_app/core/network/private_api_client.dart';
import 'package:galaxy_novels_app/data/models/reader_content_data.dart';
import 'package:galaxy_novels_app/data/repositories/reader_repository.dart';
import 'package:galaxy_novels_app/features/vip/data/private_vip_repository.dart';
import 'package:galaxy_novels_app/features/vip/data/vip_aware_reader_repository.dart';
import 'package:galaxy_novels_app/features/vip/data/vip_reader_request.dart';

void main() {
  test('routes public requests to the public reader repository', () async {
    final public = _FakeReaderRepository();
    final repository = VipAwareReaderRepository(
      publicReader: public,
      vipRepository: PrivateVipRepository(
        client: PrivateApiClient(
          config: const AppConfig(siteBaseUrl: 'https://example.com/'),
          requestSender: (_) async {
            throw StateError('VIP must not be called.');
          },
        ),
      ),
    );

    final content = await repository.loadChapter(
      '/wp-json/wor-reader-app/v1/chapters/1',
    );

    expect(content.id, 1);
    expect(public.calls, 1);
  });

  test(
    'routes vip chapter content_api requests to the private endpoint',
    () async {
      late PrivateRawRequest sent;
      final vip = PrivateVipRepository(
        client: PrivateApiClient(
          config: const AppConfig(siteBaseUrl: 'https://example.com/'),
          requestSender: (request) async {
            sent = request;
            return const PrivateRawResponse(
              statusCode: 200,
              body:
                  '{"data":{"id":44,"novel_id":8,'
                  '"label":"الفصل 44","title":"VIP",'
                  '"display_title":"VIP","position":44,"total":80,'
                  '"content_html":"<p>خاص</p>",'
                  '"navigation":{"previous_api":"",'
                  '"next_api":"vip:next:44",'
                  '"previous_id":0,"next_id":45}}}',
            );
          },
        )..updateAccessToken('wra_vip_token'),
      );
      final repository = VipAwareReaderRepository(
        publicReader: _FakeReaderRepository(),
        vipRepository: vip,
      );

      final content = await repository.loadChapter(
        '/wp-json/wor-reader-app/v1/vip/chapters/44',
      );

      expect(sent.uri.path, '/wp-json/wor-reader-app/v1/vip/chapters/44');
      expect(sent.uri.queryParameters, isEmpty);
      expect(content.id, 44);
      expect(content.contentHtml, '<p>خاص</p>');
    },
  );

  test('routes vip next requests and adapts the HTML fragment', () async {
    late PrivateRawRequest sent;
    final vip = PrivateVipRepository(
      client: PrivateApiClient(
        config: const AppConfig(siteBaseUrl: 'https://example.com/'),
        requestSender: (request) async {
          sent = request;
          return const PrivateRawResponse(
            statusCode: 200,
            body:
                '{"chapter_id":45,'
                '"html":"<article data-chapter-id=\\"45\\" '
                'data-novel-id=\\"8\\" data-chapter-label=\\"الفصل 45\\" '
                'data-chapter-title=\\"الفصل الخاص\\" '
                'data-position=\\"45\\" data-total=\\"80\\" '
                'data-next-id=\\"46\\" data-previous-url=\\"/chapter/44\\">'
                '<div class=\\"wor-reading-page__content\\">'
                '<p>الفصل التالي</p></div></article>"}',
          );
        },
      )..updateAccessToken('wra_vip_token'),
    );
    final repository = VipAwareReaderRepository(
      publicReader: _FakeReaderRepository(),
      vipRepository: vip,
    );

    final content = await repository.loadChapter(
      VipReaderRequest.nextAfter(44),
    );

    expect(sent.uri.path, '/wp-json/wor-reader-app/v1/vip/continuous-next');
    expect(sent.uri.queryParameters['chapter_id'], '44');
    expect(content.id, 45);
    expect(content.novelId, 8);
    expect(content.contentHtml, '<p>الفصل التالي</p>');
    expect(content.navigation.previousApi, VipReaderRequest.chapter(44));
    expect(content.navigation.nextApi, VipReaderRequest.chapter(46));
  });
}

class _FakeReaderRepository implements ReaderRepository {
  int calls = 0;

  @override
  Future<ReaderChapterContent> loadChapter(String contentApi) async {
    calls++;
    return const ReaderChapterContent(
      id: 1,
      novelId: 2,
      label: 'الفصل 1',
      title: 'عام',
      displayTitle: 'عام',
      position: 1,
      total: 10,
      contentHtml: '<p>عام</p>',
      navigation: ReaderChapterNavigation(
        previousApi: '',
        nextApi: '',
        previousId: 0,
        nextId: 0,
      ),
    );
  }
}
