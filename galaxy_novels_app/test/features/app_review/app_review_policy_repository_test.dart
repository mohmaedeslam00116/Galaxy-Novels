import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/features/app_review/data/stored_app_review_policy_repository.dart';
import 'package:galaxy_novels_app/features/app_review/domain/app_review_policy.dart';

void main() {
  test('keeps the cached policy when remote values are invalid', () async {
    final cached = AppReviewPolicy.defaults.copyWith(minimumDays: 7);
    final repository = StoredAppReviewPolicyRepository(
      cache: _MemoryCache(jsonEncode(cached.toJson())),
      remote: _FakeRemote({
        ...AppReviewPolicy.defaults.toJson(),
        AppReviewPolicy.minimumSessionsKey: -1,
      }),
    );

    await repository.loadCached();
    await expectLater(repository.refresh(), throwsFormatException);

    expect(repository.value, cached);
  });

  test('publishes and caches valid realtime policies', () async {
    final updates = StreamController<Map<String, Object?>>();
    addTearDown(updates.close);
    final cache = _MemoryCache(null);
    final repository = StoredAppReviewPolicyRepository(
      cache: cache,
      remote: _FakeRemote(
        AppReviewPolicy.defaults.toJson(),
        updates: updates.stream,
      ),
    );
    repository.startRealtimeUpdates();
    final updated = AppReviewPolicy.defaults.copyWith(maximumAttempts: 2);

    updates.add(updated.toJson());
    await Future<void>.delayed(Duration.zero);

    expect(repository.value, updated);
    expect(
      AppReviewPolicy.tryFromMap(
        (jsonDecode(cache.value!) as Map).map(
          (key, value) => MapEntry(key.toString(), value),
        ),
      ),
      updated,
    );
  });
}

class _MemoryCache implements AppReviewPolicyCache {
  _MemoryCache(this.value);
  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String encodedPolicy) async => value = encodedPolicy;
}

class _FakeRemote implements AppReviewPolicyRemoteSource {
  _FakeRemote(this.fetched, {this.updates = const Stream.empty()});

  final Map<String, Object?> fetched;
  @override
  final Stream<Map<String, Object?>> updates;

  @override
  Future<Map<String, Object?>> fetch() async => fetched;
}
