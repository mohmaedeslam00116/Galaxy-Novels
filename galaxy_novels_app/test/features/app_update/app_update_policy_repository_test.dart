import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/features/app_update/data/stored_app_update_policy_repository.dart';
import 'package:galaxy_novels_app/features/app_update/domain/app_update_policy.dart';

void main() {
  test('loads the last valid policy as trusted', () async {
    final expected = AppUpdatePolicy.defaults.copyWith(
      minimumSupportedBuild: 7,
    );
    final repository = StoredAppUpdatePolicyRepository(
      cache: _MemoryPolicyCache(jsonEncode(expected.toJson())),
      remote: _FakeRemotePolicySource(),
    );

    await repository.loadCached();

    expect(repository.value, expected);
    expect(repository.hasTrustedPolicy, isTrue);
  });

  test('invalid remote policy keeps the cached trusted policy', () async {
    final expected = AppUpdatePolicy.defaults.copyWith(
      minimumSupportedBuild: 4,
    );
    final repository = StoredAppUpdatePolicyRepository(
      cache: _MemoryPolicyCache(jsonEncode(expected.toJson())),
      remote: _FakeRemotePolicySource(
        fetched: {
          ...AppUpdatePolicy.defaults.toJson(),
          AppUpdatePolicy.minimumSupportedBuildKey: -2,
        },
      ),
    );
    await repository.loadCached();

    await expectLater(repository.refresh(), throwsFormatException);

    expect(repository.value, expected);
    expect(repository.hasTrustedPolicy, isTrue);
  });

  test(
    'valid remote policy is published, cached, and updated in real time',
    () async {
      final updates = StreamController<Map<String, Object?>>();
      addTearDown(updates.close);
      final cache = _MemoryPolicyCache(null);
      final fetched = AppUpdatePolicy.defaults.copyWith(
        minimumSupportedBuild: 5,
      );
      final repository = StoredAppUpdatePolicyRepository(
        cache: cache,
        remote: _FakeRemotePolicySource(
          fetched: fetched.toJson(),
          updates: updates.stream,
        ),
      );

      await repository.refresh();
      expect(repository.value, fetched);
      expect(repository.hasTrustedPolicy, isTrue);

      repository.startRealtimeUpdates();
      final realtime = fetched.copyWith(minimumSupportedBuild: 6);
      updates.add(realtime.toJson());
      await Future<void>.delayed(Duration.zero);

      expect(repository.value, realtime);
      expect(
        AppUpdatePolicy.tryFromMap(
          (jsonDecode(cache.value!) as Map).map(
            (key, value) => MapEntry(key.toString(), value),
          ),
        ),
        realtime,
      );
    },
  );
}

class _MemoryPolicyCache implements AppUpdatePolicyCache {
  _MemoryPolicyCache(this.value);

  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String encodedPolicy) async => value = encodedPolicy;
}

class _FakeRemotePolicySource implements AppUpdatePolicyRemoteSource {
  _FakeRemotePolicySource({
    Map<String, Object?>? fetched,
    this.updates = const Stream.empty(),
  }) : fetched = fetched ?? AppUpdatePolicy.defaults.toJson();

  final Map<String, Object?> fetched;
  @override
  final Stream<Map<String, Object?>> updates;

  @override
  Future<Map<String, Object?>> fetch() async => fetched;
}
