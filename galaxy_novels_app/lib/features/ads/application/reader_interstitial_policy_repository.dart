import 'package:flutter/foundation.dart';

import '../domain/reader_interstitial_policy.dart';

abstract interface class ReaderInterstitialPolicyRepository
    implements Listenable {
  ReaderInterstitialPolicy get value;

  bool get hasTrustedPolicy;

  Future<void> loadCached();

  Future<void> refresh();

  void startRealtimeUpdates();

  void dispose();
}

class NoopReaderInterstitialPolicyRepository extends ChangeNotifier
    implements ReaderInterstitialPolicyRepository {
  NoopReaderInterstitialPolicyRepository({
    this.policy = ReaderInterstitialPolicy.defaults,
  });

  final ReaderInterstitialPolicy policy;

  @override
  ReaderInterstitialPolicy get value => policy;

  @override
  bool get hasTrustedPolicy => false;

  @override
  Future<void> loadCached() async {}

  @override
  Future<void> refresh() async {}

  @override
  void startRealtimeUpdates() {}
}
