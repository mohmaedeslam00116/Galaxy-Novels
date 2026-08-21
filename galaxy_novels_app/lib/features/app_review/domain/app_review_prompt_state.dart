class AppReviewPromptState {
  const AppReviewPromptState({
    required this.firstOpenedAt,
    required this.completedChapterCount,
    required this.qualifyingSessionCount,
    required this.lastAutomaticAttemptAt,
    required this.automaticAttemptCount,
    required this.lastUnavailableAt,
    required this.lastManualStoreOpenAt,
  });

  factory AppReviewPromptState.initial(DateTime now) => AppReviewPromptState(
    firstOpenedAt: now.toUtc(),
    completedChapterCount: 0,
    qualifyingSessionCount: 0,
    lastAutomaticAttemptAt: null,
    automaticAttemptCount: 0,
    lastUnavailableAt: null,
    lastManualStoreOpenAt: null,
  );

  final DateTime firstOpenedAt;
  final int completedChapterCount;
  final int qualifyingSessionCount;
  final DateTime? lastAutomaticAttemptAt;
  final int automaticAttemptCount;
  final DateTime? lastUnavailableAt;
  final DateTime? lastManualStoreOpenAt;

  AppReviewPromptState copyWith({
    DateTime? firstOpenedAt,
    int? completedChapterCount,
    int? qualifyingSessionCount,
    DateTime? lastAutomaticAttemptAt,
    bool clearLastAutomaticAttempt = false,
    int? automaticAttemptCount,
    DateTime? lastUnavailableAt,
    bool clearLastUnavailable = false,
    DateTime? lastManualStoreOpenAt,
    bool clearLastManualStoreOpen = false,
  }) {
    return AppReviewPromptState(
      firstOpenedAt: firstOpenedAt ?? this.firstOpenedAt,
      completedChapterCount:
          completedChapterCount ?? this.completedChapterCount,
      qualifyingSessionCount:
          qualifyingSessionCount ?? this.qualifyingSessionCount,
      lastAutomaticAttemptAt: clearLastAutomaticAttempt
          ? null
          : lastAutomaticAttemptAt ?? this.lastAutomaticAttemptAt,
      automaticAttemptCount:
          automaticAttemptCount ?? this.automaticAttemptCount,
      lastUnavailableAt: clearLastUnavailable
          ? null
          : lastUnavailableAt ?? this.lastUnavailableAt,
      lastManualStoreOpenAt: clearLastManualStoreOpen
          ? null
          : lastManualStoreOpenAt ?? this.lastManualStoreOpenAt,
    );
  }

  Map<String, Object?> toJson() => {
    'first_opened_at': firstOpenedAt.toUtc().toIso8601String(),
    'completed_chapter_count': completedChapterCount,
    'qualifying_session_count': qualifyingSessionCount,
    'last_automatic_attempt_at': lastAutomaticAttemptAt
        ?.toUtc()
        .toIso8601String(),
    'automatic_attempt_count': automaticAttemptCount,
    'last_unavailable_at': lastUnavailableAt?.toUtc().toIso8601String(),
    'last_manual_store_open_at': lastManualStoreOpenAt
        ?.toUtc()
        .toIso8601String(),
  };

  static AppReviewPromptState? tryFromMap(Map<String, Object?> values) {
    final firstOpenedAt = _date(values['first_opened_at']);
    final completedChapterCount = values['completed_chapter_count'];
    final qualifyingSessionCount = values['qualifying_session_count'];
    final automaticAttemptCount = values['automatic_attempt_count'];
    final lastAutomaticAttemptAt = _nullableDate(
      values['last_automatic_attempt_at'],
    );
    final lastUnavailableAt = _nullableDate(values['last_unavailable_at']);
    final lastManualStoreOpenAt = _nullableDate(
      values['last_manual_store_open_at'],
    );
    if (firstOpenedAt == null ||
        completedChapterCount is! int ||
        completedChapterCount < 0 ||
        qualifyingSessionCount is! int ||
        qualifyingSessionCount < 0 ||
        automaticAttemptCount is! int ||
        automaticAttemptCount < 0 ||
        lastAutomaticAttemptAt == _invalidDate ||
        lastUnavailableAt == _invalidDate ||
        lastManualStoreOpenAt == _invalidDate) {
      return null;
    }
    return AppReviewPromptState(
      firstOpenedAt: firstOpenedAt,
      completedChapterCount: completedChapterCount,
      qualifyingSessionCount: qualifyingSessionCount,
      lastAutomaticAttemptAt: lastAutomaticAttemptAt as DateTime?,
      automaticAttemptCount: automaticAttemptCount,
      lastUnavailableAt: lastUnavailableAt as DateTime?,
      lastManualStoreOpenAt: lastManualStoreOpenAt as DateTime?,
    );
  }

  static final Object _invalidDate = Object();

  static DateTime? _date(Object? value) {
    if (value is! String) return null;
    return DateTime.tryParse(value)?.toUtc();
  }

  static Object? _nullableDate(Object? value) {
    if (value == null) return null;
    return _date(value) ?? _invalidDate;
  }

  @override
  bool operator ==(Object other) {
    return other is AppReviewPromptState &&
        other.firstOpenedAt == firstOpenedAt &&
        other.completedChapterCount == completedChapterCount &&
        other.qualifyingSessionCount == qualifyingSessionCount &&
        other.lastAutomaticAttemptAt == lastAutomaticAttemptAt &&
        other.automaticAttemptCount == automaticAttemptCount &&
        other.lastUnavailableAt == lastUnavailableAt &&
        other.lastManualStoreOpenAt == lastManualStoreOpenAt;
  }

  @override
  int get hashCode => Object.hash(
    firstOpenedAt,
    completedChapterCount,
    qualifyingSessionCount,
    lastAutomaticAttemptAt,
    automaticAttemptCount,
    lastUnavailableAt,
    lastManualStoreOpenAt,
  );
}
