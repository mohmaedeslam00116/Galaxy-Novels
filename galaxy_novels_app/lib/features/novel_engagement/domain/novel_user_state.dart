class NovelUserState {
  const NovelUserState({
    required this.novelId,
    required this.favorite,
    required this.myRating,
    required this.lastRead,
    required this.vip,
  });

  factory NovelUserState.fromResponse(
    Map<String, dynamic> json, {
    required int expectedNovelId,
  }) {
    final novelId = _asInt(json['novel_id']);
    if (novelId <= 0 || novelId != expectedNovelId) {
      throw const FormatException('Unexpected novel user state payload.');
    }

    final rawRating = _asInt(json['my_rating']);
    return NovelUserState(
      novelId: novelId,
      favorite: json['favorite'] == true,
      myRating: rawRating >= 1 && rawRating <= 5 ? rawRating : 0,
      lastRead: NovelLastRead.fromJson(_asMap(json['last_read'])),
      vip: NovelVipAccess.fromJson(_asMap(json['vip'])),
    );
  }

  final int novelId;
  final bool favorite;
  final int myRating;
  final NovelLastRead lastRead;
  final NovelVipAccess vip;

  NovelUserState copyWith({
    bool? favorite,
    int? myRating,
    NovelLastRead? lastRead,
    NovelVipAccess? vip,
  }) {
    return NovelUserState(
      novelId: novelId,
      favorite: favorite ?? this.favorite,
      myRating: myRating ?? this.myRating,
      lastRead: lastRead ?? this.lastRead,
      vip: vip ?? this.vip,
    );
  }
}

class NovelLastRead {
  const NovelLastRead({
    required this.chapterId,
    required this.chapterUrl,
    required this.progress,
    required this.updatedAt,
  });

  factory NovelLastRead.fromJson(Map<String, dynamic> json) {
    return NovelLastRead(
      chapterId: _asInt(json['chapter_id']).clamp(0, 0x7fffffff).toInt(),
      chapterUrl: json['chapter_url']?.toString().trim() ?? '',
      progress: _asInt(json['progress']).clamp(0, 100).toInt(),
      updatedAt: DateTime.tryParse(
        json['updated_at']?.toString() ?? '',
      )?.toUtc(),
    );
  }

  final int chapterId;
  final String chapterUrl;
  final int progress;
  final DateTime? updatedAt;
}

class NovelVipAccess {
  const NovelVipAccess({required this.active, required this.canReadPrivate});

  factory NovelVipAccess.fromJson(Map<String, dynamic> json) {
    return NovelVipAccess(
      active: json['active'] == true,
      canReadPrivate: json['can_read_private'] == true,
    );
  }

  final bool active;
  final bool canReadPrivate;
}

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  return const {};
}

int _asInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
