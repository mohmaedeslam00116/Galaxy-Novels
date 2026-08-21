class AppUpdateSnooze {
  const AppUpdateSnooze({required this.versionCode, required this.until});

  final int versionCode;
  final DateTime until;

  bool isActiveAt(DateTime instant) => instant.isBefore(until);

  Map<String, Object> toJson() => {
    'version_code': versionCode,
    'until': until.toUtc().toIso8601String(),
  };

  static AppUpdateSnooze? tryFromMap(Map<String, Object?> values) {
    final versionCode = values['version_code'];
    final until = DateTime.tryParse(values['until']?.toString() ?? '');
    if (versionCode is! int || versionCode < 1 || until == null) return null;
    return AppUpdateSnooze(versionCode: versionCode, until: until.toUtc());
  }
}

abstract interface class AppUpdateSnoozeStore {
  Future<AppUpdateSnooze?> read();

  Future<void> write(AppUpdateSnooze snooze);

  Future<void> clear();
}

class MemoryAppUpdateSnoozeStore implements AppUpdateSnoozeStore {
  AppUpdateSnooze? _value;

  @override
  Future<void> clear() async => _value = null;

  @override
  Future<AppUpdateSnooze?> read() async => _value;

  @override
  Future<void> write(AppUpdateSnooze snooze) async => _value = snooze;
}
