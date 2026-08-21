import 'package:flutter/foundation.dart';

import '../domain/app_review_policy.dart';

abstract interface class AppReviewPolicyRepository implements Listenable {
  AppReviewPolicy get value;

  Future<void> loadCached();

  Future<void> refresh();

  void startRealtimeUpdates();

  void dispose();
}

class NoopAppReviewPolicyRepository extends ChangeNotifier
    implements AppReviewPolicyRepository {
  @override
  AppReviewPolicy get value => AppReviewPolicy.defaults;

  @override
  Future<void> loadCached() async {}

  @override
  Future<void> refresh() async {}

  @override
  void startRealtimeUpdates() {}
}
