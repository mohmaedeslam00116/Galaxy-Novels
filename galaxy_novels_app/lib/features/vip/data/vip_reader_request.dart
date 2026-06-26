enum VipReaderRequestKind { chapter, nextAfter }

class VipReaderRequest {
  const VipReaderRequest._({required this.kind, required this.chapterId});

  final VipReaderRequestKind kind;
  final int chapterId;

  static String chapter(int chapterId) => 'vip:chapter:$chapterId';

  static String nextAfter(int chapterId) => 'vip:next:$chapterId';

  static VipReaderRequest? tryParse(String value) {
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
}
