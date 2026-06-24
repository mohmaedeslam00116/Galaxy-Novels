import 'comment_target.dart';
import 'public_comment.dart';

class CommentsPage {
  CommentsPage({
    required this.version,
    required this.target,
    required this.sort,
    required this.page,
    required this.perPage,
    required this.totalComments,
    required this.totalRoots,
    required this.totalPages,
    required this.generated,
    required Map<String, int> reactions,
    required List<PublicComment> comments,
  }) : reactions = Map<String, int>.unmodifiable(reactions),
       comments = List<PublicComment>.unmodifiable(comments);

  factory CommentsPage.empty({
    required CommentTarget target,
    required CommentsSort sort,
    int page = 1,
  }) {
    return CommentsPage(
      version: 2,
      target: target,
      sort: sort,
      page: page,
      perPage: 20,
      totalComments: 0,
      totalRoots: 0,
      totalPages: 0,
      generated: 0,
      reactions: const {},
      comments: const [],
    );
  }

  factory CommentsPage.fromJson(
    Map<String, dynamic> json, {
    required CommentTarget expectedTarget,
    required CommentsSort expectedSort,
    required int expectedPage,
  }) {
    final objectType = json['object_type']?.toString() ?? '';
    final objectId = _asInt(json['object_id']);
    final sortValue = json['sort']?.toString() ?? '';
    final page = _asInt(json['page']);
    final perPage = _asInt(json['per_page']);
    final totalPages = _asInt(json['total_pages']);
    if (objectType != expectedTarget.type.apiValue ||
        objectId != expectedTarget.id ||
        sortValue != expectedSort.apiValue ||
        page != expectedPage ||
        perPage <= 0 ||
        totalPages < 0) {
      throw const FormatException('Invalid comments page identity.');
    }

    final reactions = <String, int>{};
    for (final entry in _asMap(json['reactions']).entries) {
      reactions[entry.key] = _asInt(entry.value).clamp(0, 1 << 31).toInt();
    }
    final comments = _asList(json['comments'])
        .map((commentJson) => PublicComment.fromJson(_asMap(commentJson)))
        .toList(growable: false);

    return CommentsPage(
      version: _asInt(json['version']),
      target: expectedTarget,
      sort: expectedSort,
      page: page,
      perPage: perPage,
      totalComments: _asInt(json['total_comments']).clamp(0, 1 << 31).toInt(),
      totalRoots: _asInt(json['total_roots']).clamp(0, 1 << 31).toInt(),
      totalPages: totalPages,
      generated: _asInt(json['generated']).clamp(0, 1 << 62).toInt(),
      reactions: reactions,
      comments: comments,
    );
  }

  final int version;
  final CommentTarget target;
  final CommentsSort sort;
  final int page;
  final int perPage;
  final int totalComments;
  final int totalRoots;
  final int totalPages;
  final int generated;
  final Map<String, int> reactions;
  final List<PublicComment> comments;

  bool get hasNextPage => page < totalPages;
}

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return const {};
}

List<Object?> _asList(Object? value) => value is List ? value : const [];

int _asInt(Object? value) {
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
