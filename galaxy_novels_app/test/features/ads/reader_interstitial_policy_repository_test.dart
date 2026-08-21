import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/features/ads/data/stored_reader_interstitial_policy_repository.dart';
import 'package:galaxy_novels_app/features/ads/domain/reader_interstitial_policy.dart';

void main() {
  test('loads the last valid cached reader ad policy', () async {
    final cached = ReaderInterstitialPolicy.defaults.copyWith(
      minimumChapters: 8,
      maximumChapters: 24,
    );
    final repository = StoredReaderInterstitialPolicyRepository(
      cache: _MemoryCache(jsonEncode(cached.toJson())),
      remote: _FakeRemote(),
    );

    await repository.loadCached();

    expect(repository.value, cached);
    expect(repository.hasTrustedPolicy, isTrue);
    repository.dispose();
  });

  test('invalid remote values preserve the last valid policy', () async {
    final cached = ReaderInterstitialPolicy.defaults.copyWith(
      minimumChapters: 10,
      maximumChapters: 25,
    );
    final repository = StoredReaderInterstitialPolicyRepository(
      cache: _MemoryCache(jsonEncode(cached.toJson())),
      remote: _FakeRemote(
        fetched: {
          ReaderInterstitialPolicy.enabledKey: true,
          ReaderInterstitialPolicy.minimumChaptersKey: 4,
          ReaderInterstitialPolicy.maximumChaptersKey: 20,
        },
      ),
    );
    await repository.loadCached();

    await expectLater(repository.refresh(), throwsFormatException);

    expect(repository.value, cached);
    repository.dispose();
  });

  test('publishes and caches valid realtime policy updates', () async {
    final cache = _MemoryCache();
    final remote = _FakeRemote();
    final repository = StoredReaderInterstitialPolicyRepository(
      cache: cache,
      remote: remote,
    );
    repository.startRealtimeUpdates();
    final updated = ReaderInterstitialPolicy.defaults.copyWith(enabled: false);

    remote.updatesController.add(updated.toJson());
    await Future<void>.delayed(Duration.zero);

    expect(repository.value, updated);
    expect(
      ReaderInterstitialPolicy.tryFromMap(
        (jsonDecode(cache.value!) as Map).map(
          (key, value) => MapEntry(key.toString(), value),
        ),
      ),
      updated,
    );
    repository.dispose();
  });
}

class _MemoryCache implements ReaderInterstitialPolicyCache {
  _MemoryCache([this.value]);

  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String encodedPolicy) async {
    value = encodedPolicy;
  }
}

class _FakeRemote implements ReaderInterstitialPolicyRemoteSource {
  _FakeRemote({Map<String, Object?>? fetched})
    : fetched = fetched ?? ReaderInterstitialPolicy.defaults.toJson();

  final Map<String, Object?> fetched;
  final updatesController = StreamController<Map<String, Object?>>();

  @override
  Future<Map<String, Object?>> fetch() async => fetched;

  @override
  Stream<Map<String, Object?>> get updates => updatesController.stream;
}
