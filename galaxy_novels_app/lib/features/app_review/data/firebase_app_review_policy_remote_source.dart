import 'package:firebase_remote_config/firebase_remote_config.dart';

import '../domain/app_review_policy.dart';
import 'stored_app_review_policy_repository.dart';

class FirebaseAppReviewPolicyRemoteSource
    implements AppReviewPolicyRemoteSource {
  FirebaseAppReviewPolicyRemoteSource({
    FirebaseRemoteConfig? remoteConfig,
    this.fetchTimeout = const Duration(seconds: 4),
    this.minimumFetchInterval = const Duration(hours: 1),
  }) : _remoteConfig = remoteConfig ?? FirebaseRemoteConfig.instance;

  final FirebaseRemoteConfig _remoteConfig;
  final Duration fetchTimeout;
  final Duration minimumFetchInterval;
  Future<void>? _initialization;

  Future<void> _initialize() => _initialization ??= _configure();

  Future<void> _configure() async {
    await _remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: fetchTimeout,
        minimumFetchInterval: minimumFetchInterval,
      ),
    );
    await _remoteConfig.setDefaults(AppReviewPolicy.defaults.toJson());
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
    AppReviewPolicy.enabledKey: _remoteConfig.getBool(
      AppReviewPolicy.enabledKey,
    ),
    AppReviewPolicy.minimumDaysKey: _remoteConfig.getInt(
      AppReviewPolicy.minimumDaysKey,
    ),
    AppReviewPolicy.minimumCompletedChaptersKey: _remoteConfig.getInt(
      AppReviewPolicy.minimumCompletedChaptersKey,
    ),
    AppReviewPolicy.minimumSessionsKey: _remoteConfig.getInt(
      AppReviewPolicy.minimumSessionsKey,
    ),
    AppReviewPolicy.cooldownDaysKey: _remoteConfig.getInt(
      AppReviewPolicy.cooldownDaysKey,
    ),
    AppReviewPolicy.maximumAttemptsKey: _remoteConfig.getInt(
      AppReviewPolicy.maximumAttemptsKey,
    ),
  };
}
