import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/core/analytics/app_analytics.dart';
import 'package:galaxy_novels_app/features/about/application/app_version_info.dart';
import 'package:galaxy_novels_app/features/app_update/application/app_update_controller.dart';
import 'package:galaxy_novels_app/features/app_update/application/app_update_policy_repository.dart';
import 'package:galaxy_novels_app/features/app_update/application/app_update_snooze_store.dart';
import 'package:galaxy_novels_app/features/app_update/application/play_app_update_gateway.dart';
import 'package:galaxy_novels_app/features/app_update/domain/app_update_policy.dart';
import 'package:galaxy_novels_app/features/app_update/presentation/app_update_gate.dart';
import 'package:galaxy_novels_app/features/app_update/presentation/home_update_banner.dart';

void main() {
  testWidgets('required update replaces the application and cannot be popped', (
    tester,
  ) async {
    final controller = await _controller(
      minimumBuild: 4,
      availability: const PlayAppUpdateAvailability(
        availableVersionCode: 5,
        updateAvailable: true,
        flexibleAllowed: true,
        immediateAllowed: true,
      ),
    );

    await tester.pumpWidget(
      _app(
        AppUpdateGate(
          controller: controller,
          child: const Text('application-content'),
        ),
      ),
    );

    expect(find.text('يلزم تحديث التطبيق'), findsOneWidget);
    expect(find.text('application-content'), findsNothing);
    expect(find.text('تحديث الآن'), findsOneWidget);
    expect(find.byType(PopScope), findsOneWidget);
  });

  testWidgets('supported build shows application content', (tester) async {
    final controller = await _controller(minimumBuild: 0);

    await tester.pumpWidget(
      _app(
        AppUpdateGate(
          controller: controller,
          child: const Text('application-content'),
        ),
      ),
    );

    expect(find.text('application-content'), findsOneWidget);
    expect(find.text('يلزم تحديث التطبيق'), findsNothing);
  });

  testWidgets('optional banner can be deferred for the available build', (
    tester,
  ) async {
    final controller = await _controller(
      minimumBuild: 0,
      availability: const PlayAppUpdateAvailability(
        availableVersionCode: 5,
        updateAvailable: true,
        flexibleAllowed: true,
        immediateAllowed: true,
      ),
    );

    await tester.pumpWidget(_app(HomeUpdateBanner(controller: controller)));
    expect(find.text('تحديث جديد متاح'), findsOneWidget);
    expect(find.byTooltip('ذكّرني لاحقًا'), findsOneWidget);

    await tester.tap(find.byTooltip('ذكّرني لاحقًا'));
    await tester.pump();

    expect(find.text('تحديث جديد متاح'), findsNothing);
  });
}

Widget _app(Widget child) {
  return MaterialApp(
    locale: const Locale('ar'),
    home: Directionality(textDirection: TextDirection.rtl, child: child),
  );
}

Future<AppUpdateController> _controller({
  required int minimumBuild,
  PlayAppUpdateAvailability availability = PlayAppUpdateAvailability.none,
}) async {
  final controller = AppUpdateController(
    policies: _PolicyRepository(
      AppUpdatePolicy.defaults.copyWith(minimumSupportedBuild: minimumBuild),
    ),
    play: _PlayGateway(availability),
    snoozes: _SnoozeStore(),
    versionLoader: () async =>
        const AppVersionInfo(version: '1.1.3', buildNumber: '3'),
    analytics: const NoopAppAnalytics(),
  );
  await controller.initialize();
  return controller;
}

class _PolicyRepository extends ChangeNotifier
    implements AppUpdatePolicyRepository {
  _PolicyRepository(this.value);

  @override
  final AppUpdatePolicy value;

  @override
  bool get hasTrustedPolicy => true;

  @override
  Future<void> loadCached() async {}

  @override
  Future<void> refresh() async {}

  @override
  void startRealtimeUpdates() {}
}

class _PlayGateway implements PlayAppUpdateGateway {
  _PlayGateway(this.availability);

  final PlayAppUpdateAvailability availability;

  @override
  Stream<PlayAppUpdateInstallStatus> get installStatuses =>
      const Stream.empty();

  @override
  Future<PlayAppUpdateAvailability> checkForUpdate() async => availability;

  @override
  Future<void> completeFlexibleUpdate() async {}

  @override
  Future<bool> openStore() async => true;

  @override
  Future<PlayAppUpdateResult> startFlexibleUpdate() async =>
      PlayAppUpdateResult.accepted;

  @override
  Future<PlayAppUpdateResult> startImmediateUpdate() async =>
      PlayAppUpdateResult.denied;
}

class _SnoozeStore implements AppUpdateSnoozeStore {
  AppUpdateSnooze? value;

  @override
  Future<void> clear() async => value = null;

  @override
  Future<AppUpdateSnooze?> read() async => value;

  @override
  Future<void> write(AppUpdateSnooze snooze) async => value = snooze;
}
