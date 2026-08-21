class AppUpdatePolicy {
  const AppUpdatePolicy({
    required this.systemEnabled,
    required this.optionalUpdateEnabled,
    required this.minimumSupportedBuild,
    required this.optionalTitle,
    required this.optionalMessage,
    required this.requiredTitle,
    required this.requiredMessage,
  });

  static const systemEnabledKey = 'android_update_system_enabled';
  static const optionalUpdateEnabledKey = 'android_optional_update_enabled';
  static const minimumSupportedBuildKey = 'android_min_supported_build';
  static const optionalTitleKey = 'android_optional_update_title_ar';
  static const optionalMessageKey = 'android_optional_update_message_ar';
  static const requiredTitleKey = 'android_required_update_title_ar';
  static const requiredMessageKey = 'android_required_update_message_ar';

  static const defaults = AppUpdatePolicy(
    systemEnabled: true,
    optionalUpdateEnabled: true,
    minimumSupportedBuild: 0,
    optionalTitle: 'تحديث جديد متاح',
    optionalMessage: 'حدّث التطبيق للحصول على أحدث التحسينات والإصلاحات.',
    requiredTitle: 'يلزم تحديث التطبيق',
    requiredMessage:
        'هذا الإصدار لم يعد مدعومًا. حدّث التطبيق لمتابعة استخدامه.',
  );

  final bool systemEnabled;
  final bool optionalUpdateEnabled;
  final int minimumSupportedBuild;
  final String optionalTitle;
  final String optionalMessage;
  final String requiredTitle;
  final String requiredMessage;

  bool requiresUpdate(int? currentBuild) {
    return systemEnabled &&
        currentBuild != null &&
        currentBuild < minimumSupportedBuild;
  }

  AppUpdatePolicy copyWith({
    bool? systemEnabled,
    bool? optionalUpdateEnabled,
    int? minimumSupportedBuild,
    String? optionalTitle,
    String? optionalMessage,
    String? requiredTitle,
    String? requiredMessage,
  }) {
    return AppUpdatePolicy(
      systemEnabled: systemEnabled ?? this.systemEnabled,
      optionalUpdateEnabled:
          optionalUpdateEnabled ?? this.optionalUpdateEnabled,
      minimumSupportedBuild:
          minimumSupportedBuild ?? this.minimumSupportedBuild,
      optionalTitle: optionalTitle ?? this.optionalTitle,
      optionalMessage: optionalMessage ?? this.optionalMessage,
      requiredTitle: requiredTitle ?? this.requiredTitle,
      requiredMessage: requiredMessage ?? this.requiredMessage,
    );
  }

  Map<String, Object> toJson() => {
    systemEnabledKey: systemEnabled,
    optionalUpdateEnabledKey: optionalUpdateEnabled,
    minimumSupportedBuildKey: minimumSupportedBuild,
    optionalTitleKey: optionalTitle,
    optionalMessageKey: optionalMessage,
    requiredTitleKey: requiredTitle,
    requiredMessageKey: requiredMessage,
  };

  static AppUpdatePolicy? tryFromMap(Map<String, Object?> values) {
    final systemEnabled = values[systemEnabledKey];
    final optionalEnabled = values[optionalUpdateEnabledKey];
    final minimumBuild = values[minimumSupportedBuildKey];
    final optionalTitle = _nonEmptyString(values[optionalTitleKey]);
    final optionalMessage = _nonEmptyString(values[optionalMessageKey]);
    final requiredTitle = _nonEmptyString(values[requiredTitleKey]);
    final requiredMessage = _nonEmptyString(values[requiredMessageKey]);
    if (systemEnabled is! bool ||
        optionalEnabled is! bool ||
        minimumBuild is! int ||
        minimumBuild < 0 ||
        optionalTitle == null ||
        optionalMessage == null ||
        requiredTitle == null ||
        requiredMessage == null) {
      return null;
    }
    return AppUpdatePolicy(
      systemEnabled: systemEnabled,
      optionalUpdateEnabled: optionalEnabled,
      minimumSupportedBuild: minimumBuild,
      optionalTitle: optionalTitle,
      optionalMessage: optionalMessage,
      requiredTitle: requiredTitle,
      requiredMessage: requiredMessage,
    );
  }

  static String? _nonEmptyString(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  bool operator ==(Object other) {
    return other is AppUpdatePolicy &&
        other.systemEnabled == systemEnabled &&
        other.optionalUpdateEnabled == optionalUpdateEnabled &&
        other.minimumSupportedBuild == minimumSupportedBuild &&
        other.optionalTitle == optionalTitle &&
        other.optionalMessage == optionalMessage &&
        other.requiredTitle == requiredTitle &&
        other.requiredMessage == requiredMessage;
  }

  @override
  int get hashCode => Object.hash(
    systemEnabled,
    optionalUpdateEnabled,
    minimumSupportedBuild,
    optionalTitle,
    optionalMessage,
    requiredTitle,
    requiredMessage,
  );
}
