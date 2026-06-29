enum VipReaderRequestKind { chapter, nextAfter }

class VipReaderRequest {
  const VipReaderRequest._({required this.kind, required this.chapterId});

  final VipReaderRequestKind kind;
  final int chapterId;

  static String chapter(int chapterId) => 'vip:chapter:$chapterId';

  static String nextAfter(int chapterId) => 'vip:next:$chapterId';

  static VipReaderRequest? tryParse(String value) {
    final text = value.trim();
    if (text.isEmpty) {
      return null;
    }

    final internal = _tryParseInternal(text);
    if (internal != null) {
      return internal;
    }

    final uri = Uri.tryParse(text);
    if (uri == null) {
      return null;
    }

    final segments = uri.pathSegments;
    if (segments.length >= 3 &&
        segments[segments.length - 3] == 'vip' &&
        segments[segments.length - 2] == 'chapters') {
      return _fromId(
        VipReaderRequestKind.chapter,
        int.tryParse(segments.last) ?? 0,
      );
    }

    if (segments.length >= 2 &&
        segments[segments.length - 2] == 'vip' &&
        segments.last == 'chapter') {
      return _fromId(
        VipReaderRequestKind.chapter,
        int.tryParse(uri.queryParameters['chapter_id'] ?? '') ?? 0,
      );
    }

    if (segments.length >= 2 &&
        segments[segments.length - 2] == 'vip' &&
        segments.last == 'continuous-next') {
      return _fromId(
        VipReaderRequestKind.nextAfter,
        int.tryParse(uri.queryParameters['chapter_id'] ?? '') ?? 0,
      );
    }

    return null;
  }

  static VipReaderRequest? _tryParseInternal(String value) {
    final parts = value.split(':');
    if (parts.length != 3 || parts.first != 'vip') {
      return null;
    }

    final chapterId = int.tryParse(parts[2]) ?? 0;
    if (chapterId <= 0) {
      return null;
    }

    return switch (parts[1]) {
      'chapter' => VipReaderRequest._(
        kind: VipReaderRequestKind.chapter,
        chapterId: chapterId,
      ),
      'next' => VipReaderRequest._(
        kind: VipReaderRequestKind.nextAfter,
        chapterId: chapterId,
      ),
      _ => null,
    };
  }

  static VipReaderRequest? _fromId(VipReaderRequestKind kind, int chapterId) {
    if (chapterId <= 0) {
      return null;
    }
    return VipReaderRequest._(kind: kind, chapterId: chapterId);
  }
}
