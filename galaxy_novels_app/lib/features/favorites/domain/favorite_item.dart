class FavoriteItem {
  const FavoriteItem({
    required this.id,
    required this.title,
    required this.url,
    required this.cover,
    required this.manifestPath,
    required this.addedAt,
  });

  factory FavoriteItem.fromJson(Map<String, dynamic> json) {
    return FavoriteItem(
      id: _asInt(json['id']),
      title: _asString(json['title']),
      url: _asString(json['url']),
      cover: _asString(json['cover']),
      manifestPath: _asString(json['manifest_path']),
      addedAt:
          DateTime.tryParse(_asString(json['added_at']))?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  final int id;
  final String title;
  final String url;
  final String cover;
  final String manifestPath;
  final DateTime addedAt;

  FavoriteItem copyWith({
    String? title,
    String? url,
    String? cover,
    String? manifestPath,
    DateTime? addedAt,
  }) {
    return FavoriteItem(
      id: id,
      title: title ?? this.title,
      url: url ?? this.url,
      cover: cover ?? this.cover,
      manifestPath: manifestPath ?? this.manifestPath,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'title': title,
      'url': url,
      'cover': cover,
      'manifest_path': manifestPath,
      'added_at': addedAt.toUtc().toIso8601String(),
    };
  }
}

enum FavoriteChangeAction {
  add('add'),
  remove('remove');

  const FavoriteChangeAction(this.apiValue);

  final String apiValue;
}

class FavoriteChange {
  const FavoriteChange({
    required this.novelId,
    required this.action,
    required this.changedAt,
  });

  factory FavoriteChange.fromJson(Map<String, dynamic> json) {
    final actionValue = _asString(json['action']);
    return FavoriteChange(
      novelId: _asInt(json['novel_id']),
      action: actionValue == FavoriteChangeAction.remove.apiValue
          ? FavoriteChangeAction.remove
          : FavoriteChangeAction.add,
      changedAt:
          DateTime.tryParse(_asString(json['changed_at']))?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  final int novelId;
  final FavoriteChangeAction action;
  final DateTime changedAt;

  bool get shouldExist => action == FavoriteChangeAction.add;

  bool isSameOperation(FavoriteChange other) {
    return novelId == other.novelId &&
        action == other.action &&
        changedAt == other.changedAt;
  }

  Map<String, Object?> toJson() {
    return {
      'novel_id': novelId,
      'action': action.apiValue,
      'changed_at': changedAt.toUtc().toIso8601String(),
    };
  }

  Map<String, Object?> toRequestJson() {
    return {'novel_id': novelId, 'action': action.apiValue};
  }
}

class FavoriteLocalSnapshot {
  FavoriteLocalSnapshot({
    List<FavoriteItem> items = const [],
    List<FavoriteChange> pendingChanges = const [],
  }) : items = List.unmodifiable(items),
       pendingChanges = List.unmodifiable(pendingChanges);

  final List<FavoriteItem> items;
  final List<FavoriteChange> pendingChanges;
}

String favoriteManifestPath(int novelId) {
  return '/wp-content/uploads/wor-reader-cache/app/manifest/'
      'novel-$novelId.json';
}

String _asString(Object? input) => input?.toString().trim() ?? '';

int _asInt(Object? input) {
  if (input is int) {
    return input;
  }
  if (input is num) {
    return input.toInt();
  }
  return int.tryParse(input?.toString() ?? '') ?? 0;
}
