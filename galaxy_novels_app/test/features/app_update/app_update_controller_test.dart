import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/core/analytics/app_analytics.dart';
import 'package:galaxy_novels_app/features/about/application/app_version_info.dart';
import 'package:galaxy_novels_app/features/app_update/application/app_update_controller.dart';
import 'package:galaxy_novels_app/features/app_update/application/app_update_policy_repository.dart';
import 'package:galaxy_novels_app/features/app_update/application/app_update_snooze_store.dart';
import 'package:galaxy_novels_app/features/app_update/application/play_app_update_gateway.dart';
import 'package:galaxy_novels_app/features/app_update/domain/app_update_policy.dart';
import 'package:galaxy_novels_app/features/app_update/domain/app_update_state.dart';

void main() {
  test(
    'trusted cached policy blocks an unsupported build while offline',
    () async {
      final policies = _FakePolicyRepository(
        value: _policy(minimumBuild: 4),
        hasTrustedPolicy: true,
        failRefresh: true,
      );
      final controller = _controller(policies: policies);

      await controller.initialize();

      expect(controller.state.policyEvaluated, isTrue);
      expect(controller.state.requirement, AppUpdateRequirement.required);
      expect(controller.state.currentBuild, 3);
    },
  );

  test('first launch stays usable when no policy can be fetched', () async {
    final policies = _FakePolicyRepository(
      value: AppUpdatePolicy.defaults,
      hasTrustedPolicy: false,
      failRefresh: true,
    );
    final controller = _controller(policies: policies);

    await controller.initialize();

    expect(controller.state.policyEvaluated, isTrue);
    expect(controller.state.requirement, AppUpdateRequirement.none);
  });

  test('first launch does not wait forever for remote policy', () async {
    final policies = _FakePolicyRepository(
      value: AppUpdatePolicy.defaults,
      hasTrustedPolicy: false,
      refreshCompleter: Completer<void>(),
    );
    final controller = _controller(
      policies: policies,
      initialPolicyTimeout: const Duration(milliseconds: 1),
    );

    await controller.initialize();

    expect(controller.state.policyEvaluated, isTrue);
    expect(controller.state.requirement, AppUpdateRequirement.none);
  });

  test('optional update snoozes for one version but not a newer one', () async {
    final play = _FakePlayGateway(
      availability: const PlayAppUpdateAvailability(
        availableVersionCode: 4,
        updateAvailable: true,
        flexibleAllowed: true,
        immediateAllowed: true,
      ),
    );
    final controller = _controller(
      policies: _FakePolicyRepository(
        value: AppUpdatePolicy.defaults,
        hasTrustedPolicy: true,
      ),
      play: play,
    );
    await controller.initialize();
    expect(controller.state.requirement, AppUpdateRequirement.optional);

    await controller.snoozeOptionalUpdate();
    expect(controller.state.requirement, AppUpdateRequirement.none);

    play.availability = const PlayAppUpdateAvailability(
      availableVersionCode: 5,
      updateAvailable: true,
      flexibleAllowed: true,
      immediateAllowed: true,
    );
    await controller.refreshPlayAvailability();
    expect(controller.state.requirement, AppUpdateRequirement.optional);
  });

  test('flexible update becomes ready and can be installed', () async {
    final play = _FakePlayGateway(
      availability: const PlayAppUpdateAvailability(
        availableVersionCode: 4,
        updateAvailable: true,
        flexibleAllowed: true,
        immediateAllowed: true,
      ),
    );
    final controller = _controller(
      policies: _FakePolicyRepository(
        value: AppUpdatePolicy.defaults,
        hasTrustedPolicy: true,
      ),
      play: play,
    );
    await controller.initialize();

    await controller.startUpdate();
    expect(controller.state.operation, AppUpdateOperation.readyToInstall);

    await controller.startUpdate();
    expect(play.completedFlexibleUpdates, 1);
    expect(controller.state.operation, AppUpdateOperation.installing);
  });

  test(
    'downloaded flexible update is restored as ready after relaunch',
    () async {
      final controller = _controller(
        policies: _FakePolicyRepository(
          value: AppUpdatePolicy.defaults,
          hasTrustedPolicy: true,
        ),
        play: _FakePlayGateway(
          availability: const PlayAppUpdateAvailability(
            availableVersionCode: 4,
            updateAvailable: true,
            flexibleAllowed: true,
            immediateAllowed: true,
            installStatus: PlayAppUpdateInstallStatus.downloaded,
          ),
        ),
      );

      await controller.initialize();

      expect(controller.state.operation, AppUpdateOperation.readyToInstall);
    },
  );

  test('denying an immediate update keeps the required gate active', () async {
    final play = _FakePlayGateway(
      availability: const PlayAppUpdateAvailability(
        availableVersionCode: 4,
        updateAvailable: true,
        flexibleAllowed: true,
        immediateAllowed: true,
      ),
      immediateResult: PlayAppUpdateResult.denied,
    );
    final controller = _controller(
      policies: _FakePolicyRepository(
        value: _policy(minimumBuild: 4),
        hasTrustedPolicy: true,
      ),
      play: play,
    );
    await controller.initialize();

    await controller.startUpdate();

    expect(controller.state.requirement, AppUpdateRequirement.required);
    expect(controller.state.operation, AppUpdateOperation.idle);
  });
}

AppUpdateController _controller({
  required _FakePolicyRepository policies,
  _FakePlayGateway? play,
  Duration initialPolicyTimeout = const Duration(seconds: 4),
}) {
  return AppUpdateController(
    policies: policies,
    play: play ?? _FakePlayGateway(),
    snoozes: _MemorySnoozeStore(),
    versionLoader: () async =>
        const AppVersionInfo(version: '1.1.3', buildNumber: '3'),
    analytics: const NoopAppAnalytics(),
    initialPolicyTimeout: initialPolicyTimeout,
  );
}

AppUpdatePolicy _policy({required int minimumBuild}) {
  return AppUpdatePolicy.defaults.copyWith(minimumSupportedBuild: minimumBuild);
}

class _FakePolicyRepository extends ChangeNotifier
    implements AppUpdatePolicyRepository {
  _FakePolicyRepository({
    required AppUpdatePolicy value,
    required this.hasTrustedPolicy,
    this.failRefresh = false,
    this.refreshCompleter,
  }) : _value = value;

  final AppUpdatePolicy _value;
  @override
  final bool hasTrustedPolicy;
  final bool failRefresh;
  final Completer<void>? refreshCompleter;

  @override
  AppUpdatePolicy get value => _value;

  @override
  Future<void> loadCached() async {}

  @override
  Future<void> refresh() async {
    if (failRefresh) throw Exception('offline');
    await refreshCompleter?.future;
  }

  @override
  void startRealtimeUpdates() {}
}

class _MemorySnoozeStore implements AppUpdateSnoozeStore {
  AppUpdateSnooze? value;

  @override
  Future<void> clear() async => value = null;

  @override
  Future<AppUpdateSnooze?> read() async => value;

  @override
  Future<void> write(AppUpdateSnooze snooze) async => value = snooze;
}

class _FakePlayGateway implements PlayAppUpdateGateway {
  _FakePlayGateway({
    this.availability = PlayAppUpdateAvailability.none,
    this.immediateResult = PlayAppUpdateResult.accepted,
  });

  PlayAppUpdateAvailability availability;
  PlayAppUpdateResult immediateResult;
  int completedFlexibleUpdates = 0;

  @override
  Stream<PlayAppUpdateInstallStatus> get installStatuses =>
      const Stream.empty();

  @override
  Future<PlayAppUpdateAvailability> checkForUpdate() async => availability;

  @override
  Future<void> completeFlexibleUpdate() async {
    completedFlexibleUpdates += 1;
  }

  @override
  Future<bool> openStore() async => true;

  @override
  Future<PlayAppUpdateResult> startFlexibleUpdate() async =>
      PlayAppUpdateResult.accepted;

  @override
  Future<PlayAppUpdateResult> startImmediateUpdate() async => immediateResult;
}
