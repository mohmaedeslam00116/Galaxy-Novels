import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../application/app_update_policy_repository.dart';
import '../domain/app_update_policy.dart';

abstract interface class AppUpdatePolicyCache {
  Future<String?> read();

  Future<void> write(String encodedPolicy);
}

abstract interface class AppUpdatePolicyRemoteSource {
  Future<Map<String, Object?>> fetch();

  Stream<Map<String, Object?>> get updates;
}

class StoredAppUpdatePolicyRepository extends ChangeNotifier
    implements AppUpdatePolicyRepository {
  StoredAppUpdatePolicyRepository({
    required AppUpdatePolicyCache cache,
    required AppUpdatePolicyRemoteSource remote,
  }) : _cache = cache,
       _remote = remote;

  final AppUpdatePolicyCache _cache;
  final AppUpdatePolicyRemoteSource _remote;
  AppUpdatePolicy _value = AppUpdatePolicy.defaults;
  StreamSubscription<Map<String, Object?>>? _updateSubscription;
  bool _hasTrustedPolicy = false;
  bool _didLoad = false;

  @override
  AppUpdatePolicy get value => _value;

  @override
  bool get hasTrustedPolicy => _hasTrustedPolicy;

  @override
  Future<void> loadCached() async {
    if (_didLoad) return;
    _didLoad = true;
    final encoded = await _cache.read();
    if (encoded == null || encoded.isEmpty) return;
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! Map) return;
      final policy = AppUpdatePolicy.tryFromMap(
        decoded.map((key, value) => MapEntry(key.toString(), value)),
      );
      if (policy == null) return;
      _publish(policy);
    } on FormatException {
      return;
    }
  }

  @override
  Future<void> refresh() async {
    final values = await _remote.fetch();
    final policy = AppUpdatePolicy.tryFromMap(values);
    if (policy == null) {
      throw const FormatException('Invalid app update policy.');
    }
    await _saveAndPublish(policy);
  }

  @override
  void startRealtimeUpdates() {
    _updateSubscription ??= _remote.updates.listen(
      (values) {
        final policy = AppUpdatePolicy.tryFromMap(values);
        if (policy != null) unawaited(_saveAndPublish(policy));
      },
      onError: (Object _, StackTrace _) {
        // The last trusted policy remains active until Firebase reconnects.
      },
    );
  }

  Future<void> _saveAndPublish(AppUpdatePolicy policy) async {
    await _cache.write(jsonEncode(policy.toJson()));
    _publish(policy);
  }

  void _publish(AppUpdatePolicy policy) {
    final changed = policy != _value || !_hasTrustedPolicy;
    _value = policy;
    _hasTrustedPolicy = true;
    if (changed) notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_updateSubscription?.cancel());
    super.dispose();
  }
}
