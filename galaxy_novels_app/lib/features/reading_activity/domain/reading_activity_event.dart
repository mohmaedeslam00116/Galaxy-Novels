class ReadingActivityEvent {
  const ReadingActivityEvent({
    required this.ownerUserId,
    required this.eventId,
    required this.novelId,
    required this.chapterId,
    required this.activeSeconds,
    required this.openSeconds,
    required this.progress,
    required this.completed,
    required this.views,
    required this.readAt,
  });

  factory ReadingActivityEvent.fromStorageJson(Map<String, dynamic> json) {
    final ownerUserId = _asInt(json['ownerUserId']);
    final eventId = _asString(json['eventId']);
    final novelId = _asInt(json['novelId']);
    final chapterId = _asInt(json['chapterId']);
    final readAt = DateTime.tryParse(_asString(json['readAt']));
    if (ownerUserId <= 0 ||
        eventId.isEmpty ||
        novelId <= 0 ||
        chapterId <= 0 ||
        readAt == null) {
      throw const FormatException('Invalid persisted reading activity event.');
    }
    return ReadingActivityEvent(
      ownerUserId: ownerUserId,
      eventId: eventId,
      novelId: novelId,
      chapterId: chapterId,
      activeSeconds: _asInt(json['activeSeconds']),
      openSeconds: _asInt(json['openSeconds']),
      progress: _asInt(json['progress']),
      completed: json['completed'] == true,
      views: _asInt(json['views']),
      readAt: readAt.toUtc(),
    );
  }

  final int ownerUserId;
  final String eventId;
  final int novelId;
  final int chapterId;
  final int activeSeconds;
  final int openSeconds;
  final int progress;
  final bool completed;
  final int views;
  final DateTime readAt;

  Map<String, Object?> toStorageJson() {
    return {
      'ownerUserId': ownerUserId,
      'eventId': eventId,
      'novelId': novelId,
      'chapterId': chapterId,
      'activeSeconds': activeSeconds,
      'openSeconds': openSeconds,
      'progress': progress,
      'completed': completed,
      'views': views,
      'readAt': readAt.toUtc().toIso8601String(),
    };
  }

  Map<String, Object?> toRequestJson() {
    return {
      'event_id': eventId,
      'object_type': 'chapter',
      'object_id': chapterId,
      'parent_id': novelId,
      'reading_seconds': activeSeconds.clamp(0, 300),
      'open_seconds': openSeconds.clamp(0, 900),
      'progress': progress.clamp(0, 100),
      'completed': completed,
      'views': views.clamp(0, 1),
      'read_at': readAt.toUtc().toIso8601String(),
    };
  }
}

String _asString(Object? value) => value?.toString().trim() ?? '';

int _asInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
