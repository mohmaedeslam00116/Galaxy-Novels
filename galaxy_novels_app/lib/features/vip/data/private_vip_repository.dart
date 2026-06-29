import '../../../core/network/private_api_client.dart';
import '../../../data/models/reader_content_data.dart';
import '../application/vip_repository.dart';
import '../domain/vip_chapter.dart';
import 'vip_reader_request.dart';

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

  Future<ReaderChapterContent> loadChapterById(int chapterId) async {
    if (chapterId <= 0) {
      throw const FormatException('VIP chapter id must be positive.');
    }

    try {
      final json = await _client.getAuthenticated('vip/chapters/$chapterId');
      return ReaderChapterContent.fromJson(json);
    } on PrivateApiException catch (error) {
      throw _vipExceptionFrom(error);
    }
  }

  Future<ReaderChapterContent> loadNextAfter(int chapterId) async {
    if (chapterId <= 0) {
      throw const FormatException('VIP chapter id must be positive.');
    }

    try {
      final json = await _client.getAuthenticated(
        'vip/continuous-next?chapter_id=$chapterId',
      );
      return _readerContentFromVipNext(json);
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

ReaderChapterContent _readerContentFromVipNext(Map<String, dynamic> json) {
  if (json.containsKey('data') || json.containsKey('content_html')) {
    return ReaderChapterContent.fromJson(json);
  }

  final html = json['html']?.toString() ?? '';
  final chapterId = int.tryParse(json['chapter_id']?.toString() ?? '') ?? 0;
  if (html.isEmpty || chapterId <= 0) {
    throw const FormatException('Invalid VIP next chapter response.');
  }

  final attrs = _articleAttributes(html);
  final contentHtml = _contentHtml(html);
  final nextId = int.tryParse(attrs['data-next-id'] ?? '') ?? 0;
  final previousId = _idFromUrl(attrs['data-previous-url'] ?? '');

  return ReaderChapterContent(
    id: chapterId,
    novelId: int.tryParse(attrs['data-novel-id'] ?? '') ?? 0,
    label: attrs['data-chapter-label'] ?? '',
    title: attrs['data-chapter-title'] ?? '',
    displayTitle:
        attrs['data-chapter-title'] ?? attrs['data-chapter-label'] ?? '',
    position: int.tryParse(attrs['data-position'] ?? '') ?? 0,
    total: int.tryParse(attrs['data-total'] ?? '') ?? 0,
    contentHtml: contentHtml,
    navigation: ReaderChapterNavigation(
      previousApi: previousId > 0 ? VipReaderRequest.chapter(previousId) : '',
      nextApi: nextId > 0 ? VipReaderRequest.chapter(nextId) : '',
      previousId: previousId,
      nextId: nextId,
    ),
  );
}

Map<String, String> _articleAttributes(String html) {
  final article =
      RegExp(
        r'<article\b([^>]*)>',
        multiLine: true,
      ).firstMatch(html)?.group(1) ??
      '';
  final attrs = <String, String>{};
  for (final match in RegExp(
    r'(data-[a-zA-Z0-9_-]+)="([^"]*)"',
  ).allMatches(article)) {
    attrs[match.group(1)!] = match.group(2)!;
  }
  return attrs;
}

String _contentHtml(String html) {
  final match = RegExp(
    r'<div[^>]*class="[^"]*wor-reading-page__content[^"]*"[^>]*>([\s\S]*?)</div>\s*</article>',
    multiLine: true,
  ).firstMatch(html);
  return match?.group(1)?.trim() ?? html;
}

int _idFromUrl(String url) {
  final match = RegExp(r'(\d+)(?:/)?$').firstMatch(url);
  return int.tryParse(match?.group(1) ?? '') ?? 0;
}
