import 'package:firebase_remote_config/firebase_remote_config.dart';

import '../domain/reader_interstitial_policy.dart';
import 'stored_reader_interstitial_policy_repository.dart';

class FirebaseReaderInterstitialPolicyRemoteSource
    implements ReaderInterstitialPolicyRemoteSource {
  FirebaseReaderInterstitialPolicyRemoteSource({
    FirebaseRemoteConfig? remoteConfig,
    this.fetchTimeout = const Duration(seconds: 4),
    this.minimumFetchInterval = const Duration(hours: 1),
  }) : _remoteConfig = remoteConfig ?? FirebaseRemoteConfig.instance;

  final FirebaseRemoteConfig _remoteConfig;
  final Duration fetchTimeout;
  final Duration minimumFetchInterval;
  Future<void>? _initialization;

  Future<void> _initialize() {
    return _initialization ??= _configure();
  }

  Future<void> _configure() async {
    await _remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: fetchTimeout,
        minimumFetchInterval: minimumFetchInterval,
      ),
    );
    await _remoteConfig.setDefaults(ReaderInterstitialPolicy.defaults.toJson());
    await _remoteConfig.ensureInitialized();
  }

  @override
  Future<Map<String, Object?>> fetch() async {
    await _initialize();
    await _remoteConfig.fetchAndActivate();
    return _snapshot();
  }

  @override
  Stream<Map<String, Object?>> get updates async* {
    await _initialize();
    await for (final _ in _remoteConfig.onConfigUpdated) {
      await _remoteConfig.activate();
      yield _snapshot();
    }
  }

  Map<String, Object?> _snapshot() => {
    ReaderInterstitialPolicy.enabledKey: _remoteConfig.getBool(
      ReaderInterstitialPolicy.enabledKey,
    ),
    ReaderInterstitialPolicy.minimumChaptersKey: _remoteConfig.getInt(
      ReaderInterstitialPolicy.minimumChaptersKey,
    ),
    ReaderInterstitialPolicy.maximumChaptersKey: _remoteConfig.getInt(
      ReaderInterstitialPolicy.maximumChaptersKey,
    ),
  };
}
