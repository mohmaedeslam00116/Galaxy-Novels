import 'dart:async';

import 'package:firebase_remote_config/firebase_remote_config.dart';

import '../domain/app_update_policy.dart';
import 'stored_app_update_policy_repository.dart';

class FirebaseAppUpdatePolicyRemoteSource
    implements AppUpdatePolicyRemoteSource {
  FirebaseAppUpdatePolicyRemoteSource({
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
    await _remoteConfig.setDefaults(AppUpdatePolicy.defaults.toJson());
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
    AppUpdatePolicy.systemEnabledKey: _remoteConfig.getBool(
      AppUpdatePolicy.systemEnabledKey,
    ),
    AppUpdatePolicy.optionalUpdateEnabledKey: _remoteConfig.getBool(
      AppUpdatePolicy.optionalUpdateEnabledKey,
    ),
    AppUpdatePolicy.minimumSupportedBuildKey: _remoteConfig.getInt(
      AppUpdatePolicy.minimumSupportedBuildKey,
    ),
    AppUpdatePolicy.optionalTitleKey: _remoteConfig.getString(
      AppUpdatePolicy.optionalTitleKey,
    ),
    AppUpdatePolicy.optionalMessageKey: _remoteConfig.getString(
      AppUpdatePolicy.optionalMessageKey,
    ),
    AppUpdatePolicy.requiredTitleKey: _remoteConfig.getString(
      AppUpdatePolicy.requiredTitleKey,
    ),
    AppUpdatePolicy.requiredMessageKey: _remoteConfig.getString(
      AppUpdatePolicy.requiredMessageKey,
    ),
  };
}
