import 'package:flutter/widgets.dart';

abstract class HomeAdRepository {
  Future<void> initialize();

  Widget? buildHomeNativeAd(BuildContext context);
}

class NoopHomeAdRepository implements HomeAdRepository {
  const NoopHomeAdRepository();

  @override
  Future<void> initialize() async {}

  @override
  Widget? buildHomeNativeAd(BuildContext context) => null;
}
