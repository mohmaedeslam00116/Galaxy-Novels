enum CommentTargetType {
  novel('novel'),
  chapter('chapter');

  const CommentTargetType(this.apiValue);

  final String apiValue;
}

enum CommentsSort {
  newest('newest', 'الأحدث'),
  top('top', 'الأعلى'),
  replies('replies', 'الأكثر ردودًا'),
  oldest('oldest', 'الأقدم');

  const CommentsSort(this.apiValue, this.label);

  final String apiValue;
  final String label;
}

class CommentTarget {
  const CommentTarget._(this.type, this.id);

  factory CommentTarget.novel(int id) =>
      CommentTarget._(CommentTargetType.novel, _validatedId(id));

  factory CommentTarget.chapter(int id) =>
      CommentTarget._(CommentTargetType.chapter, _validatedId(id));

  final CommentTargetType type;
  final int id;

  String get pathSegment => '${type.apiValue}/$id';

  static int _validatedId(int id) {
    if (id <= 0) {
      throw RangeError.value(id, 'id', 'Comment target id must be positive.');
    }
    return id;
  }

  @override
  bool operator ==(Object other) =>
      other is CommentTarget && other.type == type && other.id == id;

  @override
  int get hashCode => Object.hash(type, id);
}
