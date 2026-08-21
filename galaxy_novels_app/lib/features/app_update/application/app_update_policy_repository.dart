import 'package:flutter/foundation.dart';

import '../domain/app_update_policy.dart';

abstract interface class AppUpdatePolicyRepository implements Listenable {
  AppUpdatePolicy get value;

  bool get hasTrustedPolicy;

  Future<void> loadCached();

  Future<void> refresh();

  void startRealtimeUpdates();

  void dispose();
}

class NoopAppUpdatePolicyRepository extends ChangeNotifier
    implements AppUpdatePolicyRepository {
  @override
  AppUpdatePolicy get value => AppUpdatePolicy.defaults;

  @override
  bool get hasTrustedPolicy => false;

  @override
  Future<void> loadCached() async {}

  @override
  Future<void> refresh() async {}

  @override
  void startRealtimeUpdates() {}
}
