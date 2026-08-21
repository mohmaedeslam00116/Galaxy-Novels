import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../application/app_review_policy_repository.dart';
import '../domain/app_review_policy.dart';

abstract interface class AppReviewPolicyCache {
  Future<String?> read();

  Future<void> write(String encodedPolicy);
}

abstract interface class AppReviewPolicyRemoteSource {
  Future<Map<String, Object?>> fetch();

  Stream<Map<String, Object?>> get updates;
}

class StoredAppReviewPolicyRepository extends ChangeNotifier
    implements AppReviewPolicyRepository {
  StoredAppReviewPolicyRepository({
    required AppReviewPolicyCache cache,
    required AppReviewPolicyRemoteSource remote,
  }) : _cache = cache,
       _remote = remote;

  final AppReviewPolicyCache _cache;
  final AppReviewPolicyRemoteSource _remote;
  AppReviewPolicy _value = AppReviewPolicy.defaults;
  StreamSubscription<Map<String, Object?>>? _subscription;
  bool _didLoad = false;

  @override
  AppReviewPolicy get value => _value;

  @override
  Future<void> loadCached() async {
    if (_didLoad) return;
    _didLoad = true;
    final encoded = await _cache.read();
    if (encoded == null || encoded.isEmpty) return;
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! Map) return;
      final policy = AppReviewPolicy.tryFromMap(
        decoded.map((key, value) => MapEntry(key.toString(), value)),
      );
      if (policy != null) _publish(policy);
    } on FormatException {
      // Safe defaults remain active when the cache is corrupt.
    }
  }

  @override
  Future<void> refresh() async {
    final policy = AppReviewPolicy.tryFromMap(await _remote.fetch());
    if (policy == null) {
      throw const FormatException('Invalid app review policy.');
    }
    await _saveAndPublish(policy);
  }

  @override
  void startRealtimeUpdates() {
    _subscription ??= _remote.updates.listen(
      (values) {
        final policy = AppReviewPolicy.tryFromMap(values);
        if (policy != null) unawaited(_saveAndPublish(policy));
      },
      onError: (Object _, StackTrace _) {
        // Keep the last trusted local policy while Firebase reconnects.
      },
    );
  }

  Future<void> _saveAndPublish(AppReviewPolicy policy) async {
    await _cache.write(jsonEncode(policy.toJson()));
    _publish(policy);
  }

  void _publish(AppReviewPolicy policy) {
    if (_value == policy) return;
    _value = policy;
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
