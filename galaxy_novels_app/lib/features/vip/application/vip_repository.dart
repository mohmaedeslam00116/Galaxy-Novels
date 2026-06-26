import '../domain/vip_chapter.dart';

enum VipChapterOrder { asc, desc }

class VipChapterQuery {
  const VipChapterQuery({
    required this.novelId,
    this.cursorOrder = '',
    this.cursorId = 0,
    this.limit = 50,
    this.order = VipChapterOrder.asc,
    this.search = '',
  });

  final int novelId;
  final String cursorOrder;
  final int cursorId;
  final int limit;
  final VipChapterOrder order;
  final String search;
}

enum VipAccessReason { loginRequired, subscriptionRequired, unavailable }

class VipAccessException implements Exception {
  const VipAccessException(this.reason, this.message);

  final VipAccessReason reason;
  final String message;

  @override
  String toString() => 'VipAccessException($reason): $message';
}

abstract interface class VipRepository {
  Future<VipChapterPage> loadChapters(VipChapterQuery query);
}
