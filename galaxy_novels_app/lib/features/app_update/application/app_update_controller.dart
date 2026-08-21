import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/analytics/app_analytics.dart';
import '../../about/application/app_version_info.dart';
import '../domain/app_update_state.dart';
import 'app_update_policy_repository.dart';
import 'app_update_snooze_store.dart';
import 'play_app_update_gateway.dart';

class AppUpdateController extends ChangeNotifier {
  AppUpdateController({
    required AppUpdatePolicyRepository policies,
    required PlayAppUpdateGateway play,
    required AppUpdateSnoozeStore snoozes,
    required AppVersionLoader versionLoader,
    required AppAnalytics analytics,
    this.initialPolicyTimeout = const Duration(seconds: 4),
  }) : _policies = policies,
       _play = play,
       _snoozes = snoozes,
       _versionLoader = versionLoader,
       _analytics = analytics;

  final AppUpdatePolicyRepository _policies;
  final PlayAppUpdateGateway _play;
  final AppUpdateSnoozeStore _snoozes;
  final AppVersionLoader _versionLoader;
  final AppAnalytics _analytics;
  final Duration initialPolicyTimeout;

  AppUpdateState _state = AppUpdateState.initial();
  AppUpdateSnooze? _snooze;
  PlayAppUpdateAvailability _availability = PlayAppUpdateAvailability.none;
  StreamSubscription<PlayAppUpdateInstallStatus>? _installSubscription;
  bool _initialized = false;

  AppUpdateState get state => _state;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    AppVersionInfo version;
    try {
      version = await _versionLoader();
    } on Exception {
      version = const AppVersionInfo(version: '', buildNumber: '');
    }
    await _policies.loadCached();
    _snooze = await _snoozes.read();
    _policies.addListener(_policyChanged);
    _policies.startRealtimeUpdates();
    _installSubscription = _play.installStatuses.listen(_installStatusChanged);
    final previousState = _state;
    _state = _buildState(
      currentVersion: version.version,
      currentBuild: int.tryParse(version.buildNumber),
      policyEvaluated: _policies.hasTrustedPolicy,
      operation: AppUpdateOperation.checking,
    );
    _trackPromptPresentation(previousState, _state);
    notifyListeners();

    await _refreshPolicy();
    await refreshPlayAvailability();
  }

  Future<void> refresh() async {
    await _refreshPolicy();
    await refreshPlayAvailability();
  }

  Future<void> refreshPlayAvailability() async {
    try {
      _availability = await _play.checkForUpdate();
      await _removeExpiredSnooze();
      _replaceState(
        operation: _operationForStatus(_availability.installStatus),
      );
    } on Exception {
      _log('app_update_check_failed');
      _replaceState(operation: AppUpdateOperation.idle);
    }
  }

  Future<void> snoozeOptionalUpdate() async {
    final availableBuild = _state.availableBuild;
    if (_state.requirement != AppUpdateRequirement.optional ||
        availableBuild == null) {
      return;
    }
    _snooze = AppUpdateSnooze(
      versionCode: availableBuild,
      until: DateTime.now().toUtc().add(const Duration(hours: 24)),
    );
    await _snoozes.write(_snooze!);
    _log('app_update_deferred');
    _replaceState();
  }

  Future<void> startUpdate() async {
    if (_state.operation == AppUpdateOperation.readyToInstall) {
      await _installFlexibleUpdate();
      return;
    }
    if (_state.requirement == AppUpdateRequirement.required) {
      await _startRequiredUpdate();
      return;
    }
    if (_state.requirement == AppUpdateRequirement.optional) {
      await _startOptionalUpdate();
    }
  }

  Future<void> openStore() async {
    _log('app_update_store_opened');
    var opened = false;
    try {
      opened = await _play.openStore();
    } on Exception {
      opened = false;
    }
    if (!opened) {
      _replaceState(
        operation: AppUpdateOperation.failed,
        errorMessage: 'تعذر فتح متجر Google Play.',
      );
    }
  }

  Future<void> _refreshPolicy() async {
    try {
      await _policies.refresh().timeout(initialPolicyTimeout);
    } on Exception {
      // Cached policy remains authoritative when the network is unavailable.
      _log('app_update_policy_fetch_failed');
    }
    _replaceState(policyEvaluated: true);
  }

  Future<void> _startOptionalUpdate() async {
    _log('app_update_action_pressed');
    if (!_state.flexibleAllowed) {
      await openStore();
      return;
    }
    _replaceState(operation: AppUpdateOperation.downloading);
    PlayAppUpdateResult result;
    try {
      result = await _play.startFlexibleUpdate();
    } on Exception {
      result = PlayAppUpdateResult.failed;
    }
    switch (result) {
      case PlayAppUpdateResult.accepted:
        _log('app_update_download_ready');
        _replaceState(operation: AppUpdateOperation.readyToInstall);
      case PlayAppUpdateResult.denied:
        _log('app_update_canceled');
        _replaceState(operation: AppUpdateOperation.idle);
      case PlayAppUpdateResult.failed:
        _log('app_update_failed');
        _replaceState(
          operation: AppUpdateOperation.failed,
          errorMessage: 'تعذر تنزيل التحديث داخل التطبيق.',
        );
    }
  }

  Future<void> _startRequiredUpdate() async {
    _log('app_update_action_pressed');
    if (!_state.immediateAllowed) {
      await openStore();
      return;
    }
    _replaceState(operation: AppUpdateOperation.installing);
    PlayAppUpdateResult result;
    try {
      result = await _play.startImmediateUpdate();
    } on Exception {
      result = PlayAppUpdateResult.failed;
    }
    switch (result) {
      case PlayAppUpdateResult.accepted:
        break;
      case PlayAppUpdateResult.denied:
        _log('app_update_canceled');
        _replaceState(operation: AppUpdateOperation.idle);
      case PlayAppUpdateResult.failed:
        _log('app_update_failed');
        _replaceState(
          operation: AppUpdateOperation.failed,
          errorMessage: 'تعذر بدء التحديث الإجباري.',
        );
    }
  }

  Future<void> _installFlexibleUpdate() async {
    _replaceState(operation: AppUpdateOperation.installing);
    try {
      await _play.completeFlexibleUpdate();
      _log('app_update_install_started');
    } on Exception {
      _log('app_update_failed');
      _replaceState(
        operation: AppUpdateOperation.failed,
        errorMessage: 'تعذر تثبيت التحديث.',
      );
    }
  }

  void _policyChanged() => _replaceState();

  void _installStatusChanged(PlayAppUpdateInstallStatus status) {
    final operation = _operationForStatus(status);
    if (status == PlayAppUpdateInstallStatus.downloaded) {
      _log('app_update_download_ready');
    } else if (status == PlayAppUpdateInstallStatus.canceled) {
      _log('app_update_canceled');
    } else if (status == PlayAppUpdateInstallStatus.failed) {
      _log('app_update_failed');
    }
    _replaceState(
      operation: operation,
      errorMessage:
          status == PlayAppUpdateInstallStatus.failed ||
              status == PlayAppUpdateInstallStatus.canceled
          ? 'توقف تحديث التطبيق. يمكنك إعادة المحاولة.'
          : null,
    );
  }

  AppUpdateOperation _operationForStatus(PlayAppUpdateInstallStatus status) {
    return switch (status) {
      PlayAppUpdateInstallStatus.pending ||
      PlayAppUpdateInstallStatus.downloading => AppUpdateOperation.downloading,
      PlayAppUpdateInstallStatus.downloaded =>
        AppUpdateOperation.readyToInstall,
      PlayAppUpdateInstallStatus.installing => AppUpdateOperation.installing,
      PlayAppUpdateInstallStatus.failed ||
      PlayAppUpdateInstallStatus.canceled => AppUpdateOperation.failed,
      PlayAppUpdateInstallStatus.idle ||
      PlayAppUpdateInstallStatus.installed => AppUpdateOperation.idle,
    };
  }

  Future<void> _removeExpiredSnooze() async {
    final snooze = _snooze;
    if (snooze == null || snooze.isActiveAt(DateTime.now().toUtc())) return;
    _snooze = null;
    await _snoozes.clear();
  }

  AppUpdateState _buildState({
    required String currentVersion,
    required int? currentBuild,
    required bool policyEvaluated,
    required AppUpdateOperation operation,
    String? errorMessage,
  }) {
    final policy = _policies.value;
    final availableBuild = _availability.updateAvailable
        ? _availability.availableVersionCode
        : null;
    final snoozed =
        availableBuild != null &&
        _snooze?.versionCode == availableBuild &&
        (_snooze?.isActiveAt(DateTime.now().toUtc()) ?? false);
    final requirement = policy.requiresUpdate(currentBuild)
        ? AppUpdateRequirement.required
        : policy.systemEnabled &&
              policy.optionalUpdateEnabled &&
              availableBuild != null &&
              (currentBuild == null || availableBuild > currentBuild) &&
              !snoozed
        ? AppUpdateRequirement.optional
        : AppUpdateRequirement.none;
    return AppUpdateState(
      policy: policy,
      policyEvaluated: policyEvaluated,
      currentVersion: currentVersion,
      currentBuild: currentBuild,
      availableBuild: availableBuild,
      requirement: requirement,
      operation: operation,
      flexibleAllowed: _availability.flexibleAllowed,
      immediateAllowed: _availability.immediateAllowed,
      errorMessage: errorMessage,
    );
  }

  void _replaceState({
    bool? policyEvaluated,
    AppUpdateOperation? operation,
    String? errorMessage,
  }) {
    final previousState = _state;
    _state = _buildState(
      currentVersion: _state.currentVersion,
      currentBuild: _state.currentBuild,
      policyEvaluated: policyEvaluated ?? _state.policyEvaluated,
      operation: operation ?? _state.operation,
      errorMessage: errorMessage,
    );
    _trackPromptPresentation(previousState, _state);
    notifyListeners();
  }

  void _trackPromptPresentation(AppUpdateState previous, AppUpdateState next) {
    if (next.requirement == AppUpdateRequirement.none) return;
    if (previous.requirement == next.requirement &&
        previous.availableBuild == next.availableBuild) {
      return;
    }
    _log('app_update_prompt_shown');
  }

  void _log(String name) {
    unawaited(
      _analytics.logEvent(
        name,
        parameters: {
          'requirement': _state.requirement.name,
          'current_build': ?_state.currentBuild,
          'available_build': ?_state.availableBuild,
          'minimum_build': _state.policy.minimumSupportedBuild,
        },
      ),
    );
  }

  @override
  void dispose() {
    _policies.removeListener(_policyChanged);
    unawaited(_installSubscription?.cancel());
    super.dispose();
  }
}
