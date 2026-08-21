import 'app_update_policy.dart';

enum AppUpdateRequirement { none, optional, required }

enum AppUpdateOperation {
  idle,
  checking,
  downloading,
  readyToInstall,
  installing,
  failed,
}

class AppUpdateState {
  const AppUpdateState({
    required this.policy,
    required this.policyEvaluated,
    required this.currentVersion,
    required this.currentBuild,
    required this.availableBuild,
    required this.requirement,
    required this.operation,
    required this.flexibleAllowed,
    required this.immediateAllowed,
    this.errorMessage,
  });

  factory AppUpdateState.initial() => const AppUpdateState(
    policy: AppUpdatePolicy.defaults,
    policyEvaluated: false,
    currentVersion: '',
    currentBuild: null,
    availableBuild: null,
    requirement: AppUpdateRequirement.none,
    operation: AppUpdateOperation.checking,
    flexibleAllowed: false,
    immediateAllowed: false,
  );

  final AppUpdatePolicy policy;
  final bool policyEvaluated;
  final String currentVersion;
  final int? currentBuild;
  final int? availableBuild;
  final AppUpdateRequirement requirement;
  final AppUpdateOperation operation;
  final bool flexibleAllowed;
  final bool immediateAllowed;
  final String? errorMessage;

  bool get blocksApplication =>
      policyEvaluated && requirement == AppUpdateRequirement.required;
}
