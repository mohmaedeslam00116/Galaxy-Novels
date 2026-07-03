import 'package:flutter/widgets.dart';

abstract class ReaderAdRepository {
  Future<void> initialize();

  Widget? buildReaderBanner(BuildContext context);
}

class NoopReaderAdRepository implements ReaderAdRepository {
  const NoopReaderAdRepository();

  @override
  Future<void> initialize() async {}

  @override
  Widget? buildReaderBanner(BuildContext context) => null;
}
