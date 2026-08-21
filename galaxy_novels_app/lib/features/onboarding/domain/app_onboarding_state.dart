enum AppOnboardingCompletionMethod { completed, skipped }

class AppOnboardingState {
  const AppOnboardingState({
    required this.completedVersion,
    required this.completedAt,
    required this.completionMethod,
  });

  const AppOnboardingState.pending()
    : completedVersion = 0,
      completedAt = null,
      completionMethod = null;

  factory AppOnboardingState.completed({
    required DateTime completedAt,
    required AppOnboardingCompletionMethod method,
  }) => AppOnboardingState(
    completedVersion: currentVersion,
    completedAt: completedAt.toUtc(),
    completionMethod: method,
  );

  static const currentVersion = 1;

  final int completedVersion;
  final DateTime? completedAt;
  final AppOnboardingCompletionMethod? completionMethod;

  bool get isCurrentVersionComplete => completedVersion >= currentVersion;

  Map<String, Object?> toJson() => {
    'completed_version': completedVersion,
    'completed_at': completedAt?.toUtc().toIso8601String(),
    'completion_method': completionMethod?.name,
  };

  static AppOnboardingState? tryFromMap(Map<String, Object?> map) {
    final version = map['completed_version'];
    final timestamp = map['completed_at'];
    final methodName = map['completion_method'];
    if (version is! int || version < 0) return null;

    final completedAt = timestamp is String
        ? DateTime.tryParse(timestamp)?.toUtc()
        : null;
    final method = methodName is String
        ? AppOnboardingCompletionMethod.values
              .where((value) => value.name == methodName)
              .firstOrNull
        : null;
    if (version > 0 && (completedAt == null || method == null)) return null;
    if (timestamp != null && completedAt == null) return null;
    if (methodName != null && method == null) return null;

    return AppOnboardingState(
      completedVersion: version,
      completedAt: completedAt,
      completionMethod: method,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppOnboardingState &&
          other.completedVersion == completedVersion &&
          other.completedAt == completedAt &&
          other.completionMethod == completionMethod;

  @override
  int get hashCode =>
      Object.hash(completedVersion, completedAt, completionMethod);
}
