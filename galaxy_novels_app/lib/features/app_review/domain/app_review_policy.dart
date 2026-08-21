class AppReviewPolicy {
  const AppReviewPolicy({
    required this.enabled,
    required this.minimumDays,
    required this.minimumCompletedChapters,
    required this.minimumSessions,
    required this.cooldownDays,
    required this.maximumAttempts,
  });

  static const enabledKey = 'android_in_app_review_enabled';
  static const minimumDaysKey = 'android_in_app_review_min_days';
  static const minimumCompletedChaptersKey =
      'android_in_app_review_min_completed_chapters';
  static const minimumSessionsKey = 'android_in_app_review_min_sessions';
  static const cooldownDaysKey = 'android_in_app_review_cooldown_days';
  static const maximumAttemptsKey = 'android_in_app_review_max_attempts';

  static const defaults = AppReviewPolicy(
    enabled: true,
    minimumDays: 3,
    minimumCompletedChapters: 10,
    minimumSessions: 2,
    cooldownDays: 120,
    maximumAttempts: 3,
  );

  final bool enabled;
  final int minimumDays;
  final int minimumCompletedChapters;
  final int minimumSessions;
  final int cooldownDays;
  final int maximumAttempts;

  AppReviewPolicy copyWith({
    bool? enabled,
    int? minimumDays,
    int? minimumCompletedChapters,
    int? minimumSessions,
    int? cooldownDays,
    int? maximumAttempts,
  }) {
    return AppReviewPolicy(
      enabled: enabled ?? this.enabled,
      minimumDays: minimumDays ?? this.minimumDays,
      minimumCompletedChapters:
          minimumCompletedChapters ?? this.minimumCompletedChapters,
      minimumSessions: minimumSessions ?? this.minimumSessions,
      cooldownDays: cooldownDays ?? this.cooldownDays,
      maximumAttempts: maximumAttempts ?? this.maximumAttempts,
    );
  }

  Map<String, Object> toJson() => {
    enabledKey: enabled,
    minimumDaysKey: minimumDays,
    minimumCompletedChaptersKey: minimumCompletedChapters,
    minimumSessionsKey: minimumSessions,
    cooldownDaysKey: cooldownDays,
    maximumAttemptsKey: maximumAttempts,
  };

  static AppReviewPolicy? tryFromMap(Map<String, Object?> values) {
    final enabled = values[enabledKey];
    final minimumDays = values[minimumDaysKey];
    final minimumChapters = values[minimumCompletedChaptersKey];
    final minimumSessions = values[minimumSessionsKey];
    final cooldownDays = values[cooldownDaysKey];
    final maximumAttempts = values[maximumAttemptsKey];
    if (enabled is! bool ||
        minimumDays is! int ||
        minimumDays < 0 ||
        minimumDays > 365 ||
        minimumChapters is! int ||
        minimumChapters < 1 ||
        minimumChapters > 1000 ||
        minimumSessions is! int ||
        minimumSessions < 1 ||
        minimumSessions > 100 ||
        cooldownDays is! int ||
        cooldownDays < 1 ||
        cooldownDays > 730 ||
        maximumAttempts is! int ||
        maximumAttempts < 1 ||
        maximumAttempts > 10) {
      return null;
    }
    return AppReviewPolicy(
      enabled: enabled,
      minimumDays: minimumDays,
      minimumCompletedChapters: minimumChapters,
      minimumSessions: minimumSessions,
      cooldownDays: cooldownDays,
      maximumAttempts: maximumAttempts,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AppReviewPolicy &&
        other.enabled == enabled &&
        other.minimumDays == minimumDays &&
        other.minimumCompletedChapters == minimumCompletedChapters &&
        other.minimumSessions == minimumSessions &&
        other.cooldownDays == cooldownDays &&
        other.maximumAttempts == maximumAttempts;
  }

  @override
  int get hashCode => Object.hash(
    enabled,
    minimumDays,
    minimumCompletedChapters,
    minimumSessions,
    cooldownDays,
    maximumAttempts,
  );
}
