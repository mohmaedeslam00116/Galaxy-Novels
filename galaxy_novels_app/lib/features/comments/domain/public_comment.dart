import 'comment_interaction.dart';

class PublicComment {
  PublicComment({
    required this.id,
    required this.parentId,
    required this.rootId,
    required this.depth,
    required this.authorName,
    required this.authorRank,
    required this.avatarUrl,
    required this.replyToName,
    required this.content,
    required this.isSpoiler,
    required this.likeCount,
    required this.dislikeCount,
    required this.repliesCount,
    required this.score,
    this.myVote,
    required this.isPinned,
    required this.createdLabel,
    required this.createdAt,
    required List<PublicComment> replies,
  }) : replies = List<PublicComment>.unmodifiable(replies);

  factory PublicComment.fromJson(Map<String, dynamic> json) {
    final id = _asInt(json['id']);
    if (id <= 0) {
      throw const FormatException('Comment id must be positive.');
    }

    return PublicComment(
      id: id,
      parentId: _asInt(json['parent_id']),
      rootId: _asInt(json['root_id']),
      depth: _asInt(json['depth']).clamp(0, 2).toInt(),
      authorName: _asString(json['author_name'], fallback: 'قارئ'),
      authorRank: _asString(json['author_rank']),
      avatarUrl: _asString(json['avatar_url']),
      replyToName: _asString(json['reply_to_name']),
      content: _asString(json['content']),
      isSpoiler: _asBool(json['is_spoiler']),
      likeCount: _asInt(json['like_count']).clamp(0, 1 << 31).toInt(),
      dislikeCount: _asInt(json['dislike_count']).clamp(0, 1 << 31).toInt(),
      repliesCount: _asInt(json['replies_count']).clamp(0, 1 << 31).toInt(),
      score: _asInt(json['score']),
      myVote: CommentVote.fromApi(json['my_vote']),
      isPinned: _asBool(json['is_pinned']),
      createdLabel: _asString(json['created_at']),
      createdAt: DateTime.tryParse(_asString(json['created_iso'])),
      replies: _asList(json['replies'])
          .map((replyJson) => PublicComment.fromJson(_asMap(replyJson)))
          .toList(growable: false),
    );
  }

  final int id;
  final int parentId;
  final int rootId;
  final int depth;
  final String authorName;
  final String authorRank;
  final String avatarUrl;
  final String replyToName;
  final String content;
  final bool isSpoiler;
  final int likeCount;
  final int dislikeCount;
  final int repliesCount;
  final int score;
  final CommentVote? myVote;
  final bool isPinned;
  final String createdLabel;
  final DateTime? createdAt;
  final List<PublicComment> replies;

  PublicComment copyWith({
    int? likeCount,
    int? dislikeCount,
    int? repliesCount,
    int? score,
    CommentVote? myVote,
    bool clearMyVote = false,
    List<PublicComment>? replies,
  }) {
    return PublicComment(
      id: id,
      parentId: parentId,
      rootId: rootId,
      depth: depth,
      authorName: authorName,
      authorRank: authorRank,
      avatarUrl: avatarUrl,
      replyToName: replyToName,
      content: content,
      isSpoiler: isSpoiler,
      likeCount: likeCount ?? this.likeCount,
      dislikeCount: dislikeCount ?? this.dislikeCount,
      repliesCount: repliesCount ?? this.repliesCount,
      score: score ?? this.score,
      myVote: clearMyVote ? null : myVote ?? this.myVote,
      isPinned: isPinned,
      createdLabel: createdLabel,
      createdAt: createdAt,
      replies: replies ?? this.replies,
    );
  }
}

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return const {};
}

List<Object?> _asList(Object? value) => value is List ? value : const [];

String _asString(Object? value, {String fallback = ''}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

int _asInt(Object? value) {
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

bool _asBool(Object? value) =>
    value == true || value == 1 || value?.toString() == '1';
