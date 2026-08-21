import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../application/reader_interstitial_policy_repository.dart';
import '../domain/reader_interstitial_policy.dart';

abstract interface class ReaderInterstitialPolicyCache {
  Future<String?> read();

  Future<void> write(String encodedPolicy);
}

abstract interface class ReaderInterstitialPolicyRemoteSource {
  Future<Map<String, Object?>> fetch();

  Stream<Map<String, Object?>> get updates;
}

class StoredReaderInterstitialPolicyRepository extends ChangeNotifier
    implements ReaderInterstitialPolicyRepository {
  StoredReaderInterstitialPolicyRepository({
    required ReaderInterstitialPolicyCache cache,
    required ReaderInterstitialPolicyRemoteSource remote,
  }) : _cache = cache,
       _remote = remote;

  final ReaderInterstitialPolicyCache _cache;
  final ReaderInterstitialPolicyRemoteSource _remote;
  ReaderInterstitialPolicy _value = ReaderInterstitialPolicy.defaults;
  StreamSubscription<Map<String, Object?>>? _updatesSubscription;
  bool _hasTrustedPolicy = false;
  bool _didLoad = false;

  @override
  ReaderInterstitialPolicy get value => _value;

  @override
  bool get hasTrustedPolicy => _hasTrustedPolicy;

  @override
  Future<void> loadCached() async {
    if (_didLoad) return;
    _didLoad = true;
    final encoded = await _cache.read();
    if (encoded == null || encoded.trim().isEmpty) return;
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! Map) return;
      final policy = ReaderInterstitialPolicy.tryFromMap(
        decoded.map((key, value) => MapEntry(key.toString(), value)),
      );
      if (policy != null) _publish(policy);
    } on FormatException {
      return;
    }
  }

  @override
  Future<void> refresh() async {
    final values = await _remote.fetch();
    final policy = ReaderInterstitialPolicy.tryFromMap(values);
    if (policy == null) {
      throw const FormatException('Invalid reader interstitial policy.');
    }
    await _saveAndPublish(policy);
  }

  @override
  void startRealtimeUpdates() {
    _updatesSubscription ??= _remote.updates.listen(
      (values) {
        final policy = ReaderInterstitialPolicy.tryFromMap(values);
        if (policy != null) unawaited(_saveAndPublish(policy));
      },
      onError: (Object _, StackTrace _) {
        // Keep the last trusted policy while Firebase reconnects.
      },
    );
  }

  Future<void> _saveAndPublish(ReaderInterstitialPolicy policy) async {
    await _cache.write(jsonEncode(policy.toJson()));
    _publish(policy);
  }

  void _publish(ReaderInterstitialPolicy policy) {
    final changed = policy != _value || !_hasTrustedPolicy;
    _value = policy;
    _hasTrustedPolicy = true;
    if (changed) notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_updatesSubscription?.cancel());
    super.dispose();
  }
}
