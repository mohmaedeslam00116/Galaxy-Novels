enum CommentVote {
  like('like'),
  dislike('dislike');

  const CommentVote(this.apiValue);

  final String apiValue;

  static CommentVote? fromApi(Object? value) {
    final normalized = value?.toString().trim() ?? '';
    for (final vote in values) {
      if (vote.apiValue == normalized) {
        return vote;
      }
    }
    return null;
  }
}

enum CommentReaction {
  like('like', 'أعجبني'),
  laugh('laugh', 'مضحك'),
  love('love', 'أحببته'),
  wow('wow', 'مفاجئ'),
  angry('angry', 'غاضب'),
  sad('sad', 'حزين');

  const CommentReaction(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static CommentReaction? fromApi(Object? value) {
    final normalized = value?.toString().trim() ?? '';
    for (final reaction in values) {
      if (reaction.apiValue == normalized) {
        return reaction;
      }
    }
    return null;
  }
}

class CommentVoteResult {
  const CommentVoteResult({
    required this.commentId,
    required this.vote,
    required this.likeCount,
    required this.dislikeCount,
    required this.score,
  });

  factory CommentVoteResult.fromJson(Map<String, dynamic> json) {
    final commentId = _asInt(json['comment_id']);
    if (commentId <= 0) {
      throw const FormatException('Comment vote result must include id.');
    }
    final counts = _asMap(json['counts']);
    return CommentVoteResult(
      commentId: commentId,
      vote: CommentVote.fromApi(json['vote']),
      likeCount: _asInt(counts['like_count']).clamp(0, 1 << 31).toInt(),
      dislikeCount: _asInt(counts['dislike_count']).clamp(0, 1 << 31).toInt(),
      score: _asInt(counts['score']),
    );
  }

  final int commentId;
  final CommentVote? vote;
  final int likeCount;
  final int dislikeCount;
  final int score;
}

class CommentReactionResult {
  CommentReactionResult({
    required this.reaction,
    required Map<CommentReaction, int> counts,
  }) : counts = Map<CommentReaction, int>.unmodifiable(counts);

  factory CommentReactionResult.fromJson(Map<String, dynamic> json) {
    final countsJson = _asMap(json['counts']);
    final counts = <CommentReaction, int>{};
    for (final reaction in CommentReaction.values) {
      counts[reaction] = _asInt(
        countsJson[reaction.apiValue],
      ).clamp(0, 1 << 31).toInt();
    }
    return CommentReactionResult(
      reaction: CommentReaction.fromApi(json['reaction']),
      counts: counts,
    );
  }

  final CommentReaction? reaction;
  final Map<CommentReaction, int> counts;
}

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return const {};
}

int _asInt(Object? value) {
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
