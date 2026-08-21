class ReaderInterstitialPolicy {
  const ReaderInterstitialPolicy({
    required this.enabled,
    required this.minimumChapters,
    required this.maximumChapters,
  });

  static const enabledKey = 'android_reader_interstitial_enabled';
  static const minimumChaptersKey = 'android_reader_interstitial_min_chapters';
  static const maximumChaptersKey = 'android_reader_interstitial_max_chapters';

  static const minimumAllowedChapters = 5;
  static const maximumAllowedChapters = 100;

  static const defaults = ReaderInterstitialPolicy(
    enabled: true,
    minimumChapters: 5,
    maximumChapters: 20,
  );

  final bool enabled;
  final int minimumChapters;
  final int maximumChapters;

  ReaderInterstitialPolicy copyWith({
    bool? enabled,
    int? minimumChapters,
    int? maximumChapters,
  }) {
    return ReaderInterstitialPolicy(
      enabled: enabled ?? this.enabled,
      minimumChapters: minimumChapters ?? this.minimumChapters,
      maximumChapters: maximumChapters ?? this.maximumChapters,
    );
  }

  Map<String, Object> toJson() => {
    enabledKey: enabled,
    minimumChaptersKey: minimumChapters,
    maximumChaptersKey: maximumChapters,
  };

  static ReaderInterstitialPolicy? tryFromMap(Map<String, Object?> values) {
    final enabled = _boolValue(values[enabledKey]);
    final minimum = _intValue(values[minimumChaptersKey]);
    final maximum = _intValue(values[maximumChaptersKey]);
    if (enabled == null || minimum == null || maximum == null) return null;
    if (minimum < minimumAllowedChapters ||
        maximum > maximumAllowedChapters ||
        minimum > maximum) {
      return null;
    }
    return ReaderInterstitialPolicy(
      enabled: enabled,
      minimumChapters: minimum,
      maximumChapters: maximum,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ReaderInterstitialPolicy &&
        other.enabled == enabled &&
        other.minimumChapters == minimumChapters &&
        other.maximumChapters == maximumChapters;
  }

  @override
  int get hashCode => Object.hash(enabled, minimumChapters, maximumChapters);
}

bool? _boolValue(Object? value) {
  if (value is bool) return value;
  return switch (value?.toString().trim().toLowerCase()) {
    'true' || '1' => true,
    'false' || '0' => false,
    _ => null,
  };
}

int? _intValue(Object? value) {
  return value is int ? value : int.tryParse(value?.toString() ?? '');
}
